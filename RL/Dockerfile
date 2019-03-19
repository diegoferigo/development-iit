ARG from=diegoferigo/development:nvidia-master
FROM ${from}

# Build-time metadata as defined at http://label-schema.org
# ARG BUILD_DATE
# ARG VCS_REF
# ARG VERSION=0.9
LABEL \
    maintainer="Diego Ferigo <dgferigo@gmail.com>" \
    # org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="rl" \
    org.label-schema.description="" \
    org.label-schema.url="https://github.com/diegoferigo/development-iit" \
    # org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/diegoferigo/development-iit" \
    # org.label-schema.vendor="" \
    # org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0"

ENV RL_DIR=/rl
ENV RL_INSTALL=${RL_DIR}/local
ENV RL_SOURCES=${RL_DIR}/sources
ENV DEVENV_PATH=${RL_INSTALL}/bin:${DEVENV_PATH}
ENV CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}:${RL_INSTALL}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${RL_INSTALL}/lib

# =======================================
# Install ignition libraries from sources
# =======================================

# http://gazebosim.org/tutorials?tut=install_dependencies_from_source

# Remove gazebo9 if present
RUN apt-get remove -y '.*sdformat.*' '.*ignition-.*' || true

ENV CC="gcc-8"
ENV CXX="g++-8"

# Common tools and libraries
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        git \
        cmake \
        cmake-curses-gui \
        g++-8 \
        wget \
        ninja-build \
        mercurial \
        ca-certificates \
        apt-utils \
        locales \
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
        # ign-fuel-tools
        libjsoncpp-dev \
        libzip-dev \
        libyaml-dev \
        libcurl4-openssl-dev \
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

