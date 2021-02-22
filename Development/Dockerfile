ARG from=diegoferigo/tools:latest
FROM ${from}

# ========================
# Install ROS Desktop Full
# ========================

# Get gazebo from the osrf repo
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" \
        > /etc/apt/sources.list.d/gazebo-stable.list &&\
    wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - &&\
    apt-get update &&\
    apt-get install --no-install-recommends -y \
        gazebo11 \
        libgazebo11-dev \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    echo "[[ -f /usr/share/gazebo/setup.sh ]] && source /usr/share/gazebo/setup.sh" >> /etc/bash.bashrc

# https://github.com/osrf/docker_images/blob/master/ros/
ENV ROS_DISTRO noetic

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
                --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 &&\
    echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -cs` main" \
        > /etc/apt/sources.list.d/ros-latest.list &&\
    apt-get update &&\
    apt-get install --no-install-recommends -y \
        python3-rosdep \
        python3-rosinstall-generator \
        python3-vcstools \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    rosdep init &&\
    rosdep update &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-desktop-full \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    echo 'if [[ -f /opt/ros/$ROS_DISTRO/setup.bash ]] ; then' >>/etc/bash.bashrc &&\
    echo '    old_path=$ROS_PACKAGE_PATH' >>/etc/bash.bashrc &&\
    echo '    source /opt/ros/$ROS_DISTRO/setup.bash' >>/etc/bash.bashrc &&\
    echo '    [[ -n ${old_path} ]] && export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$old_path' >>/etc/bash.bashrc &&\
    echo '    unset old_path' >>/etc/bash.bashrc &&\
    echo 'fi' >>/etc/bash.bashrc

# ===========================
# Install libraries and tools
# ===========================

# RUN mamba install -y -c conda-forge cmake compilers make ninja pkg-config &&\
#     rm -rf ${CONDA_PREFIX}/.micromamba/pkgs/cache 
    #&&\
    # find ${CONDA_PREFIX} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+
# RUN mamba install -y -c conda-forge \
#         ace \
#         asio \
#         boost \
#         eigen \
#         gazebo \
#         glew \
#         glfw \
#         gsl \
#         ipopt \
#         libjpeg-turbo \
#         libmatio \
#         libode \
#         libxml2 \
#         opencv \
#         pkg-config \
#         portaudio \
#         qt \
#         sdl \
#         sdl2 \
#         sqlite \
#         tinyxml &&\
#     rm -rf ${CONDA_PREFIX}/.micromamba/pkgs/cache 
    #&&\
    #find ${CONDA_PREFIX} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# RUN mamba install -y -c conda-forge \
#         expat-cos6-x86_64 \
#         freeglut \
#         libselinux-cos6-x86_64 \
#         libxau-cos6-x86_64 \
#         libxcb-cos6-x86_64 \
#         libxdamage-cos6-x86_64 \
#         libxext-cos6-x86_64 \
#         libxfixes-cos6-x86_64 \
#         libxxf86vm-cos6-x86_64 \
#         mesalib \
#         mesa-libgl-cos6-x86_64 &&\
#     rm -rf ${CONDA_PREFIX}/.micromamba/pkgs/cache 
    #&&\
    #find ${CONDA_PREFIX} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# RUN cd /tmp &&\
#     git clone https://github.com/artivis/manif.git &&\
#     mkdir -p manif/build && cd manif/build &&\
#     cmake -GNinja .. &&\
#     ninja install &&\
#     rm -rf /tmp/manif
#     
# RUN cd /tmp &&\
#     git clone https://github.com/coin-or/CppAD.git &&\
#     mkdir -p CppAD/build && cd CppAD/build &&\
#     cmake -GNinja -DCMAKE_BUILD_TYPE=Release .. &&\
#     ninja install &&\
#     rm -rf /tmp/CppAD
#     
# RUN mamba install -y -c conda-forge \
#         casadi \
#         catch2 \
#         qhull \
#     &&\
#     rm -rf /tmp/CppAD
# RUN false

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        # SUPERBUILD
        libeigen3-dev \
        coinor-libipopt-dev \
        libboost-system-dev \
        libboost-filesystem-dev \
        libboost-thread-dev \
        libirrlicht-dev \
        libtinyxml-dev \
        libedit-dev \
        libace-dev \
        libgsl0-dev \
        libopencv-dev \
        libode-dev \
        liblua5.1-dev \
        lua5.1 \
        qtbase5-dev \
        qtdeclarative5-dev \
        qtmultimedia5-dev \
        qml-module-qtquick2 \
        qml-module-qtquick-window2 \
        qml-module-qtmultimedia \
        qml-module-qtquick-dialogs \
        qml-module-qtquick-controls \
        qml-module-qt-labs-folderlistmodel \
        qml-module-qt-labs-settings \
        libsdl1.2-dev \
        libxml2-dev \
        libv4l-dev \
        # SIMMECHANICS-TO-URDF
        python-lxml \
        python-yaml \
        python-numpy \
        python-setuptools \
        # BLOCKFACTORY
        libmatio-dev \
        # MISC
        liboctave-dev \
        libqt5opengl5-dev \
        libasio-dev &&\
    rm -rf /var/lib/apt/lists/*

# ===========================================
# Install YARP, iCub and friends from sources
# ===========================================

# Environment setup of the robotology repositories
# ------------------------------------------------

ENV IIT_DIR=/iit
ENV IIT_INSTALL=${IIT_DIR}/local
ENV IIT_SOURCES=${IIT_DIR}/sources
ARG IIT_BIN=${IIT_INSTALL}/bin

# Download all sources with git
# -----------------------------

# Use docker cache for steps above
ARG IIT_DOCKER_SOURCES="20210102"

RUN mkdir -p ${IIT_SOURCES} &&\
    cd ${IIT_SOURCES} &&\
    git clone -b v2.13.3 https://github.com/catchorg/Catch2.git &&\
    git clone https://github.com/ros/urdf_parser_py &&\
    git clone https://github.com/robotology/simmechanics-to-urdf.git &&\
    git clone https://github.com/robotology-playground/icub-model-generator.git &&\
    git clone https://github.com/robotology/robotology-superbuild.git &&\
    chgrp -R runtimeusers ${IIT_DIR} && chmod -R g+rw ${IIT_DIR}

# Env variables for configuring the sources
# -----------------------------------------

ENV CMAKE_GENERATOR=Ninja
ENV SOURCES_BUILD_TYPE=RelWithDebInfo

# Select the main development robot (model loading)
ENV YARP_ROBOT_NAME="iCubGazeboV2_5"

# Configure the MEX provider
# For the time being, ROBOTOLOGY_USES_MATLAB=ON is not supported.
# Refer to https://github.com/diegoferigo/dockerfiles/issues/8
ENV ROBOTOLOGY_USES_OCTAVE=ON
ENV ROBOTOLOGY_USES_MATLAB=OFF
# ENV ROBOTOLOGY_GENERATE_MEX=ON

# Build all sources
# -----------------

# ROBOTOLOGY-SUPERBUILD
EXPOSE 10000/tcp
ENV YARP_COLORED_OUTPUT=1
ARG ROBOTOLOGY_PROJECT_TAGS=Stable
RUN cd ${IIT_SOURCES}/robotology-superbuild &&\
    mkdir -p build && cd build &&\
    export CC=gcc && export CXX=g++ &&\
    cmake \
          -GNinja \
          -DROBOTOLOGY_ENABLE_CORE:BOOL=ON \
          -DROBOTOLOGY_ENABLE_DYNAMICS:BOOL=ON \
          -DROBOTOLOGY_ENABLE_DYNAMICS_FULL_DEPS:BOOL=ON \
          -DROBOTOLOGY_ENABLE_ROBOT_TESTING:BOOL=ON \
          -DROBOTOLOGY_ENABLE_HUMAN_DYNAMICS:BOOL=ON \
          -DROBOTOLOGY_USES_GAZEBO:BOOL=ON \
          -DROBOTOLOGY_USES_OCTAVE:BOOL=${ROBOTOLOGY_USES_OCTAVE} \
          -DROBOTOLOGY_USES_MATLAB:BOOL=${ROBOTOLOGY_USES_MATLAB} \
          -DNON_INTERACTIVE_BUILD:BOOL=ON \
          -DBUILD_TESTING:BOOL=OFF \
          -DYCM_DISABLE_SYSTEM_PACKAGES:BOOL=ON \
          -DROBOTOLOGY_PROJECT_TAGS=${ROBOTOLOGY_PROJECT_TAGS} \
          .. &&\
    ninja &&\
    ln -s ${IIT_SOURCES}/robotology-superbuild/build/install ${IIT_INSTALL} &&\
    echo "source ${IIT_INSTALL}/share/robotology-superbuild/setup.sh" >> /etc/bash.bashrc &&\
    ln -s ${IIT_SOURCES}/robotology-superbuild/src/YARP/scripts/yarp_completion /etc/bash_completion.d/yarp_completion &&\
    find src/ -type f -not -name 'CMakeCache.txt' -delete &&\
    find ${IIT_SOURCES}/robotology-superbuild -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# CATCH2
RUN cd ${IIT_SOURCES}/Catch2 &&\
    mkdir -p build && cd build &&\
    cmake -GNinja -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF -DCATCH_BUILD_TESTING:BOOL=OFF -DCATCH_INSTALL_DOCS:BOOL=OFF .. &&\
    ninja install &&\
    find . -type f -not -name 'CMakeCache.txt' -delete &&\
    find ${IIT_SOURCES} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${IIT_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# SIMMECHANICS-TO-URDF
RUN cd ${IIT_SOURCES}/urdf_parser_py &&\
    # https://github.com/robotology/icub-model-generator/blob/master/.travis.yml#L56
    git checkout 31474b9baaf7c3845b40e5a9aa87d5900a2282c3 &&\
    python3 setup.py install &&\
    # Project
    cd ${IIT_SOURCES}/simmechanics-to-urdf &&\
    python3 setup.py install &&\
    find ${IIT_SOURCES}/urdf_parser_py -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${IIT_SOURCES}/simmechanics-to-urdf -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${IIT_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ICUB-MODEL-GENERATOR
RUN cd ${IIT_SOURCES}/icub-model-generator &&\
    mkdir -p build && cd build &&\
    CMAKE_PREFIX_PATH=${IIT_INSTALL} cmake \
          -GNinja \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          -DICUB_MODEL_GENERATE_DH:BOOL=OFF \
          -DICUB_MODEL_GENERATE_SIMMECHANICS:BOOL=ON \
          -DICUB_MODELS_SOURCE_DIR=${IIT_SOURCES}/icub-models \
          .. &&\
    ninja &&\
    find . -type f -not -name 'CMakeCache.txt' -delete &&\
    find ${IIT_SOURCES}/icub-model-generator -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${IIT_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# Misc setup of the image
# =======================

# Include an additional entrypoint script
COPY entrypoint.sh /usr/sbin/entrypoint_development.sh
COPY setup.sh /usr/sbin/setup_development.sh
RUN chmod 755 /usr/sbin/entrypoint_development.sh &&\
    chmod 755 /usr/sbin/setup_development.sh
ENTRYPOINT ["/usr/sbin/entrypoint_development.sh"]
CMD ["bash"]
