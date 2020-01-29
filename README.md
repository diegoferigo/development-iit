<p align="center">
    <h1 align="center">development environments</h1>
</p>

<p align="center">
<b><a href="https://github.com/diegoferigo/development-iit#what">What</a></b>
•
<b><a href="https://github.com/diegoferigo/development-iit#build-the-images">Build</a></b>
•
<b><a href="https://github.com/diegoferigo/development-iit#download-the-images">Download</a></b>
•
<b><a href="https://github.com/diegoferigo/development-iit#use-the-images">Use</a></b>
•
<b><a href="https://github.com/diegoferigo/development-iit#notes">Notes</a></b>
</p>

<p align="center">
    <a href="https://github.com/diegoferigo/development-iit/actions">
    <img src="https://github.com/diegoferigo/development-iit/workflows/Docker%20Images/badge.svg" alt="Build Status (master)" />
    </a>
</p>

## What

This repository stores my personal development environment for the activities at the Italian Institute of Technology.

These images are based upon the [`diegoferigo/devenv`](https://github.com/diegoferigo/devenv) tool, which provides a bunch of nice features such as runtime user creation, X11 forwarding support, [`nvidia-docker`](https://github.com/NVIDIA/nvidia-docker), etc.

This repository stores three docker-based isolated development environments, progressively built upon each other:

- [**`Tools`**](Tools/Dockerfile) provides a generic toolset for C++ development and it is a good candidate to be the base of other images. It mainly contains QtCreator, updated version of cmake, gcc and clang, and other various debugging tools such as gdb, valgrind, rr, iwyu, etc.
- [**`Development`**](Development/Dockerfile) contains the YARP and ROS robotic middlewares and Gazebo, and all the projects that depend on them.
- [**`ReinforcementLearning`**](RL/Dockerfile) is still in an early stage of development, and it contains all the resources I need for my research project. At the time of writing it has mainly the ignition robotics libraries, Julia, Jupyter notebook, few python packages.

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
| `rl-latest`          |
| `rl-master`          |

All the images are based on top of `diegoferigo/devenv:nvidia` which optionally support the `nvidia` runtime if specified in the config file.

## Download the images

Alternatively to building the images, you can download the pre-built versions which are stored in my [dockerhub profile](https://hub.docker.com/u/diegoferigo).
This repository has a CI pipeline that periodically builds all the images.
Though, not all tags are pushed to dockerhub.

## Use the images

In the [conf](conf/) folder you can find the devenv config files of the provided images.
Edit them for your needs and then, from that folder, just execute:

```
devenv -f <image>.yml up
```

Finally, access the image using `docker exec -it <image> su $(whoami)`.

## Notes

### Bumblebee support

The `nvidia` version of the images, thanks to `nvidia-docker`, supports natively systems based on Nvidia prime.
A system properly configured for using bumblebee (or just bbswitch) can start a container able to access the Nvidia gpu only by prepending `optirun` to the `devenv` / `docker run` / `docker-compose` command.

Be aware that if you start in this way detached containers (`-d`) the `optirun` process dies right after, turning off the GPU, while the container stays active in the background with missing hardware resources.
