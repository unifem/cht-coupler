# Builds a Docker image for PyCHT

# First, create an intermediate image to checkout git repository
FROM x11vnc/desktop:18.04 as intermediate

USER root
WORKDIR /tmp

# Checkout libcalculix and pyccx
COPY ssh /root/.ssh
RUN git clone --recurse-submodules --depth=1 \
    git@bitbucket.org:paralabc/pycht.git pycht

# Perform a second-stage by copying from the intermediate image
FROM x11vnc/desktop:18.04
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

ADD image/home $DOCKER_HOME
ADD image/bin /tmp

# Install system packages and jupyter-notebook.
# Use fix_ompi_dlopen.sh to fix dlopen issue with OpenMPI v2.x
RUN sh -c "curl -s http://dl.openfoam.org/gpg.key | apt-key add -" && \
    add-apt-repository http://dl.openfoam.org/ubuntu && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential gfortran clang strace \
        cmake wget \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-math-dev \
        libboost-program-options-dev \
        libboost-system-dev \
        libboost-thread-dev \
        libboost-timer-dev \
        doxygen \
        bison \
        flex \
        git git-lfs \
        bash-completion \
        bsdtar \
        rsync \
        ccache \
        automake autogen autoconf libtool \
        patchelf \
        openmpi-bin libopenmpi-dev \
        libhdf5-100 libhdf5-dev hdf5-tools \
        libnetcdf-dev netcdf-bin \
        libmetis5 libmetis-dev \
        libopenblas-base libopenblas-dev \
        libptscotch-dev \
        libeigen3-dev \
        python3-dev \
        python3-mpi4py \
        python3-h5py \
        swig swig3.0 \
        ttf-dejavu \
        tk-dev \
        libglu1-mesa-dev \
        libxmu-dev \
        \
        openfoam5 paraviewopenfoam54 && \
    apt-get clean && \
    \
    \
    /tmp/fix_ompi_dlopen.sh && \
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
          \
          urllib3 \
          pylint \
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

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/pycht $DOCKER_HOME/pycht

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

RUN sudo chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME/pycht && \
    cd $DOCKER_HOME/pycht && \
    ./build.sh && \
    \
    echo "export PATH=$DOCKER_HOME/pycht/bin:\$PATH:." >> $DOCKER_HOME/.profile && \
    echo "export PYTHONPATH=$DOCKER_HOME/pycht/lib/python3.6/site-packages" >> $DOCKER_HOME/.profile

USER root
