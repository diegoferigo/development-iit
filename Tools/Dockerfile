ARG from=diegoferigo/devenv:latest
FROM ${from}
MAINTAINER Diego Ferigo <dgferigo@gmail.com>

# Utilities
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        sudo \
        software-properties-common \
        apt-transport-https \
        wget \
        nano \
        dbus-x11 \
        tree \
        bash-completion \
        libgnome-keyring0 \
        gnupg2 \
        colordiff \
        octave \
        locales \
        trash-cli \
        xterm \
        &&\
    rm -rf /var/lib/apt/lists/*

# Setup locales and tzdata
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen && \
    locale-gen &&\
    update-locale LANG="en_US.UTF-8" &&\
    rm -rf /etc/localtime &&\
    ln -s /usr/share/zoneinfo/Europe/Rome /etc/localtime

# Updated clang ppa
ARG clang_version=6.0
ENV CLANG_VER=${clang_version}

# Build and development tools
RUN wget -nv -O - http://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - &&\
    apt-add-repository -y "deb http://apt.llvm.org/`lsb_release -cs`/ llvm-toolchain-`lsb_release -cs`-${CLANG_VER} main" &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        cmake \
        cmake-curses-gui \
        ninja-build \
        llvm-${CLANG_VER} \
        clang-${CLANG_VER} \
        lldb-${CLANG_VER} \
        libclang-${CLANG_VER}-dev \
        clang-format-${CLANG_VER} \
        libclang-common-${CLANG_VER}-dev \
        llvm-${CLANG_VER}-dev \
        libllvm${CLANG_VER} \
        gdb \
        valgrind \
        valkyrie \
        ccache \
        doxygen \
        graphviz \
        lsof \
        net-tools \
        iputils-ping \
        strace \
        &&\
    rm -rf /var/lib/apt/lists/*

# Install and setup python tools
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        python3-pip \
        python3-setuptools \
        spyder3 \
        python3-dev \
        python3-wheel \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    pip3 install \
        python-language-server[all] \
        colour-valgrind \
        Pygments \
        mkdocs \
        mkdocs-material

# Setup HW Acceleration for Intel graphic cards
RUN apt-get update &&\
    apt-get install -y \
        libgl1-mesa-glx \
        libgl1-mesa-dri &&\
    rm -rf /var/lib/apt/lists/*

# Atom Editor
# In the future, check if libxss1 will become an atom package dependency
RUN add-apt-repository -y ppa:webupd8team/atom &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends \
        libxss1 \
        atom &&\
    rm -rf /var/lib/apt/lists/*

# Atom packages
COPY atom_packages.txt /usr/local/etc
RUN apm install --packages-file /usr/local/etc/atom_packages.txt

# Packages with no ppa
# ====================

# QtCreator
ARG QTCREATOR_VERSION=4.8.0
COPY QtCreatorSetup.js /tmp/QtCreatorSetup.js
RUN cd /tmp &&\
    wget http://download.qt.io/official_releases/qtcreator/${QTCREATOR_VERSION%.*}/${QTCREATOR_VERSION}/qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run &&\
    chmod +x qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run &&\
    ./qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run --platform minimal --script QtCreatorSetup.js &&\
    rm /tmp/qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run /tmp/QtCreatorSetup.js &&\
    ln -s /opt/qtcreator/bin/qtcreator.sh /usr/bin/qtcreator

# Gitkraken
RUN cd /tmp &&\
    wget https://release.gitkraken.com/linux/gitkraken-amd64.deb &&\
    apt install /tmp/gitkraken-amd64.deb &&\
    rm /tmp/gitkraken-amd64.deb

# Updated CMake for QtCreator
ARG CMAKE_VER=3.13.1
RUN cd /tmp &&\
    wget https://cmake.org/files/v${CMAKE_VER%.*}/cmake-${CMAKE_VER}-Linux-x86_64.sh &&\
    chmod +x cmake-${CMAKE_VER}-Linux-x86_64.sh &&\
    mkdir /opt/cmake &&\
    sh cmake-${CMAKE_VER}-Linux-x86_64.sh --prefix=/opt/cmake --skip-license &&\
    rm /tmp/cmake-${CMAKE_VER}-Linux-x86_64.sh
ENV PATH=/opt/cmake/bin:$PATH

# rr
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        ccache \
        cmake \
        make \
        g++-multilib \
        gdb \
        pkg-config \
        python3-pexpect \
        manpages-dev \
        git \
        ninja-build \
        capnproto \
        libcapnp-dev &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /tmp &&\
    git clone https://github.com/mozilla/rr.git &&\
    cd rr && mkdir build && cd build &&\
    CC=clang-${CLANG_VER} CXX=clang++-${CLANG_VER} cmake -G Ninja .. &&\
    cmake --build . &&\
    cmake --build . --target install &&\
    rm -r /tmp/rr

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
    git clone -b matlab https://github.com/robotology-dependencies/swig.git &&\
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
          -DCMAKE_BUILD_TYPE=Release \
          -DIWYU_LLVM_ROOT_PATH=/usr/lib/llvm-${CLANG_VER} &&\
    /opt/cmake/bin/cmake --build . --target install &&\
    rm -r /tmp/include-what-you-use

# Some QT-Apps/Gazebo don't show controls without this
ENV QT_X11_NO_MITSHM=1

# Setup an additional entrypoint script
COPY setup.sh /usr/sbin/setup_tools.sh
COPY entrypoint.sh /usr/sbin/entrypoint_tools.sh
RUN chmod 755 /usr/sbin/setup_tools.sh
RUN chmod 755 /usr/sbin/entrypoint_tools.sh
ENTRYPOINT ["/usr/sbin/entrypoint_tools.sh"]
CMD ["bash"]
