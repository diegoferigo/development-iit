ARG from=ubuntu:jammy
FROM ${from}

# Change default shell to bash. This is effective only in the Dockerfile.
SHELL ["/bin/bash", "-i", "-c"]

# Create a new runtimeusers group and add root
RUN groupadd -K GID_MIN=100 -K GID_MAX=499 runtimeusers &&\
    gpasswd -a root runtimeusers

# All the resources that root creates in this image will belong to the "runtimeusers" group.
# We will make sure that files owned by `root:runtimeusers` will be writable also to all users belonging this custom group.
# This way, a user created together with the container will automatically have r/w access to all resources of this image.
USER root:runtimeusers

# System utilities
ENV TZ="Etc/UTC"
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update &&\
    apt-get install -y --no-install-recommends tzdata &&\
    apt-get install -y --no-install-recommends gnupg2 software-properties-common apt-utils &&\
    apt-get install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        git \
        nano \
        wget \
        tree \
        gosu \
        sudo \
        less \
        htop \
        net-tools \
        iputils-ping \
        &&\
    rm -rf /var/lib/apt/lists/*

# Configure conda
ENV CONDA_PREFIX=/jaxsim
ARG CONDA_PYTHON_VERSION=3.10.8
ENV MAMBA_ROOT_PREFIX=$CONDA_PREFIX/.mamba

# Install micromamba and create conda environment
RUN cd /usr/local &&\
    wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest \
        | tar -xvj bin/micromamba &&\
    eval "$(micromamba shell hook -s bash)" &&\    
    micromamba create -y -p $CONDA_PREFIX -c conda-forge \
      "python==$CONDA_PYTHON_VERSION.*" \
      "mamba==1.2.0" \
      mesa-libgl-cos7-x86_64 \
      &&\
    micromamba activate $CONDA_PREFIX &&\
    conda config --system --add channels conda-forge &&\
    conda config --system --set channel_priority strict &&\
    conda clean -afy &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' +

# Enable by default the conda environment for all users
RUN echo 'function activate_conda() {' >> /etc/bash.bashrc &&\
    echo '  eval "$(micromamba shell hook -s bash)"' >> /etc/bash.bashrc &&\
    echo '  micromamba activate $CONDA_PREFIX' >> /etc/bash.bashrc &&\
    echo '}' >> /etc/bash.bashrc &&\
    echo '[[ -z $NO_CONDA ]] && activate_conda' >> /etc/bash.bashrc

# Allow installing CUDA packages also if no GPU is detected in Dockerfile:
# https://conda-forge.org/docs/user/tipsandtricks.html#installing-cuda-enabled-packages-like-tensorflow-and-pytorch
ARG CONDA_OVERRIDE_CUDA="11.2"

# Install CUDA Toolkit
ARG cudatoolkit_version="11.2.*"
RUN echo "cudatoolkit $cudatoolkit_version" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "cuda-nvcc 12.0.*" >> $CONDA_PREFIX/conda-meta/pinned &&\
    mamba install -y cuda-nvcc -c nvidia &&\
    mamba install -y cudatoolkit cudnn compilers -c conda-forge &&\
    conda clean -afy &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' +

# Application dependencies
RUN echo "jax = 0.3.15" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "jaxlib = 0.3.15 = cuda112*" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "flax < 0.6.0" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "numpy < 1.23.0" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "optax < 0.1.5" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "pytorch = * = cuda112*" >> $CONDA_PREFIX/conda-meta/pinned &&\
    mamba install -y \
        black \
        coloredlogs \
        flax \
        gz-sim7 \
        idyntree \
        ipython \
        isort \
        jax \
        jupyter \
        mashumaro \
        matplotlib \
        numpy \
        optax \
        pandas \
        pptree \
        pytorch \
        scipy \
        tensorflow-probability \
        &&\
    conda clean -afy &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' +

RUN jax_version="$(pip list | grep '^jax ' | tr -s ' ' | cut -d ' ' -f 2)" &&\
    tfp_version="$(pip list | grep '^tensorflow-probability ' | tr -s ' ' | cut -d ' ' -f 2)" &&\
    pip install \
      distrax \
      jaxlie \
      "jax==${jax_version}" \
      "jax_dataclasses<1.4.0" \
      "tensorflow-probability==${tfp_version}" \
      &&\
    pip install --pre \
      gymnasium \
      rod \
      sb3_contrib \
      stable-baselines3 \
      &&\
    pip install git+https://github.com/ami-iit/meshcat-viz-python &&\
    rm -rf $HOME/.cache/pip &&\
    find $CONDA_PREFIX -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' +

# Configure Nvidia support
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all


# Install drivers for HW acceleration
ENV QT_X11_NO_MITSHM=1
RUN apt-get update &&\
    # https://conda-forge.org/docs/maintainer/knowledge_base.html#libgl
    apt-get install -y --no-install-recommends libgl1-mesa-glx libgl1-mesa-dri &&\
    # Other video drivers
    apt-get install -y --no-install-recommends \
      libgl1-mesa-dri libglx-amber0 libglx-mesa0 mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers \
      &&\
    rm -rf /var/lib/apt/lists/*

# Runtime user
ENV USER_UID=1000
ENV USER_GID=1000
ENV USERNAME=docker

# Setup an additional entrypoint script
USER root:root
COPY setup.sh /usr/sbin/setup_jaxsim.sh
COPY entrypoint.sh /usr/sbin/entrypoint_jaxsim.sh
RUN chmod 755 /usr/sbin/setup_jaxsim.sh &&\
    chmod 755 /usr/sbin/entrypoint_jaxsim.sh
USER root:runtimeusers
ENTRYPOINT ["/usr/sbin/entrypoint_jaxsim.sh"]
CMD ["bash", "-i"]

# Print the full conda environment for reproducibility purpose
RUN mamba env export --no-builds | grep -v "^prefix"

# ===========
# DEVELOPMENT
# ===========

# Dotfiles
ENV DOTFILES_SHARE=/usr/local
RUN apt-add-repository ppa:fish-shell/release-3 &&\
    apt-get install -y --no-install-recommends \
        nano git wget curl unzip bash-completion fish \
        &&\
    rm -rf /var/lib/apt/lists/* &&\
    git clone https://github.com/diegoferigo/dotfiles /usr/local/dotfiles &&\
    bash -i /usr/local/dotfiles/bootstrap &&\
    echo '[[ ! -d $HOME/.dotfiles ]] && bash -i /usr/local/dotfiles/bootstrap' >> /etc/bash.bashrc

# Install PyCharm
ARG PYCHARM_VERSION=2023.1
ARG PYCHARM_VARIANT=professional
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        libxtst6 libxext6 libxrender1 libfreetype6 libfontconfig1 libgtk2.0-0 libxslt1.1 libxxf86vm1 \
        libnss3 libnspr4 libatk-bridge2.0-0 libgbm1 libasound2 libatspi2.0-0 dbus-x11 libxcomposite1 libxkbcommon0 libxcb* &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /opt && mkdir -p pycharm && cd pycharm &&\
    curl -L https://download.jetbrains.com/python/pycharm-${PYCHARM_VARIANT}-${PYCHARM_VERSION}.tar.gz -o /opt/pycharm/installer.tgz &&\
    tar --strip-components=1 -xzf installer.tgz &&\
    rm installer.tgz &&\
    python_folder=$([[ $PYCHARM_VARIANT = "professional" ]] && echo "python" || echo "python-ce") &&\
    python3 /opt/pycharm/plugins/${python_folder}/helpers/pydev/setup_cython.py build_ext --inplace &&\
    ln -s /opt/pycharm/bin/pycharm.sh /usr/local/bin/pycharm &&\
    find /opt/pycharm -group runtimeusers -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w '{}' +

USER root:runtimeusers
