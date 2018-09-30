# Builds a Docker image with OpenMPI v1.10, Python3, Jupyter Notebook,
# MOAB/pyMOAB, CGNS/pyCGNS and Paraview. CGNS and MOAB are compiled with 
# OpenMPI v1.10 for parallel support.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

# Known issues: Cannot install spyder

FROM x11vnc/desktop:centos7
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ADD image/home $DOCKER_HOME

# Install system packages and jupyter-notebook.
RUN yum install -y \
        environment-modules \
        gcc-gfortran clang cmake ccache \
        automake autogen autoconf libtool \
        bison flex \
        bsdtar rsync \
        openmpi openmpi-devel \
        hdf5-openmpi hdf5-openmpi-devel \
        netcdf netcdf-devel netcdf-openmpi netcdf-openmpi-devel \
        metis metis-dev \
        openblas openblas-deve openblas-openmp \
        ptscotch-openmpi ptscotch-openmpi-devel ptscotch-openmpi-devel-parmetis \
        eigen3-devel \
        python36 python36-devel \
        swig \
        dejavu-sans-mono-fonts dejavu-sans-fonts dejavu-serif-fonts \
        tk-devel \
        mesa-libGLU-devel \
        libXmu-devel && \
    \
    ln -s -f /usr/bin/python36 /usr/bin/python3 && \
    \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    pip3 install -U \
          setuptools \
          matplotlib \
          sympy==1.1.1 \
          scipy \
          pandas \
          nose \
          sphinx \
          breathe \
          cython \
          \
          autopep8 \
          flake8 \
          pylint \
          flufl.lock \
          ply \
          pytest \
          six \
          \
          ipython \
          jupyter \
          jupyter_latex_envs \
          jupyter_contrib_nbextensions \
          ipywidgets && \
    jupyter nbextension install --py --system widgetsnbextension && \
    jupyter nbextension enable --py --system widgetsnbextension && \
    jupyter-nbextension install --py --system latex_envs && \
    jupyter-nbextension enable --py --system latex_envs && \
    jupyter contrib nbextension install --system && \
    jupyter nbextension enable spellchecker/main && \
    \
    curl -L https://github.com/hbin/top-programming-fonts/raw/master/install.sh | bash && \
    \
    touch $DOCKER_HOME/.log/jupyter.log && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    rm -rf /var/cache/yum /tmp/* /var/tmp/*

ENV MPI_HOME=/usr/lib64/openmpi
ENV HDF_HOME=$MPI_HOME

# Install CGNS from source with parallel enabled
RUN cd /tmp && \
    git clone --depth=1 -b master https://github.com/unifem/CGNS.git && \
    cd CGNS/src && \
    export CC="$MPI_HOME/bin/mpicc" F77="$MPI_HOME/bin/mpif77 -fPIC" && \
    export LIBS="-Wl,--no-as-needed -ldl -lz -lsz -lpthread" && \
    ln -s -f /usr/include/openmpi-x86_64 $MPI_HOME/include && \
    ./configure --enable-64bit --with-zlib --with-hdf5=$HDF_HOME \
        --enable-parallel --enable-cgnstools --enable-lfs --enable-shared && \
    make -j2 && make install && \
    rm -rf /tmp/CGNS

# Install pyCGNS from source
RUN cd /tmp && \
    git clone --depth=1 -b master https://github.com/unifem/pyCGNS.git && \
    cd pyCGNS && \
    python3 setup.py build \
        --includes=$MPI_HOME/include \
        --libraries=$MPI_HOME/lib && \
    python3 setup.py install && \
    CC="$MPI_HOME/bin/mpicc" pip3 install mpi4py && \
    rm -rf /tmp/*

WORKDIR $DOCKER_HOME
USER root
