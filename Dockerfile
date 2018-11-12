# Build a Docker image for CalculiX and PyCCX and install them
# into system directories.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:ovt-mapper-bin as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

# Checkout libcalculix and pyccx
COPY ssh /root/.ssh
RUN git clone --recurse-submodules --depth=1 \
    git@bitbucket.org:paralabc/pyccx.git apps/pyccx

# Download Jupyter Notebook driver routines
RUN curl -s -L https://${BB_TOKEN}@bitbucket.org/paralabc/ovt_ccx_notebooks/get/master.tar.gz | \
        bsdtar -zxvf - --strip-components 1 "*/notebooks"

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:ovt-mapper-bin
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps /tmp
COPY --from=intermediate /tmp/notebooks $DOCKER_HOME/project/notebooks

# Install pyccx
RUN cd /tmp/pyccx && \ 
    ./build.sh PREFIX=/usr/local && \
    cd .. && rm -rf /tmp/* && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
USER root
