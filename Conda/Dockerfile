ARG from=ubuntu:focal
FROM ${from}

# ========
# HEADLESS
# ========

# Change default shell to bash. This is effective only in the Dockerfile.
SHELL ["/bin/bash", "-i", "-c"]

# Create a new runtimeusers group and add root
RUN groupadd -K GID_MIN=100 -K GID_MAX=499 runtimeusers &&\
    gpasswd -a root runtimeusers

# Execute commands as root:runtimeusers so that any user created during runtime has rights
# to operate on the filesystem, and particularly the conda environment
USER root:runtimeusers

# TODO:
# 1. add root to runtimeusers?
# 1. chown runtimeusers
# 2. chmod -R g=u on all files not already owned by runtimeusers

# Setup locales and timezone
ARG TZ=Europe/Rome
ARG DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/localtime &&\
    ln -s /usr/share/zoneinfo/"${TZ}" /etc/localtime &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends locales locales-all tzdata &&\
    rm -rf /var/lib/apt/lists/*

# System utilities
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        software-properties-common \
        apt-transport-https \
        apt-utils \
        git \
        wget \
        nano \
        bash-completion \
        gnupg2 \
        colordiff \
        curl \
        zip \
        unzip \
        lsof \
        net-tools \
        iputils-ping \
        strace \
        less \
        &&\
    rm -rf /var/lib/apt/lists/*

ENV CONDA_PREFIX=/conda
ARG CONDA_PYTHON_VERSION=3.8
ENV MAMBA_ROOT_PREFIX=$CONDA_PREFIX/.mamba

# Install micromamba and create conda environment
RUN cd /usr/local &&\
    wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest \
        | tar -xvj bin/micromamba &&\
    eval "$(micromamba shell hook -s bash)" &&\    
    micromamba create -y -p $CONDA_PREFIX python==$CONDA_PYTHON_VERSION mamba -c conda-forge &&\
    micromamba activate $CONDA_PREFIX &&\
    conda config --system --add channels conda-forge &&\
    conda config --system --set channel_priority strict &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +
    # find $CONDA_PREFIX -not -group runtimeusers -and "!" -type l -exec chgrp runtimeusers {} ";" -exec chmod g+rw {} +

# Enable by default the conda environment for non-root users
RUN echo 'function activate_conda() {' >> /etc/bash.bashrc &&\
    echo '  eval "$(micromamba shell hook -s bash)"' >> /etc/bash.bashrc &&\
    echo '  micromamba activate $CONDA_PREFIX' >> /etc/bash.bashrc &&\
    echo '}' >> /etc/bash.bashrc &&\
    echo '[[ -z $NO_CONDA ]] && activate_conda' >> /etc/bash.bashrc

# RUN groupadd -K GID_MIN=100 -K GID_MAX=499 runtimeusers
# RUN chown -R :runtimeusers $CONDA_PREFIX
# RUN ls -al $CONDA_PREFIX
# RUN mamba install curl
# RUN ls -al $CONDA_PREFIX
# RUN chmod -R g=u $CONDA_PREFIX
# RUN ls -al $CONDA_PREFIX && false

# Install buildchain
RUN mamba install -y \
        compilers cmake make pkg-config ninja pybind11 git &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +

# Default directory with sources
ARG SRC_DIR=/usr/local/src

# Install dartsim
RUN mamba install -y \
        eigen assimp libccd boost openscenegraph nlopt ipopt bullet libode octomap flann tinyxml2 \
        urdfdom xorg-libxi xorg-libxmu freeglut fcl &&\
    cd $SRC_DIR &&\
    git clone https://github.com/diegoferigo/dart &&\
    mkdir -p dart/build && cd dart/build &&\
    cmake .. \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
        -DHAVE_BULLET:BOOL=ON \
        -DHAVE_DOXYGEN:BOOL=OFF \
        -DHAVE_ODE:BOOL=ON \
    &&\
    ninja install &&\
    find $SRC_DIR -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +

# Ignition Robotics
RUN mamba install -y \
        vcstool colcon-common-extensions eigen freeimage gts glib ffmpeg \
        ruby tinyxml2 tinyxml protobuf urdfdom zeromq cppzmq \
        ogre==1.10.12 \
        jsoncpp libzip qt \
        mesa-libgl-devel-cos7-x86_64 libglu &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +
#RUN activate_conda &&\
#    mamba install -y libxrandr-devel-cos7-x86_64 xorg-libxrandr &&\
#    cd $SRC_DIR &&\
#    git clone --depth=1 --branch 1.9.1 https://github.com/OGRECave/ogre &&\
#    mkdir -p ogre/build && cd ogre/build &&\
#    cmake .. \
#        -GNinja \
#        -DCMAKE_BUILD_TYPE=Release \
#        -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
#        -DOGRE_BUILD_COMPONENT_CSHARP=OFF \
#        -DOGRE_BUILD_COMPONENT_PYTHON=OFF \
#    &&\
#    ninja install
RUN cd $SRC_DIR &&\
    mkdir -p workspace/src && cd workspace/src &&\
    wget -q https://raw.githubusercontent.com/ignition-tooling/gazebodistro/master/collection-dome.yaml &&\
    sed -i -e "s|ignitionrobotics/ign-physics|diegoferigo/ign-physics|g" collection-dome.yaml &&\
    sed -i -e "s|ign-physics3|fix/get_force2|g" collection-dome.yaml &&\
    vcs import < collection-dome.yaml &&\
    sed -i "s|if(OGRE_VERSION VERSION_LESS 1.10.3)|if(OGRE_VERSION VERSION_LESS 1.11.0)|g" ign-rendering/ogre/src/CMakeLists.txt &&\
    sed -i "s|if(OGRE_VERSION VERSION_LESS 1.10.1)|if(OGRE_VERSION VERSION_LESS 1.11.0)|g" ign-rendering/ogre/src/CMakeLists.txt &&\
    colcon graph &&\
    find $SRC_DIR -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +
RUN sed -i "s|#include <GL/glxext.h>|//#include <GL/glxext.h>|g" /conda/x86_64-conda-linux-gnu/sysroot/usr/include/GL/glx.h &&\
    cd $SRC_DIR/workspace &&\
    colcon build \
        --merge-install \
        --cmake-args \
        -GNinja \
        -DBUILD_DOCS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        &&\
    echo "[[ -f $SRC_DIR/workspace/install/setup.sh ]] && source $SRC_DIR/workspace/install/setup.sh" >> /etc/bash.bashrc &&\
    find $SRC_DIR -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +
ENV IGN_GAZEBO_PHYSICS_ENGINE_PATH=$SRC_DIR/workspace/install/lib/ign-physics-3/engine-plugins

# Superbuild
RUN mamba install -y \
        ace \
        asio \
        boost \
        eigen \
        glew \
        glfw \
        gsl \
        ipopt \
        libjpeg-turbo \
        libmatio \
        libode \
        libxml2 \
        opencv \
        pkg-config \
        portaudio \
        qt \
        sdl \
        sdl2 \
        sqlite \
        tinyxml \
        jsoncpp \
        &&\
    mamba install -y \
        expat-cos7-x86_64 \
        freeglut \
        libselinux-cos7-x86_64 \
        libxau-cos7-x86_64 \
        libxcb-cos7-x86_64 \
        libxdamage-cos7-x86_64 \
        libxext-cos7-x86_64 \
        libxfixes-cos7-x86_64 \
        libxxf86vm-cos7-x86_64 \
        mesalib \
        mesa-libgl-cos7-x86_64 &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +
RUN cd $SRC_DIR &&\
    git clone https://github.com/robotology/robotology-superbuild &&\
    mkdir -p robotology-superbuild/build && cd robotology-superbuild/build &&\
    cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DROBOTOLOGY_ENABLE_CORE:BOOL=ON \
        -DROBOTOLOGY_ENABLE_DYNAMICS:BOOL=ON \
        -DROBOTOLOGY_ENABLE_DYNAMICS_FULL_DEPS:BOOL=ON \
        -DROBOTOLOGY_ENABLE_ROBOT_TESTING:BOOL=OFF \
        -DROBOTOLOGY_ENABLE_HUMAN_DYNAMICS:BOOL=OFF \
        -DROBOTOLOGY_USES_GAZEBO:BOOL=OFF \
        -DROBOTOLOGY_USES_PYTHON:BOOL=ON \
        -DROBOTOLOGY_USES_OCTAVE:BOOL=OFF \
        -DROBOTOLOGY_USES_MATLAB:BOOL=OFF \
        -DNON_INTERACTIVE_BUILD:BOOL=ON \
        -DBUILD_TESTING:BOOL=OFF \
        -DYCM_DISABLE_SYSTEM_PACKAGES:BOOL=ON \
        -DROBOTOLOGY_PROJECT_TAGS=Stable \
        -DYCM_EP_ADDITIONAL_CMAKE_ARGS="-DWITH_LAPACK=ON -DWITH_MUMPS=ON -DWITH_OSQP=ON -DWITH_PYTHON=ON -DWITH_PYTHON3=ON -DPYTHON_PREFIX=$SRC_DIR/robotology-superbuild/build/install/lib/python3/site-packages -DWITH_QPOASES=ON" \
        .. &&\
    ninja &&\
    sed -i 's/_object/object/g' $SRC_DIR/robotology-superbuild/build/install/lib/python3/site-packages/casadi/casadi.py &&\
    echo 'export PYTHONPATH=$PYTHONPATH:/usr/local/src/robotology-superbuild/build/install/lib/python3.8/dist-packages/' >> /etc/bash.bashrc &&\
    echo 'export PYTHONPATH=$PYTHONPATH:/usr/local/src/robotology-superbuild/build/install/lib/python3.8/site-packages/' >> /etc/bash.bashrc &&\
    echo "source $SRC_DIR/robotology-superbuild/build/install/share/robotology-superbuild/setup.sh" >> /etc/bash.bashrc &&\
    find $SRC_DIR -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +

RUN mamba install -y \
        ipython \
        #tensorflow-gpu \#
        pytorch-gpu \
        tensorboard \
        scipy \
        numpy \
        gym \
        gin-config \
        gputil \
        gpustat \
        lxml \
        matplotlib \
        setuptools_scm \
        ray-rllib ray-tune ray-dashboard &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +
RUN cd $SRC_DIR &&\
    git clone -b devel https://github.com/robotology/gym-ignition &&\
    mkdir gym-ignition/build && cd gym-ignition/build &&\
    cmake .. \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
        &&\
    ninja install &&\
    pip install -e .. &&\
    find $SRC_DIR -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +

# Dotfiles
ENV DOTFILES_SHARE=/usr/local
RUN mamba install -y fish &&\
    git clone https://github.com/diegoferigo/dotfiles /usr/local/dotfiles &&\
    bash /usr/local/dotfiles/bootstrap &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +

# Some QT-Apps/Gazebo don't show controls without this
ENV QT_X11_NO_MITSHM=1

# Devenv support
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        sudo \
        gosu \
        &&\
    rm -rf /var/lib/apt/lists/*
# RUN groupadd -K GID_MIN=100 -K GID_MAX=499 runtimeusers
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV USER_UID=1000
ENV USER_GID=1000
ENV USERNAME=docker

# Setup an additional entrypoint script
COPY setup.sh /usr/sbin/setup_conda.sh
COPY entrypoint.sh /usr/sbin/entrypoint_conda.sh
RUN chmod 755 /usr/sbin/setup_conda.sh &&\
    chmod 755 /usr/sbin/entrypoint_conda.sh
ENTRYPOINT ["/usr/sbin/entrypoint_conda.sh"]
CMD ["bash"]

# ===========
# DEVELOPMENT
# ===========

RUN mamba install -y \
        gdb \
        clang \
        clang-tools \
        ccache \
        valgrind \
        doxygen \
        graphviz \
        cppcheck \
        mkdocs \
        mkdocs-material \
        pygments \
        openssh \
        &&\
    pip install colour-valgrind &&\
    rm -rf $HOME/.cache/pip

# Setup HW Acceleration for Intel graphic cards
#RUN apt-get update &&\
#    apt-get install -y \
#        libgl1-mesa-glx \
#        libgl1-mesa-dri &&\
#    rm -rf /var/lib/apt/lists/*

# QtCreator
ARG QTCREATOR_VERSION=4.14.0
COPY QtCreatorSetup.js /tmp/QtCreatorSetup.js
COPY qtaccount.ini /root/.local/share/Qt/qtaccount.ini
RUN apt-get update &&\
    apt-get install -y --no-install-recommends qtcreator &&\
    rm -rf /var/lib/apt/lists/* &&\
    apt-get remove -y qtcreator &&\
    cd /tmp &&\
    wget http://download.qt.io/official_releases/qtcreator/${QTCREATOR_VERSION%.*}/${QTCREATOR_VERSION}/qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run &&\
    chmod +x qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run &&\
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/conda/lib &&\
    ./qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run --platform minimal --script QtCreatorSetup.js &&\
    rm /tmp/qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run /tmp/QtCreatorSetup.js &&\
    ln -s /opt/qtcreator/bin/qtcreator.sh /usr/bin/qtcreator

ARG PYCHARM_VER=2020.3.3
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        libxtst-dev libxext-dev libxrender-dev libfreetype6-dev libfontconfig1 libgtk2.0-0 libxslt1.1 libxxf86vm1 &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /opt && mkdir pycharm && cd pycharm &&\
    curl -L https://download.jetbrains.com/python/pycharm-community-${PYCHARM_VER}.tar.gz -o /opt/pycharm/installer.tgz &&\
    tar --strip-components=1 -xzf installer.tgz &&\
    rm installer.tgz &&\
    python3 /opt/pycharm/plugins/python-ce/helpers/pydev/setup_cython.py build_ext --inplace &&\
    ln -s /opt/pycharm/bin/pycharm.sh /usr/local/bin/pycharm

USER root:root
