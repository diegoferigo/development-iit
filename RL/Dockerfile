ARG from=diegoferigo/development:nvidia-master
FROM ${from}

# Create a new runtimeusers group (it might already exist)
RUN groupadd runtimeusers || true

ENV RL_DIR=/rl
ENV RL_INSTALL=${RL_DIR}/local
ENV RL_SOURCES=${RL_DIR}/sources
ENV DEVENV_PATH=${RL_INSTALL}/bin:${DEVENV_PATH}
ENV CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}:${RL_INSTALL}

RUN mkdir -p ${RL_SOURCES}

# =================
# Python VirtualEnv
# =================

ENV VIRTUAL_ENV=/rl/venv
ENV DEVENV_PATH=${VIRTUAL_ENV}/bin:$DEVENV_PATH

RUN pip3 install virtualenv &&\
    virtualenv ${VIRTUAL_ENV} &&\
    ${VIRTUAL_ENV}/bin/pip3 install \
        jupyter \
        docker \
        PyYAML \
        matplotlib \
        pytest \
        gym \
        numpy \
        setuptools_scm \
        cloudpickle \
        pybullet \
        ray[rllib] gputil \
        # tf-nightly-gpu tfp-nightly \#
        PyVirtualDisplay PILLOW imageio imageio-ffmpeg \
        &&\
    rm -r $HOME/.cache &&\
    #${VIRTUAL_ENV}/bin/pip3 install git+https://github.com/tensorflow/agents &&\#
    #${VIRTUAL_ENV}/bin/pip3 install --upgrade --force-reinstall tb-nightly &&\#
    find ${VIRTUAL_ENV} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# =======
# PyCharm
# =======

ARG PYCHARM_VER=2019.3.4
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        python-setuptools \
        python3-setuptools \
        libpython-dev \
        libpython3-dev \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /opt && mkdir pycharm && cd pycharm &&\
    curl -L https://download.jetbrains.com/python/pycharm-community-${PYCHARM_VER}.tar.gz -o /opt/pycharm/installer.tgz &&\
    tar --strip-components=1 -xzf installer.tgz &&\
    rm installer.tgz &&\
    python2 /opt/pycharm/plugins/python-ce/helpers/pydev/setup_cython.py build_ext --inplace &&\
    python3 /opt/pycharm/plugins/python-ce/helpers/pydev/setup_cython.py build_ext --inplace &&\
    ln -s /opt/pycharm/bin/pycharm.sh /usr/local/bin/pycharm

# ========
# iDynTree
# ========

# Use python bindings from fork
RUN cd ${RL_SOURCES} &&\
    git clone -b feature/numpy-and-ik --depth=1 https://github.com/diegoferigo/idyntree &&\
    mkdir -p idyntree/build &&\
    cd idyntree/build &&\
    cmake \
          -GNinja \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DIDYNTREE_SHARED_LIBRARY:BOOL=OFF \
          -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
          -DIDYNTREE_USES_PYTHON:BOOL=ON \
          -DIDYNTREE_USES_PYTHON_VERSION=3.6 \
          -DPYTHON_EXECUTABLE=${VIRTUAL_ENV}/bin/python \
          -DPYTHON_NUMPY_INCLUDE_DIR:PATH=${VIRTUAL_ENV}/lib/python3.6/site-packages/numpy/core/include \
          -DIDYNTREE_USES_KDL:BOOL=OFF \
          -DYCM_USE_DEPRECATED=OFF \
          .. &&\
    cmake --build . --target install &&\
    find ${RL_DIR} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+
ENV PYTHONPATH=${RL_INSTALL}/lib/python3.6/site-packages:${PYTHONPATH}

