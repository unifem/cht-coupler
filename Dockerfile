# Build a Docker image for OpenFOAM/PyOFM and CalculiX/PyCCX
# and install them into system directories.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:ccx-mapper-bin as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

# checkout libofm and pyofm
RUN git clone --depth=1 \
       https://${BB_TOKEN}@bitbucket.org/paralabc/libofm.git \
       ./apps/libofm 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/libofm/.git/config

# Download Jupyter Notebook driver routines
RUN curl -s -L https://${BB_TOKEN}@bitbucket.org/paralabc/foam_ccx_cht/get/master.tar.gz | \
        bsdtar -zxvf - --strip-components 2 "*/image/notebooks"

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:ccx-mapper-bin
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install OpenFOAM 5.0 (https://openfoam.org/download/5-0-ubuntu/),
# and configure it for user
# https://github.com/OpenFOAM/OpenFOAM-dev/tree/version-5.0/etc
RUN add-apt-repository http://dl.openfoam.org/ubuntu && \
    sh -c "curl -s http://dl.openfoam.org/gpg.key | apt-key add -" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        openfoam5 && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps .
COPY --from=intermediate /tmp/notebooks $DOCKER_HOME/project/notebooks

# Source configuration for bash
# https://github.com/OpenFOAM/OpenFOAM-dev/tree/version-5.0/etc
RUN echo "source /opt/openfoam5/etc/bashrc" >> $DOCKER_HOME/.profile && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

# Build libofm and pyofm
RUN cd libofm && \
    bash -c ". /opt/openfoam5/etc/bashrc && ./configure --python --system && ./Allwmake" && \
    cd python && \
    bash -c ". /opt/openfoam5/etc/bashrc && python3 setup.py install" && \
    rm -rf /tmp/libofm

USER root
