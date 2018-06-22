# Use latest as default tag. Build with e.g. --build-arg tag=xenial to override.
ARG tag=latest
FROM diegoferigo/tools:${tag}
MAINTAINER Diego Ferigo <dgferigo@gmail.com>

# Install ROS Desktop Full
# ========================

# Get gazebo from the osrf repo
ARG GAZEBO_VER=9
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" \
        > /etc/apt/sources.list.d/gazebo-stable.list &&\
    wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - &&\
    apt-get update &&\
    apt-get install --no-install-recommends -y \
        gazebo${GAZEBO_VER} \
        libgazebo${GAZEBO_VER}-dev \
        &&\
    rm -rf /var/lib/apt/lists/*

# https://github.com/osrf/docker_images/blob/master/ros/
ENV ROS_DISTRO melodic
# tzdata configuration
RUN ln -s /usr/share/zoneinfo/Europe/Rome /etc/localtime
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net \
                --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116 &&\
    echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -cs` main" \
        > /etc/apt/sources.list.d/ros-latest.list
RUN apt-get update &&\
    apt-get install --no-install-recommends -y \
        python-rosdep \
        python-rosinstall \
        python-vcstools \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    rosdep init &&\
    rosdep update
RUN apt-get update &&\
    apt-get install -y \
        ros-${ROS_DISTRO}-desktop \
        # ros-${ROS_DISTRO}-desktop-full \
        #ros-${ROS_DISTRO}-fake-localization \
        #ros-${ROS_DISTRO}-map-server \
        &&\
    rm -rf /var/lib/apt/lists/*

# Install libraries and tools
# ===========================

RUN apt-get update &&\
    apt-get install -y \
        # MISC
        qt5-default \
        # YARP
        libeigen3-dev \
        libgsl-dev \
        libedit-dev \
        libqcustomplot-dev \
        qtmultimedia5-dev \
        qtdeclarative5-dev \
        libqt5opengl5-dev \
        qttools5-dev \
        # GAZEBO-YARP-PLUGINS
        libatlas-base-dev \
        # IDYNTREE
        coinor-libipopt-dev \
        # BINDINGS
        liboctave-dev \
        # SIMMECHANICS-TO-URDF
        python-lxml \
        python-yaml \
        python-numpy \
        python-setuptools \
        # MISC
        libasio-dev \
        &&\
    rm -rf /var/lib/apt/lists/*

# Install YARP, iCub and friends from sources
# ===========================================

# Environment setup of the robotology repositories
# ------------------------------------------------

ENV IIT_DIR=/iit
ENV IIT_INSTALL=${IIT_DIR}/local
ENV IIT_SOURCES=${IIT_DIR}/sources
ARG IIT_BIN=${IIT_INSTALL}/bin
ENV IIT_PATH=${IIT_PATH:+${IIT_PATH}:}${IIT_BIN}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${IIT_INSTALL}/lib/
ENV PATH=${IIT_PATH}:${PATH}

# Download all sources with git
# -----------------------------

RUN mkdir -p ${IIT_SOURCES} ${IIT_BIN}

# Use docker cache for steps above
ARG IIT_DOCKER_SOURCES="20180622"

RUN cd ${IIT_SOURCES} &&\
    git clone https://github.com/robotology/ycm.git &&\
    git clone https://github.com/robotology/yarp.git &&\
    git clone https://github.com/robotology/icub-main.git &&\
    git clone https://github.com/robotology/icub-contrib-common.git &&\
    git clone https://github.com/robotology/robot-testing.git &&\
    git clone https://github.com/robotology/gazebo-yarp-plugins.git &&\
    git clone https://github.com/robotology-playground/yarp-matlab-bindings.git &&\
    git clone https://github.com/robotology/idyntree.git &&\
    git clone https://github.com/ros/urdf_parser_py &&\
    git clone https://github.com/robotology/simmechanics-to-urdf.git &&\
    git clone https://github.com/robotology-playground/icub-model-generator.git &&\
    git clone https://github.com/diegoferigo/robotology-superbuild.git &&\
    git clone https://github.com/robotology-playground/xsens-mvn.git &&\
    git clone https://github.com/robotology/human-dynamics-estimation.git &&\
    git clone https://github.com/bulletphysics/bullet3.git

# Env variables for configuring the sources
# -----------------------------------------

# Build Variables
ARG SOURCES_GIT_BRANCH=master
ENV SOURCES_BUILD_TYPE=Debug

# CMake Generator
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_EXTRA_OPTIONS=
# ENV CMAKE_GENERATOR="Unix Makefiles"
# ENV CMAKE_EXTRA_OPTIONS="-j 6"

# Select the main development robot (model loading)
ENV ROBOT_NAME="iCubGazeboV2_5"
ENV YARP_ROBOT_NAME="iCubGazeboV2_5"

# Configure the MEX provider
# For the time being, ROBOTOLOGY_USES_MATLAB=ON is not supported.
# Refer to https://github.com/diegoferigo/dockerfiles/issues/8
ENV ROBOTOLOGY_USES_OCTAVE=ON
ENV ROBOTOLOGY_USES_MATLAB=OFF
ENV ROBOTOLOGY_GENERATE_MEX=ON
# The default is "mex" but "matlab" should become the default
ENV ROBOTOLOGY_MATLAB_MEX_DIR="matlab"

# Build all sources
# -----------------

# YCM
RUN cd ${IIT_SOURCES}/ycm &&\
    git checkout ${SOURCES_GIT_BRANCH} &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS

# RTF
RUN cd ${IIT_SOURCES}/robot-testing &&\
    git checkout ${SOURCES_GIT_BRANCH} &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${IIT_INSTALL}/lib/rtf

# YARP
RUN \
    cd ${IIT_SOURCES}/yarp &&\
    git checkout ${SOURCES_GIT_BRANCH} &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          -DCREATE_GUIS=ON \
          -DCREATE_LIB_MATH=ON \
          -DSKIP_ACE=ON \
          -DYARP_COMPILE_RTF_ADDONS=ON \
          -DCREATE_OPTIONAL_CARRIERS:BOOL=ON \
          -DENABLE_yarpcar_rossrv:BOOL=ON \
          -DENABLE_yarpcar_tcpros:BOOL=ON \
          -DENABLE_yarpcar_xmlrpc:BOOL=ON \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS &&\
    ln -s ${IIT_SOURCES}/yarp/scripts/yarp_completion \
          /etc/bash_completion.d/yarp_completion
ENV YARP_DIR=${IIT_INSTALL}
ENV YARP_DATA_DIRS=${IIT_INSTALL}/share/yarp
ENV YARP_COLORED_OUTPUT=1
RUN yarp check
EXPOSE 10000/tcp

# ICUB-MAIN
RUN cd ${IIT_SOURCES}/icub-main &&\
    # git checkout ${SOURCES_GIT_BRANCH} &&\
    git checkout devel &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          -DENABLE_icubmod_cartesiancontrollerserver=ON \
          -DENABLE_icubmod_cartesiancontrollerclient=ON \
          -DENABLE_icubmod_gazecontrollerclient=ON \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS
ENV YARP_DATA_DIRS=${YARP_DATA_DIRS:+${YARP_DATA_DIRS}:}${IIT_INSTALL}/share/iCub

# ICUB-CONTRIB-COMMON
RUN cd ${IIT_SOURCES}/icub-contrib-common &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS
ENV YARP_DATA_DIRS=${YARP_DATA_DIRS:+${YARP_DATA_DIRS}:}${IIT_INSTALL}/share/ICUBcontrib

# GAZEBO-YARP-PLUGINS
RUN cd ${IIT_SOURCES}/gazebo-yarp-plugins &&\
    # git checkout ${SOURCES_GIT_BRANCH} &&\
    git checkout devel &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS
ENV YARP_DATA_DIRS=${YARP_DATA_DIRS:+${YARP_DATA_DIRS}:}${IIT_INSTALL}/share/ICUBcontrib
ENV GAZEBO_PLUGIN_PATH=${GAZEBO_PLUGIN_PATH:+${GAZEBO_PLUGIN_PATH}:}${IIT_INSTALL}/lib

# YARP-MATLAB-BINDINGS
RUN cd ${IIT_SOURCES}/yarp-matlab-bindings &&\
    # git checkout ${SOURCES_GIT_BRANCH} &&\
    git checkout devel &&\
    # Waiting https://github.com/robotology-playground/yarp-matlab-bindings/issues/18
    rm matlab/autogenerated/yarpMATLAB_wrap.cxx &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          -DYARP_SOURCE_DIR=${IIT_SOURCES}/yarp \
          -DYARP_USES_OCTAVE:BOOL=${ROBOTOLOGY_USES_OCTAVE} \
          -DYARP_USES_MATLAB:BOOL=${ROBOTOLOGY_USES_MATLAB} \
          -DYARP_GENERATE_MATLAB:BOOL=${ROBOTOLOGY_GENERATE_MEX} \
          -DYARP_INSTALL_MATLAB_LIBDIR=${ROBOTOLOGY_MATLAB_MEX_DIR} \
          -DYARP_INSTALL_MATLAB_MFILESDIR=${ROBOTOLOGY_MATLAB_MEX_DIR} \
          -DYCM_USE_DEPRECATED:BOOL=OFF \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS

# IDYNTREE
RUN cd ${IIT_SOURCES}/idyntree &&\
    git checkout ${SOURCES_GIT_BRANCH} &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          -DIDYNTREE_USES_OCTAVE:BOOL=${ROBOTOLOGY_USES_OCTAVE} \
          -DIDYNTREE_USES_MATLAB:BOOL=${ROBOTOLOGY_USES_MATLAB} \
          -DIDYNTREE_GENERATE_MATLAB:BOOL=${ROBOTOLOGY_GENERATE_MEX} \
          -DIDYNTREE_INSTALL_MATLAB_LIBDIR=${ROBOTOLOGY_MATLAB_MEX_DIR} \
          -DIDYNTREE_INSTALL_MATLAB_MFILESDIR=${ROBOTOLOGY_MATLAB_MEX_DIR} \
          -DIDYNTREE_USES_KDL:BOOL=OFF \
          -DYCM_USE_DEPRECATED=OFF \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS

# ICUB-GAZEBO-WHOLEBODY
RUN cd ${IIT_SOURCES} &&\
    git clone https://github.com/robotology-playground/icub-gazebo-wholebody.git &&\
    cd ${IIT_SOURCES}/icub-gazebo-wholebody &&\
    git checkout feature/useGeneratedModels &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          -DROBOT_NAME=${ROBOT_NAME} \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS
ENV GAZEBO_MODEL_PATH=${GAZEBO_MODEL_PATH:+${GAZEBO_MODEL_PATH}:}${IIT_INSTALL}/share/gazebo/models/
ENV GAZEBO_RESOURCE_PATH=${GAZEBO_MODEL_PATH:+${GAZEBO_MODEL_PATH}:}${IIT_INSTALL}/share/gazebo/worlds

# ICUB-MODELS
RUN cd ${IIT_SOURCES} &&\
    git clone https://github.com/robotology-playground/icub-models &&\
    cd ${IIT_SOURCES}/icub-models &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS
ENV YARP_DATA_DIRS=${YARP_DATA_DIRS:+${YARP_DATA_DIRS}:}${IIT_INSTALL}/share/iCub
ENV GAZEBO_MODEL_PATH=${GAZEBO_MODEL_PATH:+${GAZEBO_MODEL_PATH}:}${IIT_INSTALL}/share/iCub/robots:${IIT_INSTALL}/share
ENV ROS_PACKAGE_PATH=${ROS_PACKAGE_PATH:+${ROS_PACKAGE_PATH}:}${IIT_INSTALL}/share

# SIMMECHANICS-TO-URDF
# ENV ROS_DISTRO melodic
# RUN apt-key adv --keyserver ha.pool.sks-keyservers.net \
#                 --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116 &&\
#     echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -cs` main" \
#         > /etc/apt/sources.list.d/ros-latest.list &&\
#     apt-get update &&\
#     apt-get install --no-install-recommends -y \
#         python-catkin-pkg \
#         &&\
#     rm -rf /var/lib/apt/lists/*
RUN \
    # Dependencies
    cd ${IIT_SOURCES}/urdf_parser_py &&\
    python setup.py install &&\
    # Project
    cd ${IIT_SOURCES}/simmechanics-to-urdf &&\
    python setup.py install

