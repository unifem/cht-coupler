# Builds a Docker image with DataTransferKit, PyDTK2, and ParPyDTK2.
# It requires meshdb.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:meshdb-bin as intermediate
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ARG BB_TOKEN

# Check out pydtk2 securely
RUN git clone --depth=1 \
        https://${BB_TOKEN}@bitbucket.org/paralabc/pydtk2.git \
        apps/pydtk2 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/pydtk2/.git/config

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:meshdb-bin
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-math-dev \
        libboost-program-options-dev \
        libboost-system-dev \
        libboost-thread-dev \
        libboost-timer-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ARG TRILINOS_VERSION=12-12-1
ARG DTK_VERSION=2.0

# Build DataTransferKit
# For options to control Trilinos, see
# https://trilinos.org/oldsite/TrilinosBuildQuickRef.html#configuring-makefile-generator
RUN git clone --depth 1 --branch trilinos-release-${TRILINOS_VERSION} \
        https://github.com/trilinos/Trilinos.git && \
    cd Trilinos && \
    git clone --depth 1 --branch awls \
        https://github.com/unifem/DataTransferKit.git && \
    mkdir build && cd build && \
    cmake \
        -DCMAKE_INSTALL_PREFIX:PATH=/usr/local \
        -DCMAKE_BUILD_TYPE:STRING=RELEASE \
        -DCMAKE_VERBOSE_MAKEFILE:BOOL=OFF \
        -DCMAKE_SHARED_LIBS:BOOL=ON \
        -DTPL_ENABLE_MPI:BOOL=ON \
        -DTPL_ENABLE_Boost:BOOL=ON \
        -DBoost_INCLUDE_DIRS:PATH=/usr/include/boost \
        -DTPL_ENABLE_Libmesh:BOOL=OFF \
        -DTPL_ENABLE_MOAB:BOOL=ON \
        -DMOAB_INCLUDE_DIRS=$MOAB_ROOT/include \
        -DMOAB_LIBRARY_DIRS=$MOAB_ROOT/lib \
        -DTPL_ENABLE_Netcdf:BOOL=ON \
        -DTPL_ENABLE_BinUtils:BOOL=OFF \
        -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF \
        -DTrilinos_ENABLE_ALL_PACKAGES=OFF \
        -DTrilinos_EXTRA_REPOSITORIES="DataTransferKit" \
        -DTrilinos_ENABLE_EXPLICIT_INSTANTIATION:BOOL=ON \
        -DTrilinos_ASSERT_MISSING_PACKAGES:BOOL=OFF \
        -DTrilinos_ENABLE_TESTS:BOOL=OFF \
        -DTrilinos_ENABLE_EXAMPLES:BOOL=OFF \
        -DTrilinos_ENABLE_CXX11:BOOL=ON \
        -DTrilinos_ENABLE_Tpetra:BOOL=ON \
        -DTpetra_INST_INT_UNSIGNED_LONG:BOOL=ON \
        -DTPL_ENABLE_BLAS:BOOL=ON \
        -DTPL_BLAS_LIBRARIES=/usr/lib/x86_64-linux-gnu/libopenblas.so \
        -DTPL_ENABLE_LAPACK:BOOL=ON \
        -DTPL_LAPACK_LIBRARIES=/usr/lib/x86_64-linux-gnu/libopenblas.so \
        -DTrilinos_ENABLE_DataTransferKit=ON \
        -DDataTransferKit_ENABLE_DBC=ON \
        -DDataTransferKit_ENABLE_TESTS=OFF \
        -DDataTransferKit_ENABLE_EXAMPLES=OFF \
        -DDataTransferKit_ENABLE_ClangFormat=OFF \
        -DTPL_ENABLE_BoostLib:BOOL=OFF \
        -DBUILD_SHARED_LIBS:BOOL=ON \
        .. && \
    make -j2 && \
    make install && \
    \
    rm -rf /tmp/*

COPY --from=intermediate /tmp/apps .

# Install pydtk2 and parpydtk2
# make sure to add env CC=mpicxx
RUN cd pydtk2 && \
    env CC=mpicxx python3 setup.py install && \
    cd .. && rm -rf pydtk2 && \
    pip3 install parpydtk2

WORKDIR $DOCKER_HOME
USER root
