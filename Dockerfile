# Builds a Docker image with MOAB and pymoab with parallel support
# and install them into system directories.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM unifem/cht-coupler:base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install MOAB and pymoab from sources into system directories
RUN cd /tmp && \
    git clone --depth=1 https://bitbucket.org/fathomteam/moab.git && \
    cd moab && \
    autoreconf -fi && \
    ./configure \
        --prefix=/usr/local \
        --with-mpi \
        CC=mpicc \
        CXX=mpicxx \
        FC=mpif90 \
        F77=mpif77 \
        --enable-optimize \
        --enable-shared=yes \
        --with-blas=-lopenblas \
        --with-lapack=-lopenblas \
        --with-scotch=/usr/lib/x86_64-linux-gnu \
        --with-metis=/usr/lib/x86_64-linux-gnu \
        --with-x \
        --enable-ahf=yes \
        --enable-tools=yes && \
    make -j2 && make install && \
    \
    cd pymoab && \
    python3 setup.py install && \
    rm -rf /tmp/moab

ENV MOAB_ROOT=/usr/local

# Install paraview
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        paraview && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR $DOCKER_HOME
USER root
