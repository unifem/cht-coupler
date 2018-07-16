# Builds a Docker image for OpenFOAM and ParaView

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:base as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

# checkout libofm and pyofm
RUN git clone --depth=1 \
       https://${BB_TOKEN}@bitbucket.org/qiaoc/libofm.git \
       ./apps/libofm 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/libofm/.git/config

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install OpenFOAM 5.0 (https://openfoam.org/download/5-0-ubuntu/),
RUN add-apt-repository http://dl.openfoam.org/ubuntu && \
    sh -c "curl -s http://dl.openfoam.org/gpg.key | apt-key add -" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        openfoam5 \
        paraviewopenfoam54 && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Source configuration for bash
# https://github.com/OpenFOAM/OpenFOAM-dev/tree/version-5.0/etc
RUN echo "source /opt/openfoam5/etc/bashrc" >> $DOCKER_HOME/.profile && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps .

# Build libofm and pyofm
RUN echo ". /opt/openfoam5/etc/bashrc\n./configure --python --system\n./Allwmake\n" > \
        libofm/install.sh && \
    cd libofm && \
    bash ./install.sh && \
    rm -rf libofm

WORKDIR $DOCKER_HOME
USER root