# ============
# Common tools
# ============

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        apt-utils \
        gnupg \
        gnupg2 \
        apt-utils \
        ca-certificates \
        curl \
        lsb-release \
        software-properties-common \
        wget \
        libxml2-dev \
        python3-tk \
        ssh \
        &&\
    rm -rf /var/lib/apt/lists/*

# =================
# Development tools
# =================

RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - &&\
    apt-add-repository "deb https://apt.kitware.com/ubuntu/ `lsb_release -cs` main" &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends \
        git \
        cmake \
        cmake-curses-gui \
        build-essential \
        gcc-8 \
        g++-8 \
        ninja-build \
        mercurial \
        python3-pip \
        xvfb \
        &&\
    rm -rf /var/lib/apt/lists/*

# =================
# Ignition Robotics
# =================

# Uninstall gazebo classic and protobuf
RUN apt remove -y gazebo10 libgazebo10-dev libprotobuf-dev protobuf-compiler libprotobuf10 libprotobuf-lite10 &&\
    apt autoremove -y

# https://ignitionrobotics.org/docs/citadel/install
# http://gazebosim.org/tutorials?tut=install_dependencies_from_source

# Install protobuf
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        libtool \
        autoconf \
        automake \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd ${RL_SOURCES} &&\
    git clone --depth 1 -b v3.8.0 https://github.com/google/protobuf &&\
    cd protobuf &&\
    git submodule update --init --recursive &&\
    ./autogen.sh &&\
    ./configure &&\
    make -j8 &&\
    make install

# Ignition Robotics dependencies
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        ruby-dev \
        ruby \
        ruby-ronn \
        freeglut3-dev \
        libglew-dev \
        libtinyxml-dev \
        libzmq3-dev \
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
        # ign-fuel-tools
        libjsoncpp-dev \
        libzip-dev \
        libyaml-dev \
        libcurl4-openssl-dev \
        # ign-transport
        libzmqpp-dev \
        uuid-dev \
        # ign-rendering
        libogre-1.9-dev \
        #libogre-2.1-dev \
        # ign-tools
        libwebsockets-dev \
        #ign-gui
        qtquickcontrols2-5-dev \
        # ign-gazebo compile deps
        libgflags-dev \
        # ign-gazebo runtime deps
        qtbase5-dev \
        qtdeclarative5-dev \
        libqt5core5a \
        qml-module-qtquick2 \
        qml-module-qtquick-controls \
        qml-module-qtquick-controls2 \
        qml-module-qtquick-dialogs \
        qml-module-qtquick-layouts \
        qml-module-qtqml-models2 \
        qml-module-qt-labs-folderlistmodel \
        qml-module-qt-labs-settings \
        &&\
    rm -rf /var/lib/apt/lists/*

# Setup locales and timezone
ENV TZ=Europe/Rome
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update &&\
    apt-get install -y --no-install-recommends locales locales-all tzdata &&\
    rm -rf /var/lib/apt/lists/* &&\
    echo "${TZ}" | tee /etc/timezone &&\
    dpkg-reconfigure --frontend noninteractive tzdata

# =======
# CITADEL
# =======

ARG IGN_CMAKE_VER=2
ARG IGN_TOOLS_VER=""
ARG IGN_MATH_VER=6
ARG IGN_COMMON_VER=3
ARG IGN_MSG_VER=5
ARG SDFORMAT_VER=9
ARG IGN_FUEL_TOOLS_VER=4
ARG IGN_PLUGIN_VER=""
ARG IGN_TRANSPORT_VER=8
ARG IGN_PHYSICS_VER=2
ARG IGN_RENDERING_VER=3
ARG IGN_GUI_VER=3
ARG IGN_SENSORS_VER=3
ARG IGN_GAZEBO_VER=3
ARG IGN_LAUNCH_VER=2

# Add gazebo ppa and install other deps.
# We want to install from source ign-gazebo, ign-physics, sdformat, and all the components that depend on protobuf.
# ARG IGNITION_DEFAULT_CHANNEL="stable"
ARG IGNITION_DEFAULT_CHANNEL="prerelease"
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-${IGNITION_DEFAULT_CHANNEL} `lsb_release -cs` main" > \
        /etc/apt/sources.list.d/gazebo-${IGNITION_DEFAULT_CHANNEL}.list &&\
    wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends \
        libdart6-all-dev \
        # Install from ppa base components
        libignition-cmake${IGN_CMAKE_VER}-dev \
        libignition-tools${IGN_TOOLS_VER}-dev \
        libignition-math${IGN_MATH_VER}-dev \
        libignition-math${IGN_MATH_VER}-eigen3-dev \
        libignition-common${IGN_COMMON_VER}-dev \
        libignition-plugin${IGN_PLUGIN_VER}-dev \
        libignition-rendering${IGN_RENDERING_VER} \
        libignition-rendering${IGN_RENDERING_VER}-ogre1-dev \
        #libignition-rendering${IGN_RENDERING_VER}-ogre2-dev \#
        &&\
    rm -rf /var/lib/apt/lists/*

# Download all the sources
ARG RL_SOURCES="20200416"
RUN mkdir -p ${RL_SOURCES} &&\
    cd ${RL_SOURCES} &&\
    mkdir -p ${RL_SOURCES} &&\
    git clone https://github.com/ignitionrobotics/ign-transport -b ign-transport${IGN_TRANSPORT_VER} &&\
    git clone https://github.com/ignitionrobotics/ign-msgs -b ign-msgs${IGN_MSG_VER} &&\
    git clone https://github.com/osrf/sdformat -b sdf${SDFORMAT_VER} &&\
    git clone https://github.com/ignitionrobotics/ign-physics -b ign-physics${IGN_PHYSICS_VER} &&\
    git clone https://github.com/ignitionrobotics/ign-sensors -b ign-sensors${IGN_SENSORS_VER} &&\
    git clone https://github.com/ignitionrobotics/ign-gui -b ign-gui${IGN_GUI_VER} &&\
    git clone https://github.com/ignitionrobotics/ign-gazebo -b ign-gazebo${IGN_GAZEBO_VER} &&\
    git clone https://github.com/ignitionrobotics/ign-launch -b ign-launch${IGN_LAUNCH_VER} &&\
    git clone https://github.com/ignitionrobotics/ign-fuel-tools -b ign-fuel-tools${IGN_FUEL_TOOLS_VER} &&\
    chgrp -R runtimeusers ${RL_DIR} && chmod -R g+rw ${RL_DIR}

ENV CMAKE_GENERATOR="Ninja"
ENV SOURCES_BUILD_TYPE="RelWithDebInfo"
ENV IGN_INSTALL_PREFIX_PATH="/usr"

ENV CC="clang-10"
ENV CXX="clang++-10"

# sdformat
RUN cd ${RL_SOURCES}/sdformat &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${IGN_INSTALL_PREFIX_PATH} \
        # TODO: build tests OFF?
        .. &&\
    cmake --build . --target install &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ign-msgs
RUN cd ${RL_SOURCES}/ign-msgs &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${IGN_INSTALL_PREFIX_PATH} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    cmake --build . --target install &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ign-transport
RUN cd ${RL_SOURCES}/ign-transport &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${IGN_INSTALL_PREFIX_PATH} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    cmake --build . --target install &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ign-physics
RUN cd ${RL_SOURCES}/ign-physics &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${IGN_INSTALL_PREFIX_PATH} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    cmake --build . --target install &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ign-sensors
RUN cd ${RL_SOURCES}/ign-sensors &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${IGN_INSTALL_PREFIX_PATH} \
        -DDRI_TESTS:BOOL=FALSE \
        .. &&\
    cmake --build . --target install &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ign-gui
RUN cd ${RL_SOURCES}/ign-gui &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${IGN_INSTALL_PREFIX_PATH} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    cmake --build . --target install &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ign-fuel-tools
RUN cd ${RL_SOURCES}/ign-fuel-tools &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${IGN_INSTALL_PREFIX_PATH} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    cmake --build . --target install &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ign-gazebo
RUN cd ${RL_SOURCES}/ign-gazebo &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${IGN_INSTALL_PREFIX_PATH} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    cmake --build . --target install &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ign-launch
RUN cd ${RL_SOURCES}/ign-launch &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${IGN_INSTALL_PREFIX_PATH} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    cmake --build . --target install &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# Fix permissions of the directories inside RL_DIR
RUN find ${RL_DIR} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# =============
# Install Julia
# =============

ARG JULIA_VER=1.2.0
ENV DEVENV_PATH=${DEVENV_PATH}:/opt/julia/bin

RUN cd /tmp &&\
    wget https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_VER%.*}/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
    cd /opt &&\
    tar xvf /tmp/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
    rm /tmp/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
    mv julia-${JULIA_VER} julia &&\
    /opt/julia/bin/julia --version

ARG ATOM_VERSION=v1.40.1
ARG ATOM_PKG_TMP=/tmp/atom_packages.txt
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        fakeroot \
        gconf2 \
        gconf-service \
        git \
        gvfs-bin \
        libasound2 \
        libcap2 \
        libgconf-2-4 \
        libgcrypt20 \
        libgtk2.0-0 \
        libgtk-3-0 \
        libnotify4 \
        libnss3 \
        libx11-xcb1 \
        libxkbfile1 \
        libxss1 \
        libxtst6 \
        libgl1-mesa-glx \
        libgl1-mesa-dri \
        policykit-1 \
        python \
        xdg-utils &&\
    rm -rf /var/lib/apt/lists/* &&\
    curl -L https://github.com/atom/atom/releases/download/${ATOM_VERSION}/atom-amd64.deb > /tmp/atom.deb && \
    dpkg -i /tmp/atom.deb && \
    rm -f /tmp/atom.deb && \
    echo "ink" >> ${ATOM_PKG_TMP} &&\ 
    echo "uber-juno" >> ${ATOM_PKG_TMP} &&\ 
    echo "tool-bar" >> ${ATOM_PKG_TMP} &&\
    echo "indent-detective" >> ${ATOM_PKG_TMP} &&\
    echo "latex-completions" >> ${ATOM_PKG_TMP} &&\
    echo "hyperclick" >> ${ATOM_PKG_TMP} &&\ 
    echo "language-julia" >> ${ATOM_PKG_TMP} &&\ 
    echo "julia-client" >> ${ATOM_PKG_TMP} &&\
    apm install --packages-file ${ATOM_PKG_TMP} &&\
    cp -r /root/.atom /opt/dotatom &&\
    find /opt/dotatom -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# TODO: these packages are not available to the user.
# Follow: https://discourse.julialang.org/t/how-does-one-set-up-a-centralized-julia-installation/13922/21
#RUN \
#    /opt/julia/bin/julia -e 'import Pkg; Pkg.add([\
#        "IJulia",\
#        "Plots",\
#        "PyPlot",\
#        "LaTeXStrings",\
#        ]);'

# =======================
# Install projects for RL
# =======================

# Install SWIG 4 from sources
ARG SWIG_REL="rel-4.0.1"
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        autotools-dev \
        automake \
        bison \
        libpcre3-dev &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /tmp/ &&\
    git clone --depth 1 -b ${SWIG_REL} https://github.com/swig/swig.git &&\
    cd swig &&\
    sh autogen.sh &&\
    ./configure &&\
    make -j2 &&\
    make install &&\
    rm -r /tmp/swig

# =============
# FIX OWNERSHIP
# =============

RUN find ${RL_DIR} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${VIRTUAL_ENV} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ====================
# Image initialization
# ====================

COPY setup.sh /usr/sbin/setup_rl.sh
COPY entrypoint.sh /usr/sbin/entrypoint_rl.sh
RUN chmod 755 /usr/sbin/setup_rl.sh
RUN chmod 755 /usr/sbin/entrypoint_rl.sh
ENTRYPOINT ["/usr/sbin/entrypoint_rl.sh"]
CMD ["bash"]
