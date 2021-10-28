# About

The Dockerfiles distributed alongside this readme will produce Docker images that contain Advance Toolchain stack. Each image is composed of a bare minimum Linux distribution on which the Advance Toolchain is supported, and some extra development tools for C and C++. The Advance Toolchain provides a set of packages that will be installed according to the following profiles:

  - Runtime: the image comes with only runtime and mcore-libs (Multi-core libraries) packages, resulting in a image with smaller size.
  - Development: the image comes with development, performance, and runtime packages.

# Requirements
If you are going to use the Makefile for builds, then the following commands should be installed in your host machine:

 - make
 - lsb\_release
 - docker

Notice that the Linux user used to build Docker images should have permission to run the **docker** command. Check your Linux distribution documentation for more information on this topic.

# Build
The *configs* directory contain a set of Dockerfiles to build images with different combinations of AT version (and packages), and a base Linux distribution. Thus, to ease the build process, use the **make** command as follows:

```
$ make
```

By default **make** builds an image with following configuration:

 - Latest AT version
 - Base image OS same of the host
 - Development profile

Some build parameters are available though, use following environment variables to set them:

 - **AT\_VERSION**=*version*, where *version* is the AT version (10.0, 11.0 and so on)
 - **AT\_MINOR**=*minor* where *minor* is the update number (this will be used if AT\_EXTRA is set)
 - **AT\_EXTRA**=*extra*, where *extra* is a value to add to the AT version (alpha1, beta2, rc1...)
 - **DISTRO\_NAME**=*distro*, where *distro* is the name of the distro (debian, ubuntu...)
 - **DISTRO\_NICK**=*nick*, where *nick* is the nickname/version of the distro (buster, focal, xenial...)
 - **IMAGE\_PROFILE**=*profile*, where *profile* indicates a profile which may be either *runtime* or *devel*
 - **REPO**=*repo*, where *repo* is a remote repository to get the AT packages (by default https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at)
 - **CONTAINER\_TOOL**=*tool*, where *tool* is the container tool to use (by default it searches for docker or podman)

The Makefile get the name of your host's OS to select a suitable image OS. Thus, you must use a Linux distribution to build the image on which we provide a Dockerfile for the same OS. You can check supported distribution in the directory configs/*version*/ for the given Advance Toolchain *version*.

# Run
You can use **docker run** to create a container from AT images. For example, following command starts a container from AT 10.0 devel image and attach to a shell session:
```
docker run -it --privileged at/10.0:ubuntu_devel_ppc64le 
```
**Important**: some commands as gdb and ocount require access to host devices which are usually denied by default. This can be circumveted by granting privileged access to the container (see --privileged flag in above example), or allowing access to specfic devices. See [Runtime privilege and Linux capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) section at Docker Engine Reference for further details.
