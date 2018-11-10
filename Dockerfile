# Build a Docker image for CalculiX and PyCCX and install them
# into user directories.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:dev-base as intermediate

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
FROM unifem/cht-coupler:dev-base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps project

# Install pyccx
RUN cd project/pyccx && \
    ./build.sh PREFIX=$DOCKER_HOME/.local

WORKDIR $DOCKER_HOME
USER root
