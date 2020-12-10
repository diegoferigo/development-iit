ARG from=diegoferigo/devenv:latest
FROM ${from}

# Setup locales and timezone
ARG TZ=Europe/Rome
ARG DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/localtime &&\
    ln -s /usr/share/zoneinfo/"${TZ}" /etc/localtime &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends locales locales-all tzdata &&\
    rm -rf /var/lib/apt/lists/*

# Utilities
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        sudo \
        software-properties-common \
        apt-transport-https \
        apt-utils \
        wget \
        nano \
        dbus-x11 \
        tree \
        bash-completion \
        gnupg2 \
        colordiff \
        octave \
        trash-cli \
        xterm \
        curl \
        zip \
        unzip \
        mesa-utils \
        &&\
    rm -rf /var/lib/apt/lists/*

# Updated clang ppa
ARG clang_version=11
ENV CLANG_VER=${clang_version}

# Build and development tools
RUN wget -nv -O - http://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - &&\
    apt-add-repository -y "deb http://apt.llvm.org/`lsb_release -cs`/ llvm-toolchain-`lsb_release -cs`-${CLANG_VER} main" &&\
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - && \
    apt-add-repository "deb https://apt.kitware.com/ubuntu/ `lsb_release -cs` main" &&\
    apt-get install -y kitware-archive-keyring &&\
    apt-key --keyring /etc/apt/trusted.gpg del C1F34CDD40CD72DA &&\
    add-apt-repository ppa:ubuntu-toolchain-r/test &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        cmake \
        cmake-curses-gui \
        ninja-build \
        gcc-8 \
        g++-8 \
        llvm-${CLANG_VER} \
        clang-${CLANG_VER} \
        lldb-${CLANG_VER} \
        libclang-${CLANG_VER}-dev \
        clang-format-${CLANG_VER} \
        clang-tidy-${CLANG_VER} \
        libclang-common-${CLANG_VER}-dev \
        llvm-${CLANG_VER}-dev \
        libllvm${CLANG_VER} \
        gdb \
        valgrind \
        kcachegrind \
        ccache \
        cppcheck \
        doxygen \
        graphviz \
        lsof \
        net-tools \
        iputils-ping \
        strace \
        pybind11-dev \
        &&\
    rm -rf /var/lib/apt/lists/*

# Install and setup python tools
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        python3-pip \
        python3-setuptools \
        python3-dev \
        python3-wheel \
        python3-pygments \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    pip3 install \
        python-language-server[all] \
        colour-valgrind \
        mkdocs \
        mkdocs-material &&\
    rm -rf $HOME/.cache/pip

# Setup HW Acceleration for Intel graphic cards
RUN apt-get update &&\
    apt-get install -y \
        libgl1-mesa-glx \
        libgl1-mesa-dri &&\
    rm -rf /var/lib/apt/lists/*

# ====================
# Packages with no ppa
# ====================

# QtCreator
ARG QTCREATOR_VERSION=4.13.3
COPY QtCreatorSetup.js /tmp/QtCreatorSetup.js
COPY qtaccount.ini /root/.local/share/Qt/qtaccount.ini
RUN cd /tmp &&\
    wget http://download.qt.io/official_releases/qtcreator/${QTCREATOR_VERSION%.*}/${QTCREATOR_VERSION}/qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run &&\
    chmod +x qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run &&\
    ./qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run --platform minimal --script QtCreatorSetup.js &&\
    rm /tmp/qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run /tmp/QtCreatorSetup.js &&\
    ln -s /opt/qtcreator/bin/qtcreator.sh /usr/bin/qtcreator &&\
    rm /root/.local/share/Qt/qtaccount.ini

# Gitkraken
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        gconf2 \
        libgtk-3-0 \
        gvfs-bin \
        libnotify4 \
        libnss3 \
        libxtst6 \
        libxkbfile1 \
        xdg-utils \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /tmp &&\
    wget https://release.gitkraken.com/linux/gitkraken-amd64.deb &&\
    apt install /tmp/gitkraken-amd64.deb &&\
    rm /tmp/gitkraken-amd64.deb

# rr
# RUN apt-get update &&\
#     apt-get install -y --no-install-recommends \
#         ccache \
#         cmake \
#         make \
#         g++-multilib \
#         gdb \
#         pkg-config \
#         python3-pexpect \
#         manpages-dev \
#         git \
#         ninja-build \
#         capnproto \
#         libcapnp-dev &&\
#     rm -rf /var/lib/apt/lists/* &&\
#     cd /tmp &&\
#     git clone --depth 1 https://github.com/mozilla/rr.git &&\
#     cd rr && mkdir build && cd build &&\
#     cmake -G Ninja .. &&\
#     cmake --build . &&\
#     cmake --build . --target install &&\
#     rm -r /tmp/rr

# SWIG with Matlab / Octave support
# ... waiting its upstream merge
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        autotools-dev \
        automake \
        bison \
        libpcre3-dev &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /tmp/ &&\
    git clone --depth 1 -b matlab https://github.com/robotology-dependencies/swig.git &&\
    cd swig &&\
    sh autogen.sh &&\
    CC=clang-${CLANG_VER} CXX=clang++-${CLANG_VER} ./configure &&\
    make -j2 &&\
    make install &&\
    rm -r /tmp/swig

# IWYU
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        libncurses5-dev \
        libz-dev \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /tmp &&\
    git clone https://github.com/include-what-you-use/include-what-you-use.git &&\
    cd include-what-you-use &&\
    git checkout clang_${CLANG_VER} &&\
    mkdir build && cd build &&\
    cmake .. \
          -G Ninja \
          -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build . --target install &&\
    rm -r /tmp/include-what-you-use

# Extra tools
ARG EXA_VERSION=0.9.0
ARG BAT_VERSION=0.17.1
ARG STARSHIP_VERSION=0.47.0
RUN \
    mkdir /opt/extra && cd /opt/extra &&\
    # https://github.com/ogham/exa
    wget https://github.com/ogham/exa/releases/download/v${EXA_VERSION}/exa-linux-x86_64-${EXA_VERSION}.zip &&\
    unzip exa-linux-x86_64-${EXA_VERSION}.zip &&\
    mv exa-linux-x86_64 /usr/local/bin/exa &&\
    # https://github.com/junegunn/fzf
    cd /opt/extra &&\
    git clone --depth 1 https://github.com/junegunn/fzf &&\
    yes | ./fzf/install --no-update-rc &&\
    mv ~/.fzf.bash /opt/extra/fzf.bash &&\
    echo "[ -f /opt/extra/fzf.bash ] && source /opt/extra/fzf.bash" >> /etc/bash.bashrc &&\
    # https://github.com/sharkdp/bat
    cd /opt/extra &&\
    wget https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat_${BAT_VERSION}_amd64.deb &&\
    dpkg -i bat_*_amd64.deb && rm bat_*_amd64.deb &&\
    # https://github.com/jonas/tig
    cd /opt/extra &&\
    git clone --depth 1 https://github.com/jonas/tig &&\
    cd tig && make install prefix=/usr/local && cd .. && rm -r tig &&\
    # https://github.com/nvbn/thefuck
    cd /opt/extra &&\
    pip3 install thefuck &&\
    echo '[ -x /usr/local/bin/thefuck ] && eval $(thefuck --alias)' >> /etc/bash.bashrc &&\
    # Enable bash completion
    cd /opt/extra &&\
    LINESTART=$(grep -nr "if ! shopt -oq posix; then" /etc/bash.bashrc | cut -d : -f1) &&\
    LINEEND=$((LINESTART+6)) &&\
    sed -i "$LINESTART,$LINEEND s/#*//" /etc/bash.bashrc &&\
    # https://github.com/starship/starship
    cd /opt/extra &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends fonts-powerline &&\
    rm -rf /var/lib/apt/lists/* &&\
    wget https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz &&\
    tar -xvf starship-x86_64-unknown-linux-gnu.tar.gz &&\
    rm -r starship-x86_64-unknown-linux-gnu.tar.gz &&\
    echo '[ -x /opt/extra/starship ] && eval "$(/opt/extra/starship init bash)"' >> /etc/bash.bashrc &&\
    # https://github.com/rupa/z
    # Always keep this entry as last one
    cd /opt/extra &&\
    wget https://raw.githubusercontent.com/rupa/z/master/z.sh &&\
    echo "[ -f /opt/extra/z.sh ] && . /opt/extra/z.sh" >> /etc/bash.bashrc

# Some QT-Apps/Gazebo don't show controls without this
ENV QT_X11_NO_MITSHM=1

# Setup an additional entrypoint script
COPY setup.sh /usr/sbin/setup_tools.sh
COPY entrypoint.sh /usr/sbin/entrypoint_tools.sh
RUN chmod 755 /usr/sbin/setup_tools.sh &&\
    chmod 755 /usr/sbin/entrypoint_tools.sh
ENTRYPOINT ["/usr/sbin/entrypoint_tools.sh"]
CMD ["bash"]
