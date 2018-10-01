# Builds a Docker image with MPICH 3.2, Python3, and Jupyter Notebook.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/desktop:centos7
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ADD image/home $DOCKER_HOME

ARG MPI_HOME=/usr/lib64/mpich-3.2

# Install system packages and jupyter-notebook.
RUN yum install -y \
        environment-modules \
        gcc-gfortran clang cmake ccache \
        automake autogen autoconf libtool \
        bison flex \
        bsdtar rsync \
        mpich-3.2 mpich-3.2-devel \
        mvapich23 mvapich23-devel \
        hdf5 hdf5-devel \
        netcdf netcdf-devel \
        metis metis-dev \
        openblas openblas-deve \
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
    CC="$MPI_HOME/bin/mpicc" pip3 install mpi4py && \
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

WORKDIR $DOCKER_HOME
USER root
