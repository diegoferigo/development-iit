# Development environment [![Build Status (master)](https://img.shields.io/travis/com/diegoferigo/development-iit/master.svg?logo=travis&label=master)](https://travis-ci.com/diegoferigo/development-iit)

[Build](#build-the-images) • [Download](#download-the-images) • [Use](#use-the-images) • [Notes](#notes)

###

This repository stores my personal development environment for the activities at the Italian Institute of Technology.

These images are based upon the [`diegoferigo/devenv`](https://github.com/diegoferigo/devenv) tool, which provides a bunch of nice features such as runtime user creation, X11 forwarding support, [`nvidia-docker`](https://github.com/NVIDIA/nvidia-docker), etc.

This repository stores three docker-based isolated development environment, progressively built upon each other:

- [**`Tools`**](Tools/Dockerfile) provides a generic toolset for C++ development and it is a good candidate to be the base of other images. It mainly contains QtCreator, updated version of cmake, gcc and clang, and other various debugging tools such as gdb, valgrind, rr, iwyu, etc.
- [**`Development`**](Development/Dockerfile) contains the YARP and ROS robotic middlewares and Gazebo, and all the projects that depend on them.
- [**`ReinforcementLearning`**](RL/Dockerfile) is still in an early stage of development, and it contains all the resources I need for my research project. At the time of writing it has mainly the ignition gazebo libraries, Julia, and Jupyter notebook.

In all these images there are included many utilities, scripts, and customization I developed over time.

## Build the images

All the images can be built using the provided [Makefile](Makefile). Just type:

```
make <target>
```

| Targets |
| ------- |
| `tools`              |
| `development-latest` |
| `development-master` |
| `development-devel`  |
| `rl-latest`          |
| `rl-master`          |

The `-master` and `-devel` targets clone repositories with the respective git branches. All the images are based on top of `diegoferigo/devenv:nvidia` which optionally support the `nvidia` runtime if specified in the config file.

## Download the images

Alternatively to building the images, you can download the pre-built versions which are stored in my [dockerhub profile](https://hub.docker.com/u/diegoferigo). Not all tags are pushed by the CI pipeline.

## Use the images

In the [conf](conf/) folder you can find the devenv config files of the provided images. Edit them for your needs and then from that folder, just execute:

```
devenv -f <image>.yml up
```

Finally, access the image using `docker exec -it <image> su $(whoami)`.

## Notes

### Bumblebee support

The `nvidia` version of the images, thanks to `nvidia-docker`, supports natively systems based on Nvidia prime. A system properly configured for using bumblebee (or just bbswitch) can start a container able to access the Nvidia gpu only by prepending `optirun` to the `devenv` / `docker run` / `docker-compose` command.

Be aware that if you start in this way detached containers (`-d`) the `optirun` process dies right after, turning off the GPU, while the container stays active in the background with missing hardware resources.
