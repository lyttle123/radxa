#!/bin/bash

##########################################################################################################
# Paths and variables
##########################################################################################################

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${scriptdir}
cd ..
basedir=$(pwd)
cd ..
radxadir=$(pwd)
cd ${basedir}

# read config-file
source ${basedir}/build.cfg


##########################################################################################################
# functions
##########################################################################################################

function setAutoStartX {
        cd ${rootfsdir}
        mkdir mp
        mount -o loop rock_rootfs-${version}.img mp
        cat mp/etc/rc.local | sed 's@^autoStartX=.*$@autoStartX=\"'${autoStartX}'\"@' > tmpFile
        mv tmpFile mp/etc/rc.local
        chmod +x mp/etc/rc.local
        sleep 10
        umount mp
        rmdir mp
}

function getPackTools {
        git clone https://github.com/frep/rockchip-pack-tools
}

function createNandImg {
	cd ${rootfsdir}
	getPackTools
	mkdir -p rockchip-pack-tools/Linux
	mv rock_rootfs-${version}.img rockchip-pack-tools/Linux/rootfs.img
	cp ${bootImgDir}/boot-linux.img rockchip-pack-tools/Linux/
	cd rockchip-pack-tools
	./mkupdate.sh
}

function cleanup {
	mv Linux/rootfs.img ../rock_rootfs-${version}.img
	mv update.img ../${nandImageName}-${version}.img
	cd ..
	rm -rf rockchip-pack-tools
	rm -rf kali-armhf
	rm -rf kali-arm-build-scripts
}

function generateSha1sum {
        echo "generating sha1sum"
        sha1sum $1 > $1.sha1sum
}

function compressImage {
        echo "compress image"
        MACHINE_TYPE=`uname -m`
        if [ ${MACHINE_TYPE} == 'x86_64' ]; then
                pixz ${nandImageName}-${version}.img ${nandImageName}-${version}.img.xz
        else
                echo "Don't pixz on 32bit, there isn't enough memory to compress the images."
        fi
}



##########################################################################################################
# program
##########################################################################################################

if [ ! -d ${tooldir} ]; then
	echo "tools not found. Please run ./getTools.sh first"
	exit 0
fi

if [ ! -f ${bootImgDir}/boot-linux.img ]; then
	echo "boot-linux.img not found. Please check <bootImgDir> in build.cfg!"
	exit 0
fi

if [ ! -f ${bootImgDir}/modules.tar.gz ]; then
	echo "modules and firmware archive: modules.tar.gz not found. Please check <bootImgDir> in build.cfg!"
	exit 0
fi

if [ ! -d ${rootfsdir} ]; then
        # image directory does not exist yet. Create it!
        mkdir ${rootfsdir}
fi

# create the rootfs image, if it doesn't exist yet
if [ ! -f ${rootfsdir}/rock_rootfs-${version}.img ]; then
        cd ${scriptdir}
        ./createKaliRootfs.sh
	setAutoStartX
fi

createNandImg
cleanup
generateSha1sum ${nandImageName}-${version}.img
compressImage
generateSha1sum ${nandImageName}-${version}.img.xz

echo "The kali-nand-image is located at: "${rootfsdir}"/"${nandImageName}"-"${version}".img"

exit
