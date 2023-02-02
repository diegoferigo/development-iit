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

# Use clang 11 as default compiler
ENV CC=clang-${CLANG_VER}
ENV CXX=clang++-${CLANG_VER}

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
        swig \
        pybind11-dev \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    echo '[[ $(id -u) -gt 0 ]] && export PATH=/usr/lib/ccache:$PATH' >> /etc/bash.bashrc

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

# IWYU
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        libncurses5-dev \
        zlib1g-dev \
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

# Dotfiles
ENV DOTFILES_SHARE=/usr/local
RUN apt-add-repository ppa:fish-shell/release-3 &&\
    apt-get install -y --no-install-recommends \
        nano git wget curl unzip bash-completion fish \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    git clone https://github.com/diegoferigo/dotfiles /usr/local/dotfiles &&\
    bash /usr/local/dotfiles/bootstrap

# Some QT-Apps/Gazebo don't show controls without this
ENV QT_X11_NO_MITSHM=1

# Setup an additional entrypoint script
COPY setup.sh /usr/sbin/setup_tools.sh
COPY entrypoint.sh /usr/sbin/entrypoint_tools.sh
RUN chmod 755 /usr/sbin/setup_tools.sh &&\
    chmod 755 /usr/sbin/entrypoint_tools.sh
ENTRYPOINT ["/usr/sbin/entrypoint_tools.sh"]
CMD ["bash"]
