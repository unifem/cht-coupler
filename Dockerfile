# Builds a Docker image with MOAB and pymoab with parallel support
# and compile them in user directories.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM unifem/cht-coupler:dev-base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

# Install MOAB from sources into user directories
RUN mkdir -p project && cd project && \
    git clone --depth=1 https://bitbucket.org/fathomteam/moab.git && \
    cd moab && \
    autoreconf -fi && \
    ./configure \
        --prefix=$DOCKER_HOME/.local \
        --with-mpi \
        CC=mpicc \
        CXX=mpicxx \
        FC=mpif90 \
        F77=mpif77 \
        --enable-optimize \
        --enable-shared=yes \
        --with-blas=-lopenblas \
        --with-lapack=-lopenblas \
        --with-eigen3=off && \
    make -j2 && make install

ENV MOAB_ROOT=$DOCKER_HOME/.local

USER root
