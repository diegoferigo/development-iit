ARG from=diegoferigo/tools:latest
FROM ${from}

# Build-time metadata as defined at http://label-schema.org
# ARG BUILD_DATE
# ARG VCS_REF
# ARG VERSION=0.9
LABEL \
    maintainer="Diego Ferigo <dgferigo@gmail.com>" \
    # org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="development-cpp" \
    org.label-schema.description="" \
    org.label-schema.url="https://github.com/diegoferigo/development-iit" \
    # org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/diegoferigo/development-iit" \
    # org.label-schema.vendor="" \
    # org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0"

# Install ROS Desktop Full
# ========================

# Get gazebo from the osrf repo
ARG GAZEBO_VER=10
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

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
                --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 &&\
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
    apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-desktop \
        # ros-${ROS_DISTRO}-desktop-full \
        #ros-${ROS_DISTRO}-fake-localization \
        #ros-${ROS_DISTRO}-map-server \
        &&\
    rm -rf /var/lib/apt/lists/*

# Install libraries and tools
# ===========================

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        # SUPERBUILD
        libeigen3-dev \
        coinor-libipopt-dev \
        libboost-system-dev \
        libboost-filesystem-dev \
        libboost-thread-dev \
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
ARG IIT_DOCKER_SOURCES="20200123"

RUN mkdir -p ${IIT_SOURCES} &&\
    cd ${IIT_SOURCES} &&\
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
RUN cd ${IIT_SOURCES}/robotology-superbuild &&\
    mkdir -p build && cd build &&\
    YARP_ROBOT_NAME= \
    cmake \
          -G $CMAKE_GENERATOR \
          -DROBOTOLOGY_ENABLE_CORE:BOOL=ON \
          -DROBOTOLOGY_ENABLE_DYNAMICS:BOOL=ON \
          -DROBOTOLOGY_ENABLE_ROBOT_TESTING:BOOL=ON \
          -DROBOTOLOGY_ENABLE_HUMAN_DYNAMICS:BOOL=ON \
          -DROBOTOLOGY_USES_GAZEBO:BOOL=ON \
          -DROBOTOLOGY_USES_PYTHON:BOOL=ON \
          -DROBOTOLOGY_USES_OCTAVE:BOOL=${ROBOTOLOGY_USES_OCTAVE} \
          -DROBOTOLOGY_USES_MATLAB:BOOL=${ROBOTOLOGY_USES_MATLAB} \
          -DNON_INTERACTIVE_BUILD:BOOL=ON \
          .. &&\
    cmake --build . -- $CMAKE_EXTRA_OPTIONS &&\
    ln -s ${IIT_SOURCES}/robotology-superbuild/build/install ${IIT_INSTALL} &&\
    echo "source ${IIT_INSTALL}/share/robotology-superbuild/setup.sh" >> /etc/bash.bashrc &&\
    ln -s ${IIT_SOURCES}/robotology-superbuild/robotology/YARP/scripts/yarp_completion /etc/bash_completion.d/yarp_completion &&\
    find ${IIT_SOURCES}/robotology-superbuild -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

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
    python setup.py install &&\
    find ${IIT_SOURCES}/urdf_parser_py -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${IIT_SOURCES}/simmechanics-to-urdf -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${IIT_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# ICUB-MODEL-GENERATOR
RUN cd ${IIT_SOURCES}/icub-model-generator &&\
    mkdir -p build && cd build &&\
    CMAKE_PREFIX_PATH=${IIT_INSTALL} cmake \
          -G $CMAKE_GENERATOR \
          -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
          -DCMAKE_INSTALL_PREFIX=${IIT_INSTALL} \
          -DICUB_MODEL_GENERATE_DH:BOOL=OFF \
          -DICUB_MODEL_GENERATE_SIMMECHANICS:BOOL=ON \
          -DICUB_MODELS_SOURCE_DIR=${IIT_SOURCES}/icub-models \
          .. &&\
    cmake --build . -- $CMAKE_EXTRA_OPTIONS &&\
    find ${IIT_SOURCES}/icub-model-generator -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${IIT_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# Misc setup of the image
# =======================

# Include a custom bashrc
COPY bashrc /usr/etc/skel/bashrc-dev
COPY bashrc-colors /usr/etc/skel/bashrc-colors
COPY bashrc-functions /usr/etc/skel/bashrc-functions

# Include an additional entrypoint script
COPY entrypoint.sh /usr/sbin/entrypoint_development.sh
COPY setup.sh /usr/sbin/setup_development.sh
RUN chmod 755 /usr/sbin/entrypoint_development.sh
RUN chmod 755 /usr/sbin/setup_development.sh
ENTRYPOINT ["/usr/sbin/entrypoint_development.sh"]
CMD ["bash"]
