# Builds a Docker image for CalculiX and PyCCX

FROM unifem/cht-coupler:mapper
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install Calculix, along with FreeCAD and Gmsh
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        calculix-ccx \
        freecad \
        gmsh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG BB_TOKEN

# Install libcalculix and pyccx
RUN git clone --depth=1 \
    https://xmjiao:${BB_TOKEN}@bitbucket.org/qiaoc/libcalculix.git \
    ./libcalculix 2> /dev/null && \
    cd libcalculix && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i .git/config && \
    make && make install && \
    cd .. && \
    \
    git clone --depth=1 \
    https://xmjiao:${BB_TOKEN}@bitbucket.org/qiaoc/pyccx.git \
    ./pyccx 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i .git/config && \
    cd pyccx && \
    python3 setup.py install && \
    cd .. && rm -rf pydtk2

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

USER root