# ICUB-MODEL-GENERATOR
RUN cd ${IIT_SOURCES}/icub-model-generator &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          -DICUB_MODEL_GENERATE_DH:BOOL=OFF \
          -DICUB_MODEL_GENERATE_SIMMECHANICS:BOOL=ON \
          -DICUB_MODELS_SOURCE_DIR=${IIT_SOURCES}/icub-models \
          .. &&\
    cmake --build . -- $CMAKE_EXTRA_OPTIONS

# ROBOTOLOGY-SUPERBUILD
# The bashrc-dev will source the variables exported by this repo
RUN cd ${IIT_SOURCES}/robotology-superbuild &&\
    mkdir -p build && cd build &&\
    cmake \
          -G "Unix Makefiles" \
          -DROBOTOLOGY_ENABLE_CORE:BOOL=ON \
          -DROBOTOLOGY_ENABLE_DYNAMICS:BOOL=ON \
          -DROBOTOLOGY_USES_GAZEBO:BOOL=ON \
          -DROBOTOLOGY_USES_OCTAVE:BOOL=${ROBOTOLOGY_USES_OCTAVE} \
          -DROBOTOLOGY_USES_MATLAB:BOOL=${ROBOTOLOGY_USES_MATLAB} \
          -DNON_INTERACTIVE_BUILD:BOOL=ON \
          -DYCM_USE_DEPRECATED:BOOL=OFF \
          -DYCM_EP_EXPERT_MODE:BOOL=ON \
          -DYCM_EP_MAINTAINER_MODE:BOOL=ON \
          .. &&\
    make update-all -j1 &&\
    # NON_INTERACTIVE_BUILD and YCM_EP_DEVEL_MODE don't play well toghether
    # Setting a temporary git configuration
    git config --global user.email "username@iit.it" &&\
    git config --global user.name "Me" &&\
    for repo in yarp-matlab-bindings codyco-modules ; do \
        cmake -DYCM_EP_DEVEL_MODE_${repo}:BOOL=ON . &&\
        cd ../robotology/$repo ;\
        echo "Checking out $repo to ${BRANCH}" ;\
        git checkout devel ;\
        cd ../../build ;\
    done &&\
    make -j4 &&\
    rm $HOME/.gitconfig