# Setup locales and tzdata
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen &&\
    locale-gen &&\
    update-locale LANG="en_US.UTF-8" &&\
    export DEBIAN_FRONTEND=noninteractive &&\
    export DEBCONF_NONINTERACTIVE_SEEN=true &&\
    rm -rf /etc/localtime &&\
    rm -rf /etc/timezone &&\
    echo 'tzdata tzdata/Areas select Europe' | debconf-set-selections &&\
    echo 'tzdata tzdata/Zones/Europe select Rome' | debconf-set-selections &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends tzdata &&\
    rm -rf /var/lib/apt/lists/*

# Add gazebo ppa and install other deps
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list &&\
    wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add - &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends \
        libogre-2.1-dev \
        &&\
    rm -rf /var/lib/apt/lists/*
        
RUN wget https://raw.github.com/mnauw/git-remote-hg/master/git-remote-hg -O /usr/local/bin/git-remote-hg &&\
    chmod +x /usr/local/bin/git-remote-hg

# Create a new runtimeusers group (it might be already present)
RUN groupadd runtimeusers || true

# Download all the sources
ARG RL_SOURCES="20190318"
RUN mkdir -p ${RL_SOURCES} &&\
    cd ${RL_SOURCES} &&\
    mkdir -p ${RL_SOURCES} &&\
    git config --global remote-hg.ignore-name "~|pre|pendulum" &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-cmake -b branches/gz11 && cd ign-cmake && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-math && cd ign-math && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-common -b branches/gz11 && cd ign-common && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-tools && cd ign-tools && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-fuel-tools && cd ign-fuel-tools && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/osrf/sdformat -b branches/sdf8 && cd sdformat && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-msgs -b branches/ign-msgs3 && cd ign-msgs && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-transport && cd ign-transport && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-plugin && cd ign-plugin && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-physics && cd ign-physics && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-rendering -b branches/ign-rendering1 && cd ign-rendering && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-sensors -b branches/ign-sensors1 && cd ign-sensors && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-gui && cd ign-gui && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-gazebo -b branches/ign-gazebo1 && cd ign-gazebo && git gc --aggressive && cd - &&\
    git clone hg::https://bitbucket.org/ignitionrobotics/ign-launch && cd ign-launch && git gc --aggressive && cd - &&\
    # git clone hg::https://bitbucket.org/ignitionrobotics/ign-plugins && cd ign-plugins && git gc --aggressive && cd - &&\
    git clone --depth 1 https://github.com/bulletphysics/bullet3.git &&\
    git clone --depth 1 -b v6.7.2 https://github.com/dartsim/dart.git &&\
    git clone https://github.com/robotology/icub-gazebo &&\
    chgrp -R runtimeusers ${RL_DIR} && chmod -R g+rw ${RL_DIR}

# TODO: There are problems with ignition and ninja.
#       Also bullet has problems during the install.
ENV CMAKE_GENERATOR="Unix Makefiles"
ENV CMAKE_EXTRA_OPTIONS="-j8"
ENV SOURCES_BUILD_TYPE="Debug"

# Bullet
RUN cd ${RL_SOURCES}/bullet3 &&\
    mkdir -p build && cd build &&\
    cmake \
    -G"$CMAKE_GENERATOR" \
    -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
    -DBUILD_SHARED_LIBS=ON \
    .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

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
        liburdfdom-dev \
        # Boost
        libboost-regex-dev \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd ${RL_SOURCES}/dart &&\
    mkdir -p build && cd build &&\
    cmake \
        -GNinja \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done
    

# ign-cmake
RUN cd ${RL_SOURCES}/ign-cmake &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        .. &&\
    cmake --build . --target install -- $CMAKE_EXTRA_OPTIONS &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ing-math
RUN cd ${RL_SOURCES}/ign-math &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-common
RUN cd ${RL_SOURCES}/ign-common &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-tools
RUN cd ${RL_SOURCES}/ign-tools &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-fuel-tools
RUN cd ${RL_SOURCES}/ign-fuel-tools &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# sdformat
RUN cd ${RL_SOURCES}/sdformat &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        # TODO: build tests OFF?
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done
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
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-transport
RUN cd ${RL_SOURCES}/ign-transport &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-plugin
RUN cd ${RL_SOURCES}/ign-plugin &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-physics
RUN cd ${RL_SOURCES}/ign-physics &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

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
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-sensors
RUN cd ${RL_SOURCES}/ign-sensors &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DDRI_TESTS:BOOL=FALSE \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-gui
RUN cd ${RL_SOURCES}/ign-gui &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-gazebo
RUN cd ${RL_SOURCES}/ign-gazebo &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    make ${CMAKE_EXTRA_OPTIONS} install &&\
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-launch
RUN cd ${RL_SOURCES}/ign-launch &&\
    mkdir -p build && cd build &&\
    cmake \
        -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DBUILD_TESTING:BOOL=OFF \
        .. &&\
    #make ${CMAKE_EXTRA_OPTIONS} install &&
    chgrp -R runtimeusers $(pwd) && chmod -R g+rw $(pwd) &&\
    cat install_manifest.txt | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

# ign-plugins
# RUN cd ${RL_SOURCES}/ign-plugins &&\
#    mkdir -p build && cd build &&\
#    cmake \
#        -G "$CMAKE_GENERATOR" \
#        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
#        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
#        -DBUILD_TESTING:BOOL=OFF \
#        .. &&\
#    make ${CMAKE_EXTRA_OPTIONS} install

ENV IGN_GAZEBO_SYSTEM_PLUGIN_PATH=${RL_INSTALL}/lib/ign-gazebo-1/plugins


# Fix permissions of the directories inside RL_DIR
RUN find ${RL_DIR} \( -type d \) -print | while read FILE ; do chgrp runtimeusers "$FILE" && chmod g+rw "$FILE" ; done

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
        python3-pytest \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    pip3 install gym

# =============
# Install Julia
# =============

ARG JULIA_VER=1.1.0
ENV DEVENV_PATH=${DEVENV_PATH}:/opt/julia/bin

RUN cd /tmp &&\
    wget https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_VER%.*}/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
    cd /opt &&\
    tar xvf /tmp/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
    rm /tmp/julia-${JULIA_VER}-linux-x86_64.tar.gz &&\
    mv julia-${JULIA_VER} julia &&\
    /opt/julia/bin/julia --version

# TODO: these packages are not available to the user.
# Follow: https://discourse.julialang.org/t/how-does-one-set-up-a-centralized-julia-installation/13922/21
RUN \
    /opt/julia/bin/julia -e 'import Pkg; Pkg.add([\
        "IJulia",\
        "Plots",\
        "PyPlot",\
        "LaTeXStrings",\
        ]);'

# ============
# Install swig
# ============

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        autotools-dev \
        automake \
        bison \
        libpcre3-dev &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /tmp/ &&\
    git clone --depth 1 https://github.com/swig/swig.git &&\
    cd swig &&\
    sh autogen.sh &&\
    ./configure &&\
    make uninstall &&\
    make -j2 &&\
    make install &&\
    rm -r /tmp/swig

# ====================
# Image initialization
# ====================

COPY setup.sh /usr/sbin/setup_rl.sh
COPY entrypoint.sh /usr/sbin/entrypoint_rl.sh
RUN chmod 755 /usr/sbin/setup_rl.sh
RUN chmod 755 /usr/sbin/entrypoint_rl.sh
ENTRYPOINT ["/usr/sbin/entrypoint_rl.sh"]
CMD ["bash"]
