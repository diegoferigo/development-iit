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

# Helper function to match user and group permissions of all files inside a folder.
# Switching USER, as done above, allows creating all files as root:runtimeusers. However, in order to allow a seamless
# usage of resources created in the Dockerfile from the runtime user, we also need to grant writing permission to the
# runtime group to all files that are readable from the user (root in this case).
# Using find plays better than chown since we can filter out files more efficiently, preventing unnecessary copies done
# by Docker in different layers.
RUN echo "" >> /etc/bash.bashrc &&\
    echo "function fix_permissions() {" >> /etc/bash.bashrc &&\
    echo '  dir=$(readlink --canonicalize $1)' >> /etc/bash.bashrc &&\
    echo '  group=${2:-runtimeusers}' >> /etc/bash.bashrc &&\
    echo '  [[ ! -d "$dir" ]] && echo "Input $dir is not a directory" >/dev/stderr && exit 1' >> /etc/bash.bashrc &&\
    echo '  find $1 -group $group -not -type l -perm /u+w -not -perm -g+w -print -exec chmod g+w "{}" +' >> /etc/bash.bashrc &&\
    echo "}" >> /etc/bash.bashrc &&\
    echo "" >> /etc/bash.bashrc

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
ARG CONDA_PYTHON_VERSION=3.11
ENV MAMBA_ROOT_PREFIX=$CONDA_PREFIX/.mamba

# Install micromamba and create conda environment
RUN cd /usr/local &&\
    wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest \
        | tar -xvj bin/micromamba &&\
    eval "$(micromamba shell hook -s bash)" &&\    
    micromamba create -y -p $CONDA_PREFIX -c conda-forge \
      "python==$CONDA_PYTHON_VERSION.*" \
      mamba \
      mesa-libgl-cos7-x86_64 \
      &&\
    micromamba activate $CONDA_PREFIX &&\
    conda config --system --add channels conda-forge &&\
    conda config --system --set channel_priority strict &&\
    conda clean -afy &&\
    fix_permissions $CONDA_PREFIX

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
    fix_permissions $CONDA_PREFIX

# Application dependencies
RUN echo "chex <= 0.1.82" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "jaxlib = * = cuda*" >> $CONDA_PREFIX/conda-meta/pinned &&\
    echo "pytorch = * = cuda*" >> $CONDA_PREFIX/conda-meta/pinned &&\
    mamba install -y \
        black \
        coloredlogs \
        # TODO: not working due to too old typing_extensions
        # TODO: also pytest needs typing_extensions >= 4.6
        diffrax \
        equinox \
        #
        flax \
        gymnasium \
        gz-sim7 \
        idyntree \
        ipython \
        isort \
        jax \
        jupyter \
        mashumaro \
        matplotlib \
        meshcat-python \
        numpy \
        optax \
        pandas \
        pptree \
        pytorch \
        scipy \
        tensorboard \
        tensorflow-probability \
        &&\
    conda clean -afy &&\
    # Dirty workaround: override with pip package
    pip install "typing_extensions>=4.6" &&\
    rm -rf $HOME/.cache/pip &&\
    fix_permissions $CONDA_PREFIX

RUN gymnasium_version=="$(pip list | grep '^gymnasium ' | tr -s ' ' | cut -d ' ' -f 2)" &&\
    jax_version="$(pip list | grep '^jax ' | tr -s ' ' | cut -d ' ' -f 2)" &&\
    chex_version="$(pip list | grep '^chex ' | tr -s ' ' | cut -d ' ' -f 2)" &&\
    tfp_version="$(pip list | grep '^tensorflow-probability ' | tr -s ' ' | cut -d ' ' -f 2)" &&\
    numpy_version=="$(pip list | grep '^numpy ' | tr -s ' ' | cut -d ' ' -f 2)" &&\
    # Pin some conda version to prevent pip to update packages
    pip install \
      "chex==${chex_version}" \
      "gymnasium==${gymnasium_version}" \
      "jax==${jax_version}" \
      "numpy==${numpy_version}" \
      "tensorflow-probability==${tfp_version}" \
      # PyPI packages
      git+https://github.com/ami-iit/meshcat-viz-python \
      # TODO: distrax has a circular import error with tfp
      #distrax \#
      jaxlie \
      jax_dataclasses \
      loop-rate-limiters \
      pywebview[qt] \
      sb3_contrib \
      stable-baselines3 \
      &&\
    rm -rf $HOME/.cache/pip &&\
    fix_permissions $CONDA_PREFIX

# Configure Nvidia support
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# Install drivers for HW acceleration
# https://conda-forge.org/docs/maintainer/knowledge_base.html#libgl
ENV QT_X11_NO_MITSHM=1
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
      libegl1 \
      libgl1 \
      libgl1-mesa-dri \
      libgl1-mesa-glx \
      libglx-amber0 \
      libglx-mesa0 \
      mesa-va-drivers \
      mesa-vdpau-drivers \
      mesa-vulkan-drivers \
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
    echo '[[ ! -d $HOME/.dotfiles ]] && bash /usr/local/dotfiles/bootstrap' >> /etc/bash.bashrc

# Install PyCharm
ARG PYCHARM_VERSION=2023.2.2
ARG PYCHARM_VARIANT=professional
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
        libxtst6 libxext6 libxrender1 libfreetype6 libfontconfig1 libgtk2.0-0 libxslt1.1 libxxf86vm1 libwayland-cursor0 \
        libnss3 libnspr4 libatk-bridge2.0-0 libgbm1 libasound2 libatspi2.0-0 dbus-x11 libxcomposite1 libxkbcommon-x11-0 libx11-xcb1 libxcb* &&\
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
