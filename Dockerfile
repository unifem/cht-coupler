# Build a Docker image for CalculiX and PyCCX and install them
# into system directories.

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:ovt-mapper-bin as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

# Checkout libcalculix and pyccx
RUN git clone --depth=1 \
    https://${BB_TOKEN}@bitbucket.org/paralabc/libcalculix.git \
        apps/libcalculix 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/libcalculix/.git/config && \
    \
    git clone --depth=1 \
    https://${BB_TOKEN}@bitbucket.org/paralabc/pyccx.git \
        apps/pyccx 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/pyccx/.git/config

# Download Jupyter Notebook driver routines
RUN curl -s -L https://${BB_TOKEN}@bitbucket.org/paralabc/ovt_ccx_notebooks/get/master.tar.gz | \
        bsdtar -zxvf - --strip-components 1 "*/notebooks"

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:ovt-mapper-bin
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps .
COPY --from=intermediate /tmp/notebooks $DOCKER_HOME/project/notebooks

# Install libcalculix and pyccx
RUN cd /tmp/libcalculix && \
    make && make install && \
    cd .. && \
    \
    cd pyccx && \
    python3 setup.py install && \
    cd .. && rm -rf /tmp/* && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
USER root
