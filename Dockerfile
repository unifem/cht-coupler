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
        --with-eigen3=off \
        --with-scotch=off \
        --with-metis=off && \
    make -j2 && make install && \
    rm -rf /tmp/moab

ENV MOAB_ROOT=/usr/local

WORKDIR $DOCKER_HOME
USER root
