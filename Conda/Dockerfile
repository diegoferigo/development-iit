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
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' + &&\
    conda clean -afy

# Enable by default the conda environment for all users
RUN echo 'function activate_conda() {' >> /etc/bash.bashrc &&\
    echo '  eval "$(micromamba shell hook -s bash)"' >> /etc/bash.bashrc &&\
    echo '  micromamba activate $CONDA_PREFIX' >> /etc/bash.bashrc &&\
    echo '}' >> /etc/bash.bashrc &&\
    echo '[[ -z $NO_CONDA ]] && activate_conda' >> /etc/bash.bashrc

# Install buildchain
RUN echo 'sysroot_linux-64>=2.17' >> $CONDA_PREFIX/conda-meta/pinned &&\
    mamba install -y \
        compilers cmake make pkg-config ninja pybind11 git boa &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' + &&\
    conda clean -afy

# Packages installed later switch blas implementation to mkl, pinning it from the beginning here
RUN echo 'libblas=*=*mkl' >> $CONDA_PREFIX/conda-meta/pinned

# Default directory with sources
ARG SRC_DIR=/usr/local/src

# Install dartsim
RUN mamba install -y \
        eigen assimp libccd boost openscenegraph nlopt ipopt bullet libode octomap flann tinyxml2 \
        urdfdom xorg-libxi xorg-libxmu freeglut fcl &&\
    cd $SRC_DIR &&\
    git clone --depth=1 https://github.com/ignition-forks/dart &&\
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
    find $SRC_DIR -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' + &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' + &&\
    conda clean -afy

# Ignition Robotics dependencies
# TODO: ign-rendering doesn't find ogre-next
RUN echo 'protobuf 3.20.*' >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo 'ogre 1.10.*' >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo 'ogre-next 2.2.*' >> $CONDA_PREFIX/conda-meta/pinned &&\
    mamba install -y \
        vcstool colcon-common-extensions eigen freeimage gts glib ffmpeg \
        ruby tinyxml2 tinyxml protobuf urdfdom zeromq cppzmq libwebsockets \
        ogre ogre-next jsoncpp libzip qt \
        mesa-libgl-devel-cos7-x86_64 libx11-devel-cos7-x86_64 libglu &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' + &&\
    conda clean -afy

# Ignition Robotics
ARG IGNITION_DISTRIBUTION=fortress
COPY gui.yaml /usr/local/src/gui.yaml
RUN cd $SRC_DIR &&\
    mkdir -p workspace/src && cd workspace/src &&\
    wget -q https://raw.githubusercontent.com/ignition-tooling/gazebodistro/master/collection-$IGNITION_DISTRIBUTION.yaml &&\
    vcs import < /usr/local/src/gui.yaml &&\
    sed -i "s|if(OGRE_VERSION VERSION_LESS 1.10.3)|if(OGRE_VERSION VERSION_LESS 1.11.0)|g" ign-rendering/ogre/src/CMakeLists.txt &&\
    sed -i "s|if(OGRE_VERSION VERSION_LESS 1.10.1)|if(OGRE_VERSION VERSION_LESS 1.11.0)|g" ign-rendering/ogre/src/CMakeLists.txt &&\
    colcon graph &&\
    # Workaround for GL headers
    sed -i "s|#include <GL/glxext.h>|//#include <GL/glxext.h>|g" \
        $CONDA_PREFIX/x86_64-conda-linux-gnu/sysroot/usr/include/GL/glx.h &&\
    cd $SRC_DIR/workspace &&\
    colcon build \
        --merge-install \
        --packages-end ignition-gazebo6 \
        --cmake-args \
        -GNinja \
        -DBUILD_DOCS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        &&\
    find build/ -type f -not -name 'CMakeCache.txt' -delete &&\
    echo "[[ -f $SRC_DIR/workspace/install/setup.sh ]] && source $SRC_DIR/workspace/install/setup.sh" \
        >> /etc/bash.bashrc &&\
    find $SRC_DIR -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' +

# Superbuild dependencies
RUN mamba install -y \
        ace \
        asio \
        assimp \
        boost \
        eigen \
        #gazebo \#
        glew \
        glfw \
        gsl \
        ipopt \
        irrlicht \
        libjpeg-turbo \
        libmatio \
        libode \
        libxml2 \
        jsoncpp \
        nlohmann_json \
        opencv \
        pkg-config \
        portaudio \
        qt \
        sdl \
        sdl2 \
        sqlite \
        tinyxml \
        spdlog \
        #lua \#
        &&\
    mamba install -y \
        bash-completion \
        expat-cos7-x86_64 \
        freeglut \
        libdc1394 \
        libselinux-cos7-x86_64 \
        libxau-cos7-x86_64 \
        libxcb-cos7-x86_64 \
        libxdamage-cos7-x86_64 \
        libxext-cos7-x86_64 \
        libxfixes-cos7-x86_64 \
        libxxf86vm-cos7-x86_64 \
        mesa-libgl-cos7-x86_64 \
        libxshmfence-cos7-x86_64 \
        libxshmfence-devel-cos7-x86_64 \
        mesalib \
        &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' + &&\
    conda clean -afy

