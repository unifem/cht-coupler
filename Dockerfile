# Builds a Docker image for code development, with Visual Studio Code, ddd, Valgrind, etc.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

ADD image/home $DOCKER_HOME/

# Install mscode and system packages
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg && \
    sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list' && \
    \
    apt-get update && \
    apt-get install  -y --no-install-recommends \
	gdb\
	ddd \
	valgrind \
        electric-fence \
        kcachegrind \

        pandoc \
	code \
	meld \
	emacs \
	vim-gtk3 \
	nano \
        clang \
	clang-format && \
    apt-get install -y --no-install-recommends \
    apt-get clean && \
    pip3 install -U \
        autopep8 \
        flake8 \
        pylint \
        pytest && \
    echo "move_to_config vscode" >> /usr/local/bin/init_vnc && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

# Install mscode extensions
RUN bash -c 'for ext in \
        ms-vscode.cpptools \
        xaver.clang-format \
        cschlosser.doxdocgen \
        bbenoist.doxygen \
        streetsidesoftware.code-spell-checker \
        eamodio.gitlens \
        james-yu.latex-workshop \
        yzhang.markdown-all-in-one \
        davidanson.vscode-markdownlint \
        gimly81.matlab \
        krvajalm.linter-gfortran \
        ms-python.python \
        vector-of-bool.cmake-tools \
        twxs.cmake \
        formulahendry.terminal; \
        do \
            code --install-extension $ext; \
        done'

USER root
