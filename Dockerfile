# Build a Docker image for CalculiX and PyCCX and install them
# into user directories.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:dev-base as intermediate

USER $DOCKER_USER
WORKDIR /tmp

# Checkout libcalculix and pyccx
COPY --chown=$DOCKER_USER:$DOCKER_GROUP ssh $DOCKER_HOME/.ssh
RUN git clone --recurse-submodules --depth=1 \
    git@bitbucket.org:paralabc/pyccx.git apps/pyccx
    
# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:dev-base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

# Copy git repository from intermediate image
COPY --from=intermediate --chown=$DOCKER_USER:$DOCKER_GROUP /tmp/apps project

# Install pyccx
RUN cd project/pyccx && \
    ./build.sh PREFIX=$DOCKER_HOME/.local

WORKDIR $DOCKER_HOME
USER root
