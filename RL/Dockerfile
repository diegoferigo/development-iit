ARG from=diegoferigo/development:nvidia-master
FROM ${from}

# Create a new runtimeusers group (it might already exist)
RUN groupadd runtimeusers || true

ENV RL_DIR=/rl
ENV RL_INSTALL=${RL_DIR}/local
ENV RL_SOURCES=${RL_DIR}/sources
ENV PATH=${RL_INSTALL}/bin:${PATH}
ENV CMAKE_PREFIX_PATH=${RL_INSTALL}:${CMAKE_PREFIX_PATH}

RUN mkdir -p ${RL_SOURCES}

ENV CMAKE_GENERATOR="Ninja"
ENV SOURCES_BUILD_TYPE="RelWithDebInfo"
ENV IGN_INSTALL_PREFIX_PATH="/usr"

# =================
# Python VirtualEnv
# =================

ENV VIRTUAL_ENV=/rl/venv
ENV PATH=${VIRTUAL_ENV}/bin:$PATH
ARG GET_PYTHON_VERSION="python3 -c 'from sys import version_info as i; print(f\"{i[0]}.{i[1]}\")'"

RUN apt-get update &&\
    apt-get install -y --no-install-recommends virtualenv &&\
    rm -rf /var/lib/apt/lists/* &&\
    virtualenv -p python$(eval ${GET_PYTHON_VERSION}) ${VIRTUAL_ENV} &&\
    pip install \
        jupyter \
        docker \
        PyYAML \
        matplotlib \
        pytest \
        gym \
        numpy \
        setuptools_scm \
        pybullet \
        ray[all] \
        torch torchvision \
        tensorboard tensorboardX \
        tensorflow tensorflow-probability \
        PyVirtualDisplay PILLOW imageio imageio-ffmpeg \
        sphinx sphinx-rtd-theme sphinx-autodoc-typehints \
        sphinx_fontawesome sphinx-multiversion breathe \
        cvxpy osqp casadi \
        &&\
    rm -r $HOME/.cache/pip &&\
    find ${VIRTUAL_ENV} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# =======
# PyCharm
# =======

ARG PYCHARM_VER=2020.2.5
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        python3-setuptools \
        libpython3-dev \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /opt && mkdir pycharm && cd pycharm &&\
    curl -L https://download.jetbrains.com/python/pycharm-community-${PYCHARM_VER}.tar.gz -o /opt/pycharm/installer.tgz &&\
    tar --strip-components=1 -xzf installer.tgz &&\
    rm installer.tgz &&\
    python3 /opt/pycharm/plugins/python-ce/helpers/pydev/setup_cython.py build_ext --inplace &&\
    ln -s /opt/pycharm/bin/pycharm.sh /usr/local/bin/pycharm

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
        ca-certificates \
        curl \
        lsb-release \
        software-properties-common \
        wget \
        libxml2-dev \
        python3-tk \
        ssh \
        x11-utils \
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

# https://ignitionrobotics.org/docs/citadel/install
# http://gazebosim.org/tutorials?tut=install_dependencies_from_source

# Setup locales and timezone
ARG TZ=Europe/Rome
ARG DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/localtime &&\
    ln -s /usr/share/zoneinfo/"${TZ}" /etc/localtime &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends locales locales-all tzdata &&\
    rm -rf /var/lib/apt/lists/*

ARG IGNITION_DEFAULT_CHANNEL="stable"
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-${IGNITION_DEFAULT_CHANNEL} `lsb_release -cs` main" > \
        /etc/apt/sources.list.d/gazebo-${IGNITION_DEFAULT_CHANNEL}.list &&\
    wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - &&\
    apt-get update &&\
    # Install deps of Ignition Gazebo
    apt-get install -y --no-install-recommends \
        cmake \
        freeglut3-dev \
        libavcodec-dev \
        libavdevice-dev \
        libavformat-dev \
        libavutil-dev \
        libbenchmark-dev \
        libcurl4-openssl-dev \
        libfreeimage-dev \
        libgflags-dev \
        libglew-dev \
        libgts-dev \
        libjsoncpp-dev \
        libogre-1.9-dev \
        libogre-2.1-dev \
        libprotobuf-dev \
        libprotoc-dev \
        libqt5core5a \
        libsqlite3-dev \
        libswscale-dev \
        libtinyxml-dev \
        libtinyxml2-dev \
        libwebsockets-dev \
        libyaml-dev \
        libzip-dev \
        libzmq3-dev \
        pkg-config \
        protobuf-compiler \
        python \
        qml-module-qt-labs-folderlistmodel \
        qml-module-qt-labs-settings \
        qml-module-qtqml-models2 \
        qml-module-qtquick-controls \
        qml-module-qtquick-controls2 \
        qml-module-qtquick-dialogs \
        qml-module-qtquick-layouts \
        qml-module-qtquick2 \
        qtbase5-dev \
        qtdeclarative5-dev \
        qtquickcontrols2-5-dev \
        ruby \
        ruby-dev \
        ruby-ronn \
        swig \
        uuid-dev \
        # Additional
        #libdart-collision-ode-dev \#
        #libdart-dev \#
        #libdart-external-ikfast-dev \#
        #libdart-external-odelcpsolver-dev \#
        #libdart-utils-urdf-dev \#
        &&\
    rm -rf /var/lib/apt/lists/*

# Install DART from sources
# https://dartsim.github.io/install_dart_on_ubuntu.html
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        libeigen3-dev \
        libassimp-dev \
        libccd-dev \
        libfcl-dev \
        libboost-regex-dev \
        libboost-system-dev \
        libopenscenegraph-dev \
        libnlopt-cxx-dev \
        coinor-libipopt-dev \
        libbullet-dev \
        libode-dev \
        liboctomap-dev \
        libflann-dev \
        libtinyxml2-dev \
        liburdfdom-dev \
        libxi-dev \
        libxmu-dev \
        freeglut3-dev \
        libopenscenegraph-dev \
    &&\
    cd ${RL_SOURCES} &&\
    git clone --depth=1 https://github.com/diegoferigo/dart &&\
    mkdir dart/build && cd dart/build &&\
    cmake .. \
        -G"$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DHAVE_BULLET:BOOL=ON \
        -DHAVE_DOXYGEN:BOOL=OFF \
        -DHAVE_ODE:BOOL=ON \
    &&\
    cmake --build . --target install &&\
    find . -type f -not -name 'CMakeCache.txt' -delete &&\
    find ${RL_SOURCES} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+
ENV LD_LIBRARY_PATH=${RL_INSTALL}/lib:${LD_LIBRARY_PATH}

RUN pip install vcstool colcon-common-extensions &&\
    rm -r $HOME/.cache/pip &&\
    find ${VIRTUAL_ENV} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

ENV CC=gcc
ENV CXX=g++
ARG IGN_SOURCES_DATE="20201210"
ARG IGNITION_DISTRIBUTION="dome"
RUN mkdir -p ${RL_SOURCES}/workspace/src &&\
    cd ${RL_SOURCES}/workspace/src &&\
    wget https://raw.githubusercontent.com/ignition-tooling/gazebodistro/master/collection-${IGNITION_DISTRIBUTION}.yaml &&\
    sed -i -e "s|ignitionrobotics/ign-physics|diegoferigo/ign-physics|g" collection-dome.yaml &&\
    sed -i -e "s|ign-physics3|fix/get_force2|g" collection-dome.yaml &&\
    vcs import < collection-${IGNITION_DISTRIBUTION}.yaml &&\
    sed -i -e "s|this->dataPtr->SetRemovedComponentsMsgs|//this->dataPtr->SetRemovedComponentsMsgs|g" \
        ign-gazebo/src/EntityComponentManager.cc &&\
    cd ${RL_SOURCES}/workspace &&\
    colcon graph &&\
    colcon build \
        --cmake-args \
        -G"$CMAKE_GENERATOR" \
        -DBUILD_TESTING:BOOL=OFF \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        --merge-install \
        &&\
    find build/ -type f -not -name 'CMakeCache.txt' -delete &&\
    find ${RL_SOURCES}/workspace -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+
RUN echo "source ${RL_SOURCES}/workspace/install/setup.bash" >> /etc/bash.bashrc

# =============
# Install Julia
# =============

# ARG JULIA_VER=1.4.1
# # ENV DEVENV_PATH=${DEVENV_PATH}:/opt/julia/bin
# ENV PATH=${PATH}:/opt/julia/bin
# 
# RUN cd /tmp &&\
#     wget https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_VER%.*}/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
#     cd /opt &&\
#     tar xvf /tmp/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
#     rm /tmp/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
#     mv julia-${JULIA_VER} julia &&\
#     /opt/julia/bin/julia --version
# 
# ARG ATOM_VERSION=v1.46.0
# ARG ATOM_PKG_TMP=/tmp/atom_packages.txt
# RUN apt-get update && \
#     apt-get install -y --no-install-recommends \
#         ca-certificates \
#         curl \
#         fakeroot \
#         gconf2 \
#         gconf-service \
#         git \
#         gvfs-bin \
#         libasound2 \
#         libcap2 \
#         libgconf-2-4 \
#         libgcrypt20 \
#         libgtk2.0-0 \
#         libgtk-3-0 \
#         libnotify4 \
#         libnss3 \
#         libx11-xcb1 \
#         libxkbfile1 \
#         libxss1 \
#         libxtst6 \
#         libgl1-mesa-glx \
#         libgl1-mesa-dri \
#         policykit-1 \
#         python \
#         xdg-utils &&\
#     rm -rf /var/lib/apt/lists/* &&\
#     curl -L https://github.com/atom/atom/releases/download/${ATOM_VERSION}/atom-amd64.deb > /tmp/atom.deb && \
#     dpkg -i /tmp/atom.deb && \
#     rm -f /tmp/atom.deb && \
#     echo "ink" >> ${ATOM_PKG_TMP} &&\ 
#     echo "uber-juno" >> ${ATOM_PKG_TMP} &&\ 
#     echo "tool-bar" >> ${ATOM_PKG_TMP} &&\
#     echo "indent-detective" >> ${ATOM_PKG_TMP} &&\
#     echo "latex-completions" >> ${ATOM_PKG_TMP} &&\
#     echo "hyperclick" >> ${ATOM_PKG_TMP} &&\ 
#     echo "language-julia" >> ${ATOM_PKG_TMP} &&\ 
#     echo "julia-client" >> ${ATOM_PKG_TMP} &&\
#     apm install --packages-file ${ATOM_PKG_TMP} &&\
#     cp -r /root/.atom /opt/dotatom &&\
#     find /opt/dotatom -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

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

# Execute RUN commands in an interactive shell (loading /etc/bash.bashrc)
SHELL ["/bin/bash", "-i", "-c"]

RUN pip install --pre gym-ignition[website] &&\
    pip install git+https://github.com/dic-iit/gazebo-scenario-plugins &&\
    rm -rf $HOME/.cache/pip &&\
    find ${VIRTUAL_ENV} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# =============
# FIX OWNERSHIP
# =============

RUN find ${RL_DIR} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${VIRTUAL_ENV} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+
    
# VSCode
# RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add - &&\
#     sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" &&\
#     sudo apt-get install -y --no-install-recommends code &&\
#     sudo rm -rf /var/lib/apt/lists/*

# ====================
# Image initialization
# ====================

COPY setup.sh /usr/sbin/setup_rl.sh
COPY entrypoint.sh /usr/sbin/entrypoint_rl.sh
RUN chmod 755 /usr/sbin/setup_rl.sh &&\
    chmod 755 /usr/sbin/entrypoint_rl.sh
ENTRYPOINT ["/usr/sbin/entrypoint_rl.sh"]
CMD ["bash"]
