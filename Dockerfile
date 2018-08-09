# Builds a Docker image for OVERTURE and PyOVERTURE

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:ovt-frw-dev as intermediate

USER root
WORKDIR /tmp

ARG BB_TOKEN

# checkout pyovcg
RUN git clone --depth=1 \
    https://${BB_TOKEN}@bitbucket.org/paralabc/pyovcg.git \
        apps/pyovcg 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/pyovcg/.git/config

# Perform a second-stage by copying from intermediate image
FROM unifem/cht-coupler:ovt-frw-dev
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/apps $DOCKER_HOME/project
RUN chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

USER $DOCKER_USER

# Compile CG in serial
ENV CG=$DOCKER_HOME/project/overture/cg
ENV CGBUILDPREFIX=$DOCKER_HOME/project/overture/cg.bin

RUN cd $CG && git pull https master && \
    make -j2 usePETSc=on OV_USE_PETSC_3=1 libCommon && \
    make -j2 usePETSc=on OV_USE_PETSC_3=1 cgad cgcns cgins cgasf cgsm cgmp && \
    mkdir -p $CGBUILDPREFIX/bin && \
    ln -s -f $CGBUILDPREFIX/*/bin/* $CGBUILDPREFIX/bin && \
    \
    echo "export PATH=$CGBUILDPREFIX/bin:\$PATH:." >> \
        $DOCKER_HOME/.profile

# Install pyovcg
RUN cd $DOCKER_HOME/project/pyovcg && \
    python3 setup.py install --user

USER root
WORKDIR $DOCKER_HOME
