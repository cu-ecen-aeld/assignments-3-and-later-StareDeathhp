#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p "${OUTDIR}" || { echo "Failed to create directory ${OUTDIR}"; exit 1; }            #fail script if a error happens.


cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    # Clean up the kernel source tree
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

    # Prepare the default config for ARM64
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

    echo "Build the kernel image and modules (we'll skip modules_install)"
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all

    echo "Build Device Tree Blobs (DTBs)"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs


fi
# read -p "Press Enter to continue..."            #Added but plan to remove.

cd ${OUTDIR}/linux-stable
echo "Adding the Image in outdir"
# Copy output files (Image and dtbs) to OUTDIR
cp arch/${ARCH}/boot/Image ${OUTDIR}/
# cd ${OUTDIR}/linux-stable
# cp arch/${ARCH}/boot/dts/*.dtb ${OUTDIR}/
find arch/${ARCH}/boot/dts -name "*.dtb" -exec cp {} ${OUTDIR}/ \;


echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs/{bin,dev,etc,lib,proc,sbin,tmp,var,/usr,/usr/sbin,home}

# QEMU_AUDIO_DRV=none qemu-system-arm -m 256M -nographic -M versatilepb -kernel ${OUTDIR}/Image


# read -p "Press Enter to continue..."        #Added but plan to remove.

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig

else
    cd busybox
fi
#Added libraries since this part is complaing that busy box does not have libs
# Add shared libraries required by busybox
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

# Create lib and lib64 directories
mkdir -p ${OUTDIR}/rootfs/lib
mkdir -p ${OUTDIR}/rootfs/lib64
mkdir -p ${OUTDIR}/rootfs/etc/init.d    #added for kernel
mkdir -p ${OUTDIR}/rootfs/{dev,proc,sys,tmp,mnt,run}


cat <<EOF > ${OUTDIR}/rootfs/etc/init.d/rcS
#!/bin/sh
echo "Boot script running..."
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs tmpfs /tmp
EOF
chmod +x ${OUTDIR}/rootfs/etc/init.d/rcS
    #end of add

# Copy required libraries and dynamic linker
cp -a ${SYSROOT}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/
cp -a ${SYSROOT}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp -a ${SYSROOT}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
cp -a ${SYSROOT}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/

# read -p "Press Enter to continue..."            #Added but plan to remove.


# TODO: Make and install busybox
make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"
# read -p "Press Enter to continue... after lib depend"            #Added but plan to remove.
if [ ! -f "${OUTDIR}/rootfs/bin/busybox" ]; then
  echo "❌ Error: BusyBox binary not found at ${OUTDIR}/rootfs/bin/busybox"
  exit 1
fi


# TODO: Add library dependencies to rootfs
# Step 1: Get shared libraries using readelf
# ${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library" | awk '{print $3}' | while read lib; do
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | \
grep 'Shared library:' | \
grep -o '\[.*\]' | tr -d '[]' | \
while read lib; do                                                  #Awk was reading the word "shared" this was added to try to find the actual library name.
    # Step 2: Check if the library exists on the host system
    lib_path=$(find /lib /usr/lib -name "$lib" 2>/dev/null)
    # read -p "Press Enter to continue..."            #Added but plan to remove.
    if [ -n "$lib_path" ]; then
        # Step 3: Copy the library to rootfs/lib
        echo "Copying $lib to ${OUTDIR}/rootfs/lib/"
        cp $lib_path ${OUTDIR}/rootfs/lib/
        # read -p "Press Enter to continue..."            #Added but plan to remove.
        # I want to add the librarys so im trying this way of using AArch64 specific libraries
        

    else
        echo "Library $lib not found!"
    fi
done


# TODO: Make device nodes
sudo mknod ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod ${OUTDIR}/rootfs/dev/console c 5 1
#added because of tty not found
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/tty2 c 4 2
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/tty3 c 4 3
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/tty4 c 4 4


# TODO: Clean and build the writer utility
# Cross-compile the writer application
${CROSS_COMPILE}gcc -o ${OUTDIR}/rootfs/home/writer ${FINDER_APP_DIR}/writer.c

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
# Copy the finder related scripts and executables to /home on the target rootfs
echo "Copying finder related scripts and executables to /home"
cp ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/conf/username.txt ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/conf/assignment.txt ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/



# TODO: Chown the root directory
cd ${OUTDIR}/rootfs/
# sudo chown -R root:root *
sudo chown -R root:root .


# TODO: Create initramfs.cpio.gz
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio" || {
    echo "❌ Failed to create initramfs.cpio"
    exit 1
}
echo "Compressing initramfs.cpio"
gzip -f "${OUTDIR}/initramfs.cpio"
# read -p "Press Enter to continue..."            #Added but plan to remove.

# #added and keeping, it seem to be the right step
# QEMU_AUDIO_DRV=none qemu-system-aarch64 \
#   -machine virt \
#   -cpu cortex-a53 \
#   -m 512M \
#   -nographic \
#   -kernel ${OUTDIR}/Image \
#   -initrd ${OUTDIR}/initramfs.cpio.gz \
#   -append "console=ttyAMA0 root=/dev/ram rdinit=/sbin/init"
