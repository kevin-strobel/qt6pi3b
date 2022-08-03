# Cross-compiling Qt 6 for the Raspberry Pi 3B (64-bit)

## Preface

This is a guide for cross-compiling Qt 6 for Raspberry Pi 3B (64-bit OS).
To have a clean, defined, and reliable environment, I build Qt 6 using Docker. However, the build worked for me in a Virtual Machine, too. Just be sure to use a **Ubuntu 20.04 LTS (Focal Fossa)** VM if you don't use Docker since the build will fail with the latest Ubuntu version.

This guide is heavily inspired by [1] and [2].

## Build

In the following, your "computer" refers to as where you execute Docker (most Linux distributions will do), "host" refers to as the Docker environment (Ubuntu 20.04 LTS), and "target" refers to as the Raspberry Pi 3B (Raspbian 64-bit).

### Raspberry Pi

- Setup the Raspberry Pi using a 64-bit image of Raspbian (I used the *2022-04-04-raspios-bullseye-arm64.img.xz* image) from the official Raspberry Pi homepage).
- Install the required software

```
sudo apt update
sudo apt full-upgrade
sudo reboot

sudo apt-get install libboost-all-dev libudev-dev libinput-dev libts-dev libmtdev-dev libjpeg-dev libfontconfig1-dev libssl-dev libdbus-1-dev libglib2.0-dev libxkbcommon-dev libegl1-mesa-dev libgbm-dev libgles2-mesa-dev mesa-common-dev libasound2-dev libpulse-dev gstreamer1.0-omx libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev  gstreamer1.0-alsa libvpx-dev libsrtp2-dev libsnappy-dev libnss3-dev "^libxcb.*" flex bison libxslt-dev ruby gperf libbz2-dev libcups2-dev libatkmm-1.6-dev libxi6 libxcomposite1 libfreetype6-dev libicu-dev libsqlite3-dev libxslt1-dev

sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev libx11-dev freetds-dev libsqlite3-dev libpq-dev libiodbc2-dev firebird-dev libgst-dev libxext-dev libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev libxcb-shm0 libxcb-shm0-dev libxcb-icccm4 libxcb-icccm4-dev libxcb-sync1 libxcb-sync-dev libxcb-render-util0 libxcb-render-util0-dev libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-glx0-dev libxi-dev libdrm-dev libxcb-xinerama0 libxcb-xinerama0-dev libatspi2.0-dev libxcursor-dev libxcomposite-dev libxdamage-dev libxss-dev libxtst-dev libpci-dev libcap-dev libxrandr-dev libdirectfb-dev libaudio-dev libxkbcommon-x11-dev

sudo mkdir /usr/local/qt6
```

- Enable the SSH service and make sure that you can connect from your computer to your RPi.

### Computer

First of all, install *rsync*, *ssh*, *git* and *docker* on your computer. I assume you have a basic understanding of Docker.

Then,

- Checkout this repository
- Execute `./prepareSysroot.sh <RPI username> <RPI IP address>`
  This copies the Raspberry Pi's sysroot to your computer. Depending on your configuration, you may enter your RPi user's password three times.
- Carefully look at the Dockerfile's "*PLEASE CUSTOMIZE THIS SECTION*" and edit it if necessary.
- Execute `docker build --tag qtpi/qtpi:1.0 .`
  This will generate a Docker image while compiling and cross-compiling Qt. Since most of the process is done here, it will take some time.
- When the last step succeeded, you now have the complete environment ready for compiling Qt applications for your host / your computer as well as your Raspberry Pi.
- At last, you should run a Docker container from the newly generated Docker image: `docker run -it --rm qtpi/qtpi:1.0`
  From there, simply execute `~/copyQtToRPi.sh <RPI username> <RPI IP address>`
  to copy the Qt files to your Raspberry Pi.

Inside the Docker container, the Qt host installation is located at **~/qt-host**, the Qt target installation at **~/qt-raspi** (see [1]).

For compiling and executing sample applications on the host or target, see [2].

## References

[1] https://wiki.qt.io/Cross-Compile_Qt_6_for_Raspberry_Pi

[2] https://github.com/PhysicsX/QTonRaspberryPi/blob/main/README.md
