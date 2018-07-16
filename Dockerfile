# Builds a Docker image for OVERTURE and PyOVERTURE

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:ovt-frw as intermediate

USER root
WORKDIR /tmp

ARG SSH_PRIVATE_KEY

# checkout pyovcg
RUN mkdir -p /root/.ssh && \
    echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && \
    chmod go-r /root/.ssh/id_rsa && \
    touch /root/.ssh/known_hosts && \
    ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts && \
    \
    git clone --depth=1 \
       git@bitbucket.org:qiaoc/pyovcg.git \
       ./apps/pyovcg && \
    \
    rm /root/.ssh/id_rsa

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:ovt-frw
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER $DOCKER_USER
WORKDIR /tmp

# Compile CG in serial
ENV CG=$DOCKER_HOME/overture/cg
ENV CGBUILDPREFIX=$DOCKER_HOME/overture/cg.bin

RUN cd $CG && git pull https master && \
    make -j2 usePETSc=on OV_USE_PETSC_3=1 libCommon && \
    make -j2 usePETSc=on OV_USE_PETSC_3=1 cgad cgcns cgins cgasf cgsm cgmp && \
    mkdir -p $CGBUILDPREFIX/bin && \
    ln -s -f $CGBUILDPREFIX/*/bin/* $CGBUILDPREFIX/bin && \
    \
    echo "export PATH=$CGBUILDPREFIX/bin:\$PATH:." >> \
        $DOCKER_HOME/.profile

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps .

# Build pyovcg
RUN cd pyovcg && \
    python3 setup.py install && \
    rm -rf pyovcg

WORKDIR $DOCKER_HOME
USER root
