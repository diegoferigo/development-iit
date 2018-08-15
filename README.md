# Development environment

[![Build Status (master)](https://img.shields.io/travis-ci/com/diegoferigo/development-iit/master.svg?logo=travis&label=master)](https://travis-ci.com/diegoferigo/development-iit)

This repository stores my personal development environment for the activities at the Italian Institute of Technology. 

It constists of a docker-based isolated development environment composed by two images: **`Tools`** and **`Development`**.

`Tools` provides a generic toolset for C++ development and it can be useful to base other images on top of it. `Development` instead is very specific and it is based on my workflow: it includes all the git repositories I work on and a bunch of utilities, scripts and customization I developed over time.

#### Index

- [Tools](#tools)
  - [How to get Tools](#how-to-get-tools)
  - [How to use Tools](#how-to-use-tools)
- [Development](#development)
- [Notes](#notes)
  - [Bumblebee support](#bumblebee-support)

## **`Tools`** 

This image provides a complete toolset for C++ development:

- QtCreator
- Updated CMake
- Updated clang
- Debugging tools (gdb, valgrind, rr, iwyu)

It contains also Atom Editor with some useful packages.

Furthermore, it provides the following features:

- Runtime user generation
- Support of Intel HW Acceleration
- Support of Nvidia HW Acceleration through [nvidia-docker 2](https://github.com/NVIDIA/nvidia-docker)

### How to get `Tools`

#### Build the image

`Tools` can be built with the classic `docker build` process. By default, the image is built with the latest version of clang and using `ubuntu:bionic` as base image. The image can be customized in the following way:

```bash
docker build \
    --build-arg from=ubuntu:bionic \
    --build-arg clang_version=6.0  \
    --rm -t \
    diegoferigo/tools:custom .
```

#### Download the image

This image is also hosted in my dockerhub profile. You can get the prebuilt image with:

```bash
docker pull diegoferigo/tools:$TAG
```

Where `$TAG` is one of the following:

| Tag | Base image |
| --- | ---------- |
| `latest` | `ubuntu:bionic` |
| `nvidia` | `nvidia/opengl:1.0-glvnd-runtime-ubuntu18.04` |

### How to use `Tools`

The main options you can specify for `Tools` are related to the runtime user and X11 support. Here an example showing how to open a GUI that access your system's xorg server:

```bash
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | grep -v ffff | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

docker run -it --rm \
    -e USER_UID=$(id -u) \
    -e USER_GID=$(id -g) \
    -e USERNAME=$(whoami) \
    -v $XSOCK:$XSOCK:rw \
    -v $XAUTH:$XAUTH:rw \
    -e XAUTHORITY=${XAUTH} \
    -e DISPLAY \
    --name tools \
    diegoferigo/tools \
    qtcreator
```

**Note:** if you have an Nvidia GPU, running this simple example requires the `diegoferigo/tools:nvidia` image and the `--runtime nvidia` command line option.

## **`Development`**

`Development` is built upon `Tools` and on top of it this image downloads, configures, and installs all the specific repositories I need for my development activities. They belong mainly to the [robotology](https://github.com/robotology) organization.

The configuration of this image is demanded to a [control.sh](Development/scripts/control.sh) script. This helper aims to simplify the container configuration by providing high-level options such as systemd support, X11 forwarding, gdb support, etc.

**Note:** The former configuration method based on docker-compose can be found in the deleted  [`compose` folder](https://github.com/diegoferigo/development-iit/tree/e89fbec3a7f554004512898a6bccf54063a06017/Development/compose).

## Notes

### Bumblebee support

The `nvidia` version of the images, thanks to `nvidia-docker`, supports natively systems based on Nvidia prime. A system properly configured for using bumblebee (or just bbswitch) can start a container able to access the Nvidia gpu only by prepending `optirun` to the `docker run` / `docker-compose` / `control.sh` command.

Be aware that if you start in this way detached containers (`-d`) the `optirun` process dies right after, turning off the GPU, while the container stays active in the background with missing hardware resources. 
