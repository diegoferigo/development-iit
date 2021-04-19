ARG from=diegoferigo/development:latest
FROM ${from}

ENV RL_DIR=/rl
ENV RL_INSTALL=${RL_DIR}/local
ENV RL_SOURCES=${RL_DIR}/sources
ENV PATH=${RL_INSTALL}/bin:${PATH}
ENV CMAKE_PREFIX_PATH=${RL_INSTALL}:${CMAKE_PREFIX_PATH}

RUN mkdir -p ${RL_SOURCES}

ENV CMAKE_GENERATOR="Ninja"
ENV SOURCES_BUILD_TYPE="RelWithDebInfo"

# =================
# Python VirtualEnv
# =================

ENV VIRTUAL_ENV=/venv
ENV PATH=${VIRTUAL_ENV}/bin:$PATH
ARG GET_PYTHON_VERSION="python3 -c 'from sys import version_info as i; print(f\"{i[0]}.{i[1]}\")'"

RUN apt-get update &&\
    apt-get install -y --no-install-recommends virtualenv python3-tk &&\
    rm -rf /var/lib/apt/lists/* &&\
    virtualenv -p python$(eval ${GET_PYTHON_VERSION}) ${VIRTUAL_ENV} &&\
    python -m pip install --upgrade pip &&\
    pip install \
        jupyter \
        docker \
        PyYAML \
        matplotlib \
        setuptools_scm \
        pybullet \
        ray[all] \
        torch torchvision \
        tensorboard tensorboardX \
        tensorflow tensorflow-probability \
        PyVirtualDisplay PILLOW imageio imageio-ffmpeg \
        cvxpy osqp casadi \
        &&\
    rm -r $HOME/.cache/pip &&\
    find ${VIRTUAL_ENV} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# =======
# PyCharm
# =======

ARG PYCHARM_VER=2021.1
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

# =================
# Ignition Robotics
# =================

# https://ignitionrobotics.org/docs/citadel/install
# http://gazebosim.org/tutorials?tut=install_dependencies_from_source

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
    rm -rf /var/lib/apt/lists/* &&\
    cd ${RL_SOURCES} &&\
    git clone --depth=1 https://github.com/diegoferigo/dart &&\
    mkdir -p dart/build && cd dart/build &&\
    sed -i "s/if(TARGET dart AND NOT DART_BUILD_DARTPY)/if(TARGET dart AND NOT DART_BUILD_DARTPY AND OFF)/g" \
       ../CMakeLists.txt &&\
    cmake .. \
        -GNinja \
        -DCMAKE_INSTALL_PREFIX=${RL_INSTALL} \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        -DHAVE_BULLET:BOOL=ON \
        -DHAVE_DOXYGEN:BOOL=OFF \
        -DHAVE_ODE:BOOL=ON \
        -DDART_BUILD_DARTPY:BOOL=OFF \
        -DDART_BUILD_EXTRAS:BOOL=OFF \
    &&\
    ninja install &&\
    find . -type f -not -name 'CMakeCache.txt' -delete &&\
    find ${RL_SOURCES} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    find ${RL_INSTALL} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+
ENV LD_LIBRARY_PATH=${RL_INSTALL}/lib:${LD_LIBRARY_PATH}

RUN pip install vcstool colcon-common-extensions &&\
    rm -r $HOME/.cache/pip &&\
    find ${VIRTUAL_ENV} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

ARG IGN_SOURCES_DATE="20210103"
ARG IGNITION_DISTRIBUTION="edifice"
ARG IGNITION_DEFAULT_CHANNEL="stable"

RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-${IGNITION_DEFAULT_CHANNEL} `lsb_release -cs` main" > \
        /etc/apt/sources.list.d/gazebo-${IGNITION_DEFAULT_CHANNEL}.list &&\
    wget http://packages.osrfoundation.org/gazebo.key -qO - | apt-key add - &&\
    mkdir -p ${RL_SOURCES}/workspace/src &&\
    cd ${RL_SOURCES}/workspace/src &&\
    wget -q https://raw.githubusercontent.com/ignition-tooling/gazebodistro/master/collection-${IGNITION_DISTRIBUTION}.yaml &&\
    vcs import < collection-${IGNITION_DISTRIBUTION}.yaml &&\
    apt-get update &&\
    sudo apt -y install --no-install-recommends \
        $(sort -u $(find . -iname 'packages-'$(lsb_release -cs)'.apt' -o -iname 'packages.apt') | grep -v -E "dart|^libignition|^libsdformat" | tr '\n' ' ') &&\
    rm -rf /var/lib/apt/lists/* &&\
    sed -i -e "s|ignitionrobotics/ign-physics|diegoferigo/ign-physics|g" collection-${IGNITION_DISTRIBUTION}.yaml &&\
    sed -i -e "s|ign-physics4|fix/compute_joint_force_edifice|g" collection-${IGNITION_DISTRIBUTION}.yaml &&\
    cd ${RL_SOURCES}/workspace &&\
    colcon graph &&\
    export CC=gcc && export CXX=g++ &&\
    colcon build \
        --cmake-args \
        -G"$CMAKE_GENERATOR" \
        -DBUILD_TESTING:BOOL=OFF \
        -DCMAKE_BUILD_TYPE=${SOURCES_BUILD_TYPE} \
        --merge-install \
        &&\
    find build/ -type f -not -name 'CMakeCache.txt' -delete &&\
    find ${RL_SOURCES}/workspace -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ &&\
    echo "[[ -f ${RL_SOURCES}/workspace/install/setup.bash ]] && source ${RL_SOURCES}/workspace/install/setup.bash" >> /etc/bash.bashrc

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

RUN pip install --pre gym-ignition[website,test] &&\
    pip install --no-build-isolation git+https://github.com/dic-iit/gazebo-scenario-plugins &&\
    rm -rf $HOME/.cache/pip &&\
    find ${VIRTUAL_ENV} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+

# Install micromamba
RUN cd /usr/local &&\
    wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest \
        | tar -xvj bin/micromamba &&\
    echo 'eval "$(micromamba shell hook -s bash)"' >> /etc/bash.bashrc

# Install libgfortran 3.0
ENV CONDA_PREFIX=/conda
ENV MAMBA_ROOT_PREFIX=${CONDA_PREFIX}/.micromamba
RUN micromamba create -y -p ${CONDA_PREFIX} libgfortran=3.0.0 -c conda-forge &&\
    echo "micromamba activate ${CONDA_PREFIX}" >> /etc/bash.bashrc &&\
    rm -rf ${MAMBA_ROOT_PREFIX}/pkgs &&\
    find ${CONDA_PREFIX} -not -group runtimeusers -exec chgrp runtimeusers {} \; -exec chmod g+rw {} \+ 
ENV LD_LIBRARY_PATH=$CONDA_PREFIX/lib/:$LD_LIBRARY_PATH

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
