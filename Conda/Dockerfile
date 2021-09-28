ARG from=ubuntu:focal
FROM ${from}

# TODO: https://jcristharif.com/conda-docker-tips.html

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
        tree \
        htop \
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
    micromamba create -y -p $CONDA_PREFIX "python==$CONDA_PYTHON_VERSION.*" mamba -c conda-forge &&\
    micromamba activate $CONDA_PREFIX &&\
    conda config --system --add channels conda-forge &&\
    conda config --system --set channel_priority strict &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    conda clean -afy

# Enable by default the conda environment for all users
RUN echo 'function activate_conda() {' >> /etc/bash.bashrc &&\
    echo '  eval "$(micromamba shell hook -s bash)"' >> /etc/bash.bashrc &&\
    echo '  micromamba activate $CONDA_PREFIX' >> /etc/bash.bashrc &&\
    echo '}' >> /etc/bash.bashrc &&\
    echo '[[ -z $NO_CONDA ]] && activate_conda' >> /etc/bash.bashrc

# Install buildchain
# https://github.com/diegoferigo/development-iit/issues/9
RUN echo 'binutils < 2.36.0' >> $CONDA_PREFIX/conda-meta/pinned
RUN mamba install -y \
        compilers cmake make pkg-config ninja pybind11 git boa &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    conda clean -afy

# Default directory with sources
ARG SRC_DIR=/usr/local/src

# Install dartsim
RUN mamba install -y \
        eigen assimp libccd boost openscenegraph nlopt ipopt bullet libode octomap flann tinyxml2 \
        urdfdom xorg-libxi xorg-libxmu freeglut fcl &&\
    cd $SRC_DIR &&\
    git clone https://github.com/diegoferigo/dart &&\
    mkdir -p dart/build && cd dart/build &&\
    sed -i "s/if(TARGET dart AND NOT DART_BUILD_DARTPY)/if(TARGET dart AND NOT DART_BUILD_DARTPY AND OFF)/g" \
       ../CMakeLists.txt &&\
    cmake .. \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
        -DHAVE_BULLET:BOOL=ON \
        -DHAVE_DOXYGEN:BOOL=OFF \
        -DHAVE_ODE:BOOL=ON \
        -DDART_BUILD_DARTPY:BOOL=OFF \
        -DDART_BUILD_EXTRAS:BOOL=OFF \
    &&\
    ninja install &&\
    find . -type f -not -name 'CMakeCache.txt' -delete &&\
    find $SRC_DIR -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    conda clean -afy

# Ignition Robotics dependencies
RUN echo 'protobuf 3.15.*' >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo 'ogre 1.10.*' >> $CONDA_PREFIX/conda-meta/pinned
RUN mamba install -y \
        vcstool colcon-common-extensions eigen freeimage gts glib ffmpeg \
        ruby tinyxml2 tinyxml protobuf urdfdom zeromq cppzmq libwebsockets \
        ogre jsoncpp libzip qt \
        mesa-libgl-devel-cos7-x86_64 libx11-devel-cos7-x86_64 libglu &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    conda clean -afy

# Ignition Robotics
ARG IGNITION_DISTRIBUTION=edifice
RUN cd $SRC_DIR &&\
    mkdir -p workspace/src && cd workspace/src &&\
    wget -q https://raw.githubusercontent.com/ignition-tooling/gazebodistro/master/collection-$IGNITION_DISTRIBUTION.yaml &&\
    sed -i -e "s|ignitionrobotics/ign-physics|diegoferigo/ign-physics|g" collection-$IGNITION_DISTRIBUTION.yaml &&\#
    sed -i -e "s|ign-physics4|fix/compute_joint_force_edifice|g" collection-$IGNITION_DISTRIBUTION.yaml &&\#
    vcs import < collection-$IGNITION_DISTRIBUTION.yaml &&\
    sed -i "s|if(OGRE_VERSION VERSION_LESS 1.10.3)|if(OGRE_VERSION VERSION_LESS 1.11.0)|g" ign-rendering/ogre/src/CMakeLists.txt &&\
    sed -i "s|if(OGRE_VERSION VERSION_LESS 1.10.1)|if(OGRE_VERSION VERSION_LESS 1.11.0)|g" ign-rendering/ogre/src/CMakeLists.txt &&\
    colcon graph &&\
    # Workaround for GL headers
    sed -i "s|#include <GL/glxext.h>|//#include <GL/glxext.h>|g" \
        $CONDA_PREFIX/x86_64-conda-linux-gnu/sysroot/usr/include/GL/glx.h &&\
    cd $SRC_DIR/workspace &&\
    colcon build \
        --merge-install \
        --cmake-args \
        -GNinja \
        -DBUILD_DOCS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        &&\
    find build/ -type f -not -name 'CMakeCache.txt' -delete &&\
    echo "[[ -f $SRC_DIR/workspace/install/setup.sh ]] && source $SRC_DIR/workspace/install/setup.sh" \
        >> /etc/bash.bashrc &&\
    find $SRC_DIR -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +

