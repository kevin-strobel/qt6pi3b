#!/bin/bash
if [ "$#" -ne 2 ]; then
	echo "Parameter count does not match."
	exit -1
fi

error() {
	echo "ERROR!"
	echo "COPYING THE SYSROOT DID NOT FINISH SUCCESSFULLY. PLEASE RETRY!"
	exit -1
}
trap "error" ERR

RPI_USERNAME=$1
RPI_IP_ADDR=$2

mkdir -p rpi-sysroot
rm -rf rpi-sysroot/*

rsync -avz --rsync-path="sudo rsync" --delete ${RPI_USERNAME}@${RPI_IP_ADDR}:/lib rpi-sysroot
rsync -avz --rsync-path="sudo rsync" --delete ${RPI_USERNAME}@${RPI_IP_ADDR}:/usr/include rpi-sysroot/usr
rsync -avz --rsync-path="sudo rsync" --delete ${RPI_USERNAME}@${RPI_IP_ADDR}:/usr/lib rpi-sysroot/usr

echo "Success!"
echo "Now go on with the docker image generation."

