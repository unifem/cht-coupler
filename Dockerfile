# Builds a Docker image for PyCHT without OVERFLOW

# First, create an intermediate image to checkout git repository
FROM unifem/cht-coupler:base as intermediate

USER root
WORKDIR /tmp

# Checkout libcalculix and pyccx
COPY ssh /root/.ssh
RUN git clone --recurse-submodules --depth=1 \
    git@bitbucket.org:paralabc/pycht.git pycht && \
    rm -rf pycht/solvers/pyovf/overflow \
           pycht/.git/modules/solvers/pyovf/modules/overflow

# Perform a second-stage by copying from the intermediate image
FROM unifem/cht-coupler:base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

# Copy git repository from intermediate image
COPY --from=intermediate /tmp/pycht $DOCKER_HOME/pycht

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

RUN sudo chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    cd $DOCKER_HOME/pycht && \
    source /opt/openfoam5/etc/bashrc && \
    ./pycht build mapper pycpl pycss pyccx pyofm && \
    \
    echo "export PATH=$DOCKER_HOME/pycht/bin:\$PATH:." >> $DOCKER_HOME/.profile && \
    echo "export LD_LIBRARY_PATH=$DOCKER_HOME/pycht/lib:\$LD_LIBRARY_PATH" >> $DOCKER_HOME/.profile && \
    echo "export PYTHONPATH=$DOCKER_HOME/pycht/lib/python3.6/site-packages" >> $DOCKER_HOME/.profile

USER root
