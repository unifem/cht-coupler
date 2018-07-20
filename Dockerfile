# Builds a Docker image for FEniCS with PETSc

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:base as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

RUN git clone --depth=1 \
    https://${BB_TOKEN}@bitbucket.org/qiaoc/fesol.git \
        apps/fesol 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/*/.git/config

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install PETSC and SLEPC
ENV PETSC_VERSION=3.7.6
ENV SLEPC_VERSION=3.7.4

# Install system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bison \
        flex \
        bash-completion \
        bsdtar \
        rsync \
        gdb \
        ccache \
        \
        libscalapack-openmpi1 libscalapack-mpi-dev \
        libsuperlu-dev \
        libsuitesparse-dev \
        libhypre-dev \
        libblacs-openmpi1 libblacs-mpi-dev \
        libptscotch-dev \
        libmumps-dev \
        \
        libpetsc${PETSC_VERSION}-dev \
        libslepc${SLEPC_VERSION}-dev \
        \
        git \
        git-lfs \
        libnss3 \
        imagemagick \
        \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-math-dev \
        libboost-program-options-dev \
        libboost-system-dev \
        libboost-thread-dev \
        libboost-timer-dev \
        libeigen3-dev \
        libomp-dev \
        libpcre3-dev \
        libhdf5-openmpi-dev \
        libgmp-dev \
        libcln-dev \
        libmpfr-dev \
        libparmetis4.0 libmetis-dev libparmetis-dev && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PETSC_DIR=/usr/lib/petscdir/${PETSC_VERSION}/x86_64-linux-gnu-real
ENV SLEPC_DIR=/usr/lib/slepcdir/${SLEPC_VERSION}/x86_64-linux-gnu-real

ADD image/home $DOCKER_HOME

# Build FEniCS with Python3
ENV FENICS_BUILD_TYPE=Release \
    FENICS_PREFIX=/usr/local \
    FENICS_VERSION=2017.1.0 \
    FENICS_PYTHON=python3

ARG FENICS_SRC_DIR=/tmp/src


# Disable testing of compilation of PETSC and SLEPC in cmake
# cmake is broken in dolfin when using system installed PETSC and SLEPC
ARG CMAKE_EXTRA_ARGS="-DPETSC_TEST_LIB_COMPILED=1 -DPETSC_TEST_LIB_EXITCODE=0 \
                      -DSLEPC_TEST_LIB_COMPILED=1 -DSLEPC_TEST_LIB_EXITCODE=0"

RUN $DOCKER_HOME/bin/fenics-pull && \
    $DOCKER_HOME/bin/fenics-build && \
    ldconfig && \
    rm -rf /tmp/src && \
    rm -f $DOCKER_HOME/bin/fenics-*

# Install fenics-tools (this might be removed later)
RUN cd /tmp && \
    git clone --depth 1 https://github.com/unifem/fenicstools.git && \
    cd fenicstools && \
    python3 setup.py install && \
    rm -rf /tmp/fenicstools

ENV PYTHONPATH=$FENICS_PREFIX/lib/python3/dist-packages:$PYTHONPATH

# Install fesol
RUN cd fesol && \
    python3 setup.py install && \
    cd .. && rm -rf /tmp/*

WORKDIR $DOCKER_HOME
USER root
