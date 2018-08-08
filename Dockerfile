# Builds a Docker image with OpenMPI v2.x, Python3 and Jupyter Notebook.
# OpenMPI v2 is patched to work with dlopen.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/desktop:17.10
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ADD image/home $DOCKER_HOME
ADD image/bin /tmp

# Install system packages
# Use fix_ompi_dlopen.sh to fix dlopen issue with OpenMPI v2.x
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential gfortran \
        cmake wget \
        bison \
        flex \
        git \
        bash-completion \
        bsdtar \
        rsync \
        ccache \
        automake autogen autoconf libtool \
        patchelf \
        openmpi-bin libopenmpi-dev \
        libhdf5-100 libhdf5-dev hdf5-tools \
        libhdf5-openmpi-100 libhdf5-openmpi-dev \
        libnetcdf-dev netcdf-bin \
        libmetis5 libmetis-dev \
        libopenblas-base libopenblas-dev \
        libptscotch-dev \
        libeigen3-dev \
        python3-dev \
        python3-mpi4py \
        swig3.0 \
        ttf-dejavu \
        tk-dev \
        libglu1-mesa-dev \
        libxmu-dev && \
    apt-get clean && \
    \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    pip3 install -U \
        setuptools\
        cython \
        numpy && \
    \
    /tmp/fix_ompi_dlopen.sh && \
    mkdir -p /usr/lib/hdf5-openmpi && \
    ln -s -f /usr/include/hdf5/openmpi /usr/lib/hdf5-openmpi/include && \
    ln -s -f /usr/lib/x86_64-linux-gnu/hdf5/openmpi /usr/lib/hdf5-openmpi/lib && \
    \
    mkdir -p /usr/lib/hdf5-serial && \
    ln -s -f /usr/include/hdf5/serial /usr/lib/hdf5-serial/include && \
    ln -s -f /usr/lib/x86_64-linux-gnu/hdf5/serial /usr/lib/hdf5-serial/lib && \
    \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER $DOCKER_USER
WORKDIR $DOCKER_HOME
USER root
