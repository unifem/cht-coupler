# Build a Docker image for CalculiX and PyCCX and install them
# into system directories.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:ovt-mapper-bin as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

# Checkout libcalculix and pyccx
RUN git clone --depth=1 \
    https://${BB_TOKEN}@bitbucket.org/qiaoc/libcalculix.git \
        apps/libcalculix 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/libcalculix/.git/config && \
    \
    git clone --depth=1 \
    https://${BB_TOKEN}@bitbucket.org/qiaoc/pyccx.git \
        apps/pyccx 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/pyccx/.git/config

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:ovt-mapper-bin
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps .

# Install libcalculix and pyccx
RUN cd /tmp/libcalculix && \
    make && make install && \
    cd .. && \
    \
    cd pyccx && \
    python3 setup.py install && \
    cd .. && rm -rf /tmp/*

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

# Download Jupyter Notebook driver routines
RUN mkdir -p project && \
    cd project && \
    curl -s -L https://github.com/chiao45/ovt_ccx_notebooks/archive/master.zip | \
        bsdtar -zxvf - --strip-components 1 ovt_ccx_notebooks-master/notebooks

USER root
