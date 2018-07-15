# Builds a Docker image for CalculiX and PyCCX

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:mapper as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

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
FROM unifem/cht-coupler:mapper
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

COPY --from=intermediate /tmp/apps .

# Install libcalculix and pyccx
RUN cd libcalculix && \
    make && make install && \
    cd .. && \
    \
    cd pyccx && \
    python3 setup.py install && \
    cd .. && rm -rf /tmp/*

WORKDIR $DOCKER_HOME
USER root
