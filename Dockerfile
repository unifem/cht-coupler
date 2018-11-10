# Build a Docker image for CalculiX and PyCCX and install them
# into system directories.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:mapper-bin as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

# Checkout libcalculix and pyccx
RUN git clone --recurse-submodules --depth=1 \
    https://${BB_TOKEN}@bitbucket.org/paralabc/pyccx.git \
        apps/pyccx 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/pyccx/.git/config

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:mapper-bin
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps /tmp

# Install pyccx
RUN cd /tmp/pyccx && \
    ./build.sh PREFIX=/usr/local && \
    cd .. && rm -rf /tmp/*

WORKDIR $DOCKER_HOME
USER root