# Superbuild dependencies
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
        nlohmann_json \
        spdlog \
        irrlicht \
        #manif \#
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
        mesa-libgl-cos7-x86_64 \
    &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    conda clean -afy

# Superbuild
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
        -DROBOTOLOGY_USES_IGNITION:BOOL=OFF \
        -DROBOTOLOGY_USES_PYTHON:BOOL=ON \
        -DROBOTOLOGY_USES_OCTAVE:BOOL=OFF \
        -DROBOTOLOGY_USES_MATLAB:BOOL=OFF \
        -DNON_INTERACTIVE_BUILD:BOOL=ON \
        -DBUILD_TESTING:BOOL=OFF \
        -DYCM_DISABLE_SYSTEM_PACKAGES:BOOL=ON \
        -DROBOTOLOGY_PROJECT_TAGS=Stable \
        -Dbipedal-locomotion-framework_TAG=master \
        -Dmanif_REPOSITORY=artivis/manif \
        -Dmanif_TAG=devel \
        # casadi: lapack/mumps/osqp/qpoases
        # manif: python destination
        -DYCM_EP_ADDITIONAL_CMAKE_ARGS="-DWITH_LAPACK=ON -DWITH_MUMPS=ON -DWITH_OSQP=ON -DWITH_QPOASES=ON -DMANIFPY_INSTDIR=$SRC_DIR/robotology-superbuild/build/install/lib/python3.8/site-packages/manifpy" \
        .. &&\
    ninja &&\
    find src/ -type f -not -name 'CMakeCache.txt' -delete &&\
    echo "source $SRC_DIR/robotology-superbuild/build/install/share/robotology-superbuild/setup.sh" \
        >> /etc/bash.bashrc &&\
    ln -s $SRC_DIR/robotology-superbuild/src/YARP/scripts/yarp_completion /etc/bash_completion.d/yarp_completion &&\
    find $SRC_DIR -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +

# Application dependencies
ARG cudatoolkit_version="11.2.*"
RUN echo 'bazel < 4' >> $CONDA_PREFIX/conda-meta/pinned &&\
    mamba install -y \
        ipython \
        #tensorflow-gpu \#
        "cudatoolkit==$cudatoolkit_version" \
        pytorch-gpu \
        tensorboard \
        pytorch-lightning \
        pandas \
        scipy \
        numpy \
        gym \
        gin-config \
        gputil \
        gpustat \
        lxml \
        matplotlib \
        setuptools_scm \
        bazel \
        #ray-rllib ray-tune ray-dashboard \#
        &&\
    pip install \
        mashumaro \
        tables \
        cmake-build-extension \
        &&\
    # Install ray from pip
    mamba install -y \
        tensorboardx py-spy uvicorn fastapi starlette opencv pydantic atari_py kubernetes websocket-client h11 &&\
    pip install ray[all] \
        &&\
    pip install black isort build twine \
        &&\
    rm -rf $HOME/.cache/pip &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    conda clean -afy

# gym-ignition
RUN cd $SRC_DIR &&\
    git clone -b devel https://github.com/robotology/gym-ignition &&\
    cd gym-ignition &&\
    cmake -S . -B build/ \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
        &&\
    cmake --build build/ --target install &&\
    find build/ -type f -not -name 'CMakeCache.txt' -delete &&\
    pip install -e scenario/ &&\
    pip install -e . &&\
    rm -rf $HOME/.cache/pip &&\
    find $SRC_DIR -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} +

