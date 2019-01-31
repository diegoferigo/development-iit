ARG from=diegoferigo/development:nvidia-master
FROM ${from}
MAINTAINER Diego Ferigo <dgferigo@gmail.com>

ENV RL_DIR=/rl
ENV RL_INSTALL=${RL_DIR}/local
ENV RL_SOURCES=${RL_DIR}/sources
ENV DEVENV_PATH=${RL_INSTALL}/bin:${DEVENV_PATH}
ENV CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}:${RL_INSTALL}

# =======================================
# Install ignition libraries from sources
# =======================================

# http://gazebosim.org/tutorials?tut=install_dependencies_from_source

# Remove gazebo9 if present
RUN apt-get remove -y '.*sdformat.*' '.*ignition-.*' || true

# Ignition needs g++ 8
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        g++-8 \
        &&\
    rm -rf /var/lib/apt/lists/*
ENV CC="gcc-8"
ENV CXX="g++-8"

# Common tools and libraries
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        git \
        cmake \
        cmake-curses-gui \
        wget \
        ninja-build \
        mercurial \
        ca-certificates \
        apt-utils \
        &&\
    rm -rf /var/lib/apt/lists/*

# Ignition dependencies
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        ruby-dev \
        ruby \
        # ign-common
        libtinyxml2-dev \
        libswscale-dev \
        libavdevice-dev \
        libavformat-dev \
        libavcodec-dev \
        libavutil-dev \
        libfreeimage-dev \
        libgts-dev \
        libsqlite3-dev \
        # sdformat
        python \
        libboost-system-dev \
        libxml2-utils \
        # ign-msgs
        libprotoc-dev \
        libprotobuf-dev \
        protobuf-compiler \
        # ign-transport
        libzmqpp-dev \
        uuid-dev \
        # ign-rendering
        libogre-1.9-dev \
        #ign-gui
        qtquickcontrols2-5-dev \
        # ign-gazebo compile deps
        libgflags-dev \
        # ign-gazebo runtime deps
        qtbase5-dev \
        qtdeclarative5-dev \
        qml-module-qtquick2 \
        qml-module-qtquick-controls \
        qml-module-qtquick-controls2 \
        qml-module-qtquick-dialogs \
        qml-module-qtquick-layouts \
        qml-module-qt-labs-folderlistmodel \
        qml-module-qt-labs-settings \
        &&\
    rm -rf /var/lib/apt/lists/*

# Download all the sources
ARG RL_SOURCES="20181227"
RUN mkdir -p ${RL_SOURCES} &&\
    cd ${RL_SOURCES} &&\
    mkdir -p ${RL_SOURCES} &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-cmake -b gz11 &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-math -b gz11 &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-common -b gz11 &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-tools &&\
    hg clone https://bitbucket.org/osrf/sdformat -b gz11 &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-msgs -b gz11 &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-transport -b gz11 &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-plugin &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-physics &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-rendering -b gz11 &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-gui -b gz11 &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-gazebo &&\
    hg clone https://bitbucket.org/ignitionrobotics/ign-sensors &&\
    git clone https://github.com/bulletphysics/bullet3.git &&\
    git clone git://github.com/dartsim/dart.git

# TODO: There are problems with ignition and ninja.
#       Also bullet has problems during the install.
ENV CMAKE_GENERATOR="Unix Makefiles"
ENV CMAKE_EXTRA_OPTIONS="-j8"

# Bullet
RUN cd ${RL_SOURCES}/bullet3 &&\
    mkdir -p build && cd build &&\
    cmake \
    -G"$CMAKE_GENERATOR" \
    -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
    -DBUILD_SHARED_LIBS=ON \
    .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS

# Dart core
# Following https://github.com/dartsim/dart/wiki/DART-5.1-Installation-for-Ubuntu#install-dart-from-source
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        libeigen3-dev \
        libassimp-dev \
        libccd-dev \
        libfcl-dev \
        libxi-dev \
        libxmu-dev \
        freeglut3-dev \
        libode-dev \
        # Boost
        libboost-regex-dev \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd ${RL_SOURCES}/dart &&\
    git checkout release-6.7 &&\
    mkdir -p build && cd build &&\
    cmake \
        -GNinja \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS

# ign-cmake
RUN cd ${RL_SOURCES}/ign-cmake &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS

# ing-math
RUN cd ${RL_SOURCES}/ign-math &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# ign-common
RUN cd ${RL_SOURCES}/ign-common &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# ign-tools
RUN cd ${RL_SOURCES}/ign-tools &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# sdformat
RUN cd ${RL_SOURCES}/sdformat &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install
    # TODO: with clang here it does not find "limits.h"

# ign-msgs
RUN cd ${RL_SOURCES}/ign-msgs &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# ign-transport
RUN cd ${RL_SOURCES}/ign-transport &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# ign-plugin
RUN cd ${RL_SOURCES}/ign-plugin &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# ign-physics
RUN cd ${RL_SOURCES}/ign-physics &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# ign-rendering
# TODO: nvidia optix support
RUN cd ${RL_SOURCES}/ign-rendering &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# ign-sensors
RUN cd ${RL_SOURCES}/ign-sensors &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DDRI_TESTS:BOOL=FALSE \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# ign-gui
RUN cd ${RL_SOURCES}/ign-gui &&\
    sed -i 's/LoadLibrary/LoadLib/' src/Application.cc &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# ign-gazebo
RUN cd ${RL_SOURCES}/ign-gazebo &&\
    sed -i 's/LoadLibrary/LoadLib/' src/SystemLoader.cc &&\
    sed -i 's/LoadLibrary/LoadLib/' src/systems/physics/Physics.cc &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install

# =======================
# Install Python packages
# =======================

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        ipython3 \
        jupyter \
        jupyter-notebook \
        jupyter-nbconvert \
        python3-docker \
        python3-yaml \
        python3-matplotlib \
        python3-tk \
        &&\
    rm -rf /var/lib/apt/lists/*

# =============
# Install Julia
# =============

ARG JULIA_VER=1.0.2
ENV PATH=$PATH:/opt/julia/bin

RUN cd /tmp &&\
    wget https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_VER%.*}/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
    cd /opt &&\
    tar xvf /tmp/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
    rm /tmp/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
    mv julia-${JULIA_VER} julia &&\
    julia --version

# TODO: these packages are not available to the user.
# Follow: https://discourse.julialang.org/t/how-does-one-set-up-a-centralized-julia-installation/13922/21
RUN \
    julia -e 'import Pkg; Pkg.add([\
        "IJulia",\
        "Plots",\
        "PyPlot",\
        "LaTeXStrings",\
        ]);'
