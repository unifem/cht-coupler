# Builds a Docker image for OpenFOAM/PyOFM and CalculiX/PyCCX.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:dev-base as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

# checkout libofm and pyofm
RUN git clone --depth=1 \
       https://${BB_TOKEN}@bitbucket.org/qiaoc/libofm.git \
       ./apps/libofm 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/libofm/.git/config

# Checkout libcalculix and pyccx
RUN git clone --depth=1 \
    https://${BB_TOKEN}@bitbucket.org/qiaoc/libcalculix.git \
        apps/libcalculix 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/libcalculix/.git/config && \
    \
    git clone --depth=1 \
    https://${BB_TOKEN}@bitbucket.org/qiaoc/pyccx.git \
        apps/pyccx 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/pyccx/.git/config

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:dev-base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root

COPY --from=intermediate /tmp/apps .

# Install OpenFOAM 5.0 (https://openfoam.org/download/5-0-ubuntu/),
RUN add-apt-repository http://dl.openfoam.org/ubuntu && \
    sh -c "curl -s http://dl.openfoam.org/gpg.key | apt-key add -" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        openfoam5 && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Source configuration for bash
# https://github.com/OpenFOAM/OpenFOAM-dev/tree/version-5.0/etc
RUN echo "source /opt/openfoam5/etc/bashrc" >> $DOCKER_HOME/.profile && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

# Copy git repository from intermediate image
WORKDIR $DOCKER_HOME/project

# Build libofm and pyofm
RUN echo ". /opt/openfoam5/etc/bashrc\n./configure --python\n./Allwmake\n" > \
        libofm/install.sh && \
    cd $DOCKER_HOME/project/libofm && \
    bash ./install.sh

# Install libcalculix and pyccx
RUN cd $DOCKER_HOME/project/libcalculix && \
    make && \
    \
    cd $DOCKER_HOME/project/pyccx && \
    python3 setup.py install --user

WORKDIR $DOCKER_HOME
USER root