# Dotfiles
ENV DOTFILES_SHARE=/usr/local
RUN mamba install -y fish &&\
    git clone https://github.com/diegoferigo/dotfiles /usr/local/dotfiles &&\
    bash /usr/local/dotfiles/bootstrap &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    conda clean -afy

# Some QT-Apps/Gazebo don't show controls without this
ENV QT_X11_NO_MITSHM=1

# Devenv support
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        sudo \
        gosu \
        &&\
    rm -rf /var/lib/apt/lists/*
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
        # TODO
        #llvmdev \#
        clang-tools \
        ccache \
        #valgrind \#
        doxygen \
        graphviz \
        cppcheck \
        mkdocs \
        mkdocs-material \
        pygments \
        openssh \
        palettable \
        tikzplotlib \
        jq \
        &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends valgrind xterm &&\
    rm -rf /var/lib/apt/lists/* &&\
    pip install colour-valgrind &&\
    rm -rf $HOME/.cache/pip &&\
    find $CONDA_PREFIX -perm /u=w -and -not -perm /g=w -exec chmod g=u {} + &&\
    conda clean -afy

# Setup HW Acceleration for Intel graphic cards
#RUN apt-get update &&\
#    apt-get install -y \
#        libgl1-mesa-glx \
#        libgl1-mesa-dri &&\
#    rm -rf /var/lib/apt/lists/*

# QtCreator
ARG QTCREATOR_VERSION=5.0.0
COPY qtaccount.ini /root/.local/share/Qt/qtaccount.ini

RUN apt-get update &&\
    # Must find all libs during runtime
    # - ldd /tmp/qtcreator.run
    # - ldd /opt/qtcreator/bin/qtcreator
    # - ldd /opt/qtcreator/lib/Qt/plugins/platforms/libqxcb.so
    apt-get install -y --no-install-recommends \
        libgl1 libxcomposite1 libwayland-cursor0 libx11-xcb1 libxcb-glx0 libxkbcommon-x11-0 libxcb* &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /tmp &&\
    wget http://download.qt.io/official_releases/qtcreator/${QTCREATOR_VERSION%.*}/${QTCREATOR_VERSION}/qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run -O qtcreator.run &&\
    chmod +x qtcreator.run &&\
    # https://wiki.qt.io/Online_Installer_4.x
    ./qtcreator.run --accept-licenses --accept-messages --accept-obligations --confirm-command --root /opt/qtcreator install &&\
    rm /tmp/qtcreator.run &&\
    ln -s /opt/qtcreator/bin/qtcreator.sh /usr/bin/qtcreator

ARG PYCHARM_VERSION=2021.2
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        libxtst6 libxext6 libxrender1 libfreetype6 libfontconfig1 libgtk2.0-0 libxslt1.1 libxxf86vm1 \
        libnss3 libnspr4 libatk-bridge2.0-0 libgbm1 libasound2 libatspi2.0-0 &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /opt && mkdir pycharm && cd pycharm &&\
    curl -L https://download.jetbrains.com/python/pycharm-community-${PYCHARM_VERSION}.tar.gz -o /opt/pycharm/installer.tgz &&\
    tar --strip-components=1 -xzf installer.tgz &&\
    rm installer.tgz &&\
    python3 /opt/pycharm/plugins/python-ce/helpers/pydev/setup_cython.py build_ext --inplace &&\
    ln -s /opt/pycharm/bin/pycharm.sh /usr/local/bin/pycharm

# The autocompletion feature of QtCreator does not work with conda compilers.
# We set here the system's clang as default compiler, and enable ccache.
ARG CCACHE_DISABLE=1
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        clang clang-format &&\
    rm -rf /var/lib/apt/lists/* &&\
    echo 'CC="ccache /usr/bin/clang"' >> /etc/bash.bashrc &&\
    echo 'CXX="ccache /usr/bin/clang++"' >> /etc/bash.bashrc

# This is not working in the base environment:
# https://github.com/conda-forge/compilers-feedstock/issues/31
# conda env config vars set CC="ccache $(which clang)" CXX="ccache $(which clang++)"

USER root:root
