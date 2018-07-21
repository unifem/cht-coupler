# Builds a Docker image for FEniCS

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

# Install system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bison \
        flex \
        bash-completion \
        bsdtar \
        rsync \
        gdb \
        pkg-config \
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
    \
    pip3 install -U \
          matplotlib \
          sympy==1.1.1 \
          scipy \
          sphinx \
          \
          pybind11 \
          ply \
          pytest \
          six && \
      rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install FEniCS
RUN apt-get install --no-install-recommends software-properties-common && \
    add-apt-repository ppa:fenics-packages/fenics && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive && \
    apt-get install --no-install-recommends fenics mshr && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
