# Builds a Docker image for PyCHT without OVERFLOW

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:pycht as intermediate

USER root
WORKDIR /tmp

# Checkout pycht with overflow
COPY ssh /root/.ssh
RUN git clone --recurse-submodules --depth=1 \
    git@bitbucket.org:paralabc/pycht.git pycht

# Perform a second-stage by copying from the intermediate image
FROM unifem/cht-coupler:pycht
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/pycht/solvers/pyovf/overflow \
                $DOCKER_HOME/pycht/solvers/pyovf/overflow
COPY --from=intermediate /tmp/pycht/.git/modules/solvers/pyovf/modules/overflow \
                $DOCKER_HOME/pycht/.git/modules/solvers/pyovf/modules/overflow

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

RUN sudo chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    cd $DOCKER_HOME/pycht && \
    ./build.sh pyovf

USER root
