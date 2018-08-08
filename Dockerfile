# Builds a Docker image with OpenMPI v2.x, Python3, Jupyter Notebook,
# MOAB/pyMOAB and CGNS/pyCGNS. CGNS and MOAB are compiled with 
# OpenMPI v2.x for parallel support. OpenMPI is patched to work with dlopen.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/desktop:17.10
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ADD image/home $DOCKER_HOME
ADD image/bin /tmp

# Install system packages and jupyter-notebook.
# Use fix_ompi_dlopen.sh to fix dlopen issue with OpenMPI v2.x
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential gfortran clang \
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
          PyQt5 \
          spyder \
          \
          urllib3 \
          requests \
          pylint \
          progressbar2 \
          PyDrive \
          \
          ipython \
          jupyter \
          jupyter_latex_envs \
          jupyter_contrib_nbextensions \
          ipywidgets && \
    jupyter nbextension install --py --system \
         widgetsnbextension && \
    jupyter nbextension enable --py --system \
         widgetsnbextension && \
    jupyter-nbextension install --py --system \
        latex_envs && \
    jupyter-nbextension enable --py --system \
        latex_envs && \
    jupyter contrib nbextension install --system && \
    jupyter nbextension enable spellchecker/main && \
    \
    curl -L https://github.com/hbin/top-programming-fonts/raw/master/install.sh | bash && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    \
    touch $DOCKER_HOME/.log/jupyter.log && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install CGNS from source with parallel enabled
RUN cd /tmp && \
    git clone --depth=1 -b master https://github.com/CGNS/CGNS.git && \
    cd CGNS/src && \
    export CC="mpicc" && \
    export LIBS="-Wl,--no-as-needed -ldl -lz -lsz -lpthread" && \
    ./configure --enable-64bit --with-zlib --with-hdf5=/usr/lib/hdf5-openmpi \
        --enable-parallel --enable-cgnstools --enable-lfs --enable-shared && \
    sed -i 's/TKINCS =/TKINCS = -I\/usr\/include\/tcl/' cgnstools/make.defs && \
    make -j2 && make install && \
    rm -rf /tmp/CGNS

# Install pyCGNS from source
RUN cd /tmp && \
    git clone --depth=1 -b master https://github.com/unifem/pyCGNS.git && \
    cd pyCGNS && \
    python3 setup.py build \
        --includes=/usr/include/hdf5/openmpi:/usr/include/openmpi \
        --libraries=/usr/lib/x86_64-linux-gnu/hdf5/openmpi && \
    python3 setup.py install && \
    rm -rf /tmp/pyCGNS

# Install MOAB and pymoab from sources
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
        --with-scotch=/usr/lib \
        --with-metis=/usr/lib/x86_64-linux-gnu \
        --with-eigen3=/usr/include/eigen3 \
        --with-x \
        --with-cgns \
        --with-netcdf \
        --with-hdf5=/usr/lib/hdf5-openmpi \
        --with-hdf5-ldflags="-L/usr/lib/hdf5-openmpi/lib" \
        --enable-ahf=yes \
        --enable-tools=yes && \
    make -j2 && make install && \
    \
    cd pymoab && \
    python3 setup.py install && \
    rm -rf /tmp/moab

WORKDIR $DOCKER_HOME
USER root
