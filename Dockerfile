#######################################################################
# Docker image generation for cross-compiling Qt 6 for Raspberry Pi 3 #
#######################################################################

# Based on: https://wiki.qt.io/Cross-Compile_Qt_6_for_Raspberry_Pi
#               |- https://wiki.qt.io/Building_Qt_6_from_Git
#           https://github.com/PhysicsX/QTonRaspberryPi/blob/main/README.md

# Building Qt does not work on the newest Ubuntu (linker error), so let's use Ubuntu 20.04
FROM ubuntu:focal

#######################################################################
#                 PLEASE CUSTOMIZE THIS SECTION
#######################################################################
# The Qt version to build
ARG QT_VERSION=6.3.1
# The Qt modules to build
# I use QtQuick with QML, so the following three modules need to be built
ARG QT_MODULES=qtbase,qtshadertools,qtdeclarative
# How many cores to use for parallel builds
ARG PARALLELIZATION=8
# Your time zone (optionally change it)
ARG TZ=Europe/Berlin
#######################################################################

ARG CMAKE_GIT_HASH=6b24b9c7fca09a7e5ca4ae652f4252175e168bde
ARG RPI_DEVICE=linux-rasp-pi3-g++

#############################
# Prepare and update Ubuntu #
#############################
RUN apt update \
 && apt upgrade -y \
 && apt install sudo \
 && useradd -G sudo -m qtpi \
 && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER qtpi:qtpi
WORKDIR /home/qtpi

#############################
# Install required packages #
#############################
# Qt
RUN sudo DEBIAN_FRONTEND=noninteractive TZ="${TZ}" apt install -y make build-essential libclang-dev ninja-build gcc git bison python3 gperf pkg-config libfontconfig1-dev libfreetype6-dev libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libatspi2.0-dev libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev \
# cross-compiler toolchain \
 && sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
# package for building CMake \
 && sudo apt install -y libssl-dev \
# data transfer \
 && sudo apt install -y rsync wget

#######################
# Create working dirs #
#######################
RUN mkdir rpi-sysroot rpi-sysroot/usr rpi-sysroot/opt \
 && mkdir qt-host qt-raspi qthost-build qtpi-build

################################################
# Copy sysroot into the image and fix symlinks #
################################################
COPY --chown=qtpi:qtpi rpi-sysroot /home/qtpi/rpi-sysroot

RUN wget https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py \
 && chmod u+x sysroot-relativelinks.py \
 && python3 sysroot-relativelinks.py rpi-sysroot

##################################
# Build a CMake version that can #
# cope with our toolchain.cmake  #
##################################
RUN git clone https://github.com/Kitware/CMake.git \
 && cd CMake \
 && git checkout ${CMAKE_GIT_HASH} \
 && ./bootstrap \
 && make \
 && sudo make install \
 && cd .. \
 && rm -rf CMake

####################
# Clone Qt sources #
####################
RUN git clone git://code.qt.io/qt/qt5.git qt6 \
 && cd qt6 \
 && git checkout v${QT_VERSION} \
 && perl init-repository --module-subset=${QT_MODULES}
# Leave the qt6 folder in case you must look up sources later

#################
# Qt HOST build #
#################
RUN cd qthost-build \
 && ../qt6/configure -prefix $HOME/qt-host \
 && cmake --build . --parallel ${PARALLELIZATION} \
 && cmake --install . \
 && cd .. \
 && rm -rf qthost-build

###################
# Qt TARGET build #
###################
COPY --chown=qtpi:qtpi toolchain.cmake /home/qtpi/toolchain.cmake

RUN cd qtpi-build \
 && ../qt6/configure -release -opengl es2 -nomake examples -nomake tests -qt-host-path $HOME/qt-host -extprefix $HOME/qt-raspi -prefix /usr/local/qt6 -device ${RPI_DEVICE} -device-option CROSS_COMPILE=aarch64-linux-gnu- -- -DCMAKE_TOOLCHAIN_FILE=$HOME/toolchain.cmake -DQT_FEATURE_xcb=ON -DFEATURE_xcb_xlib=ON -DQT_FEATURE_xlib=ON \
 && cmake --build . --parallel ${PARALLELIZATION} \
 && cmake --install . \
 && cd .. \
 && rm -rf qtpi-build

########################################
# Syncing the Qt files back to the RPi #
# is done in the docker container      #
########################################
COPY --chown=qtpi:qtpi _copyQtToRPi.sh /home/qtpi/copyQtToRPi.sh