# xsens-mvn
RUN cd ${IIT_SOURCES}/xsens-mvn &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          -DENABLE_mvnx_parser:BOOL=NO \
          -DENABLE_xsens_mnv_remote:BOOL=ON \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS

# human-dynamics-estimation
RUN cd ${IIT_SOURCES}/human-dynamics-estimation &&\
    mkdir -p build && cd build &&\
    cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS

# Bullet
RUN cd ${IIT_SOURCES}/bullet3 &&\
    mkdir -p build && cd build &&\
    cmake \
    -G $CMAKE_GENERATOR \
    -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
    -DBUILD_SHARED_LIBS=ON \
    .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS

# Misc setup of the image
# =======================

# Some QT-Apps/Gazebo don't show controls without this
ENV QT_X11_NO_MITSHM 1

# Include a custom bashrc
COPY bashrc /usr/etc/skel/bashrc-dev
COPY bashrc-colors /usr/etc/skel/bashrc-colors
COPY bashrc-functions /usr/etc/skel/bashrc-functions

# Include an additional entrypoint script
COPY entrypoint.sh /usr/sbin/entrypoint_development.sh
RUN chmod 755 /usr/sbin/entrypoint_development.sh
COPY setup.sh /usr/sbin/setup_development.sh
RUN chmod 755 /usr/sbin/setup_development.sh
ENTRYPOINT ["/usr/sbin/entrypoint_development.sh"]
