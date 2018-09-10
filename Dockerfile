# Builds a Docker image for OpenFOAM/PyOFM and CalculiX/PyCCX.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:ccx-mapper-dev as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

# checkout libofm and pyofm
RUN git clone --depth=1 \
       https://${BB_TOKEN}@bitbucket.org/paralabc/libofm.git \
       ./apps/libofm 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/libofm/.git/config

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:ccx-mapper-dev
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root

COPY --from=intermediate /tmp/apps $DOCKER_HOME/project

# Install OpenFOAM 5.0 (https://openfoam.org/download/5-0-ubuntu/),
RUN sh -c "curl -s http://dl.openfoam.org/gpg.key | apt-key add -" && \
    add-apt-repository http://dl.openfoam.org/ubuntu && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        openfoam5 paraviewopenfoam54 && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Source configuration for bash
# https://github.com/OpenFOAM/OpenFOAM-dev/tree/version-5.0/etc
RUN echo "source /opt/openfoam5/etc/bashrc" >> $DOCKER_HOME/.profile && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

USER $DOCKER_USER
WORKDIR $DOCKER_HOME/project

# Build libofm and pyofm
RUN cd $DOCKER_HOME/project/libofm && \
    bash -c ". /opt/openfoam5/etc/bashrc && ./configure --python && ./Allwmake" && \
    cd $DOCKER_HOME/project/libofm/python && \
    bash -c ". /opt/openfoam5/etc/bashrc && python3 setup.py install --user" && \
    cd $DOCKER_HOME/project/libofm && \
    bash -c ". /opt/openfoam5/etc/bashrc && ./Allwclean python"

WORKDIR $DOCKER_HOME
USER root
