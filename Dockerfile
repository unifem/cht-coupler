# Build a Docker image for CalculiX and PyCCX and install them
# into user directories.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:ovt-mapper-dev as intermediate

USER root
WORKDIR /tmp

# Checkout libcalculix and pyccx
COPY ssh /root/.ssh
RUN git clone --recurse-submodules --depth=1 \
    git@bitbucket.org:paralabc/pyccx.git apps/pyccx

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:ovt-mapper-dev
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps project

# Install pyccx
RUN sudo chown -R $DOCKER_USER:$DOCKER_GROUP project && \
    cd project/pyccx && \
    ./build.sh PREFIX=$DOCKER_HOME/.local

WORKDIR $DOCKER_HOME
USER root