# Superbuild
RUN cd $SRC_DIR &&\
    mamba install -y casadi && conda clean -afy &&\
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
        -Dmanif_REPOSITORY=artivis/manif \
        -Dmanif_TAG=devel \
        # casadi: lapack/mumps/osqp/qpoases
        # manif: python destination
        -DYCM_EP_ADDITIONAL_CMAKE_ARGS="-DWITH_LAPACK=ON -DWITH_MUMPS=ON -DWITH_QPOASES=ON -DMANIFPY_INSTDIR=$SRC_DIR/robotology-superbuild/build/install/lib/python3.8/site-packages/manifpy" \
        .. &&\
    ninja &&\
    find src/ -type f -not -name 'CMakeCache.txt' -delete &&\
    echo "source $SRC_DIR/robotology-superbuild/build/install/share/robotology-superbuild/setup.sh" \
        >> /etc/bash.bashrc &&\
    ln -s $SRC_DIR/robotology-superbuild/src/YARP/scripts/yarp_completion /etc/bash_completion.d/yarp_completion &&\
    find $SRC_DIR -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' +

# Application dependencies
ARG cudatoolkit_version="11.2.*"
RUN echo "jax <0.3.16" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "jaxlib =*  =cuda112*" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "pytorch =*  =cuda112*" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "cudatoolkit $cudatoolkit_version" >> $CONDA_PREFIX/conda-meta/pinned &&\
    mamba install -y cudatoolkit cuda-nvcc -c conda-forge -c nvidia &&\
    mamba install -y \
        jax \
        pytorch \
        ipython \
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
        ray-all \
        black \
        isort \
        build \
        twine \
        mashumaro \
        pytables \
        cmake-build-extension \
        &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' + &&\
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

# Setup HW acceleration for GUIs
# https://conda-forge.org/docs/maintainer/knowledge_base.html#libgl
RUN apt-get update &&\
    apt-get install -y --no-install-recommends libgl1-mesa-glx libgl1-mesa-dri &&\
    rm -rf /var/lib/apt/lists/*

# Dotfiles
ENV DOTFILES_SHARE=/usr/local
RUN mamba install -y fish &&\
    git clone https://github.com/diegoferigo/dotfiles /usr/local/dotfiles &&\
    bash /usr/local/dotfiles/bootstrap &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' + &&\
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
USER root:root
COPY setup.sh /usr/sbin/setup_conda.sh
COPY entrypoint.sh /usr/sbin/entrypoint_conda.sh
RUN chmod 755 /usr/sbin/setup_conda.sh &&\
    chmod 755 /usr/sbin/entrypoint_conda.sh
ENTRYPOINT ["/usr/sbin/entrypoint_conda.sh"]
CMD ["bash"]

# ===========
# DEVELOPMENT
# ===========

USER root:runtimeusers

RUN mamba install -y \
        gdb \
        clang \
        clangdev \
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
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' + &&\
    conda clean -afy

# QtCreator
ARG QTCREATOR_VERSION=8.0.1
COPY qtaccount.ini /root/.local/share/Qt/qtaccount.ini

RUN apt-get update &&\
    # Must find all libs during runtime
    # - ldd /tmp/qtcreator.run
    # - ldd /opt/qtcreator/bin/qtcreator
    # - ldd /opt/qtcreator/lib/Qt/plugins/platforms/libqxcb.so
    apt-get install -y --no-install-recommends \
        libgl1 libxcomposite1 libwayland-cursor0 libx11-xcb1 libxcb-glx0 libxkbcommon-x11-0 freeglut3 freeglut3-dev libxcb* &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /tmp &&\
    wget http://download.qt.io/official_releases/qtcreator/${QTCREATOR_VERSION%.*}/${QTCREATOR_VERSION}/qt-creator-opensource-linux-x86_64-${QTCREATOR_VERSION}.run -O qtcreator.run &&\
    chmod +x qtcreator.run &&\
    # https://wiki.qt.io/Online_Installer_4.x
    ./qtcreator.run --accept-licenses --accept-messages --accept-obligations --confirm-command --root /opt/qtcreator install &&\
    rm /tmp/qtcreator.run &&\
    ln -s /opt/qtcreator/bin/qtcreator.sh /usr/bin/qtcreator

ARG PYCHARM_VERSION=2022.2.1
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
ENV CMAKE_CXX_COMPILER_LAUNCHER=ccache
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        clang clang-format &&\
    rm -rf /var/lib/apt/lists/*

# This is not working in the base environment:
# https://github.com/conda-forge/compilers-feedstock/issues/31
# conda env config vars set CC="ccache $(which clang)" CXX="ccache $(which clang++)"

USER root:root
