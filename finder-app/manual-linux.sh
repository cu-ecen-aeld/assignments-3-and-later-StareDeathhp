export CROSS_COMPILE=aarch64-linux-gnu-

#!/usr/bin/env bash
set -e

# a) Xử lý argument
OUTDIR=${1:-/tmp/aeld}
OUTDIR=$(realpath "$OUTDIR")

# b) Tạo thư mục OUTDIR
mkdir -p "$OUTDIR"

# c) Clone kernel nếu chưa có, checkout đúng tag
if [ ! -d "$OUTDIR/linux" ]; then
  git clone --depth 1 --branch v5.15 \
    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
    "$OUTDIR/linux"
fi

# d) Build kernel ARM64
pushd "$OUTDIR/linux"
make ARCH=arm64 defconfig
make -j$(nproc) ARCH=arm64 Image
popd

# e) Copy Image ra OUTDIR
cp "$OUTDIR/linux/arch/arm64/boot/Image" "$OUTDIR/Image"

# f) Tạo staging rootfs
STAGING="$OUTDIR/rootfs"
rm -rf "$STAGING"
mkdir -p "$STAGING"{/bin,/dev,/proc,/sys,/home}

# f.i) Copy writer (cross-compiled) và scripts, conf
#    - Đảm bảo bạn đã build writer với CROSS_COMPILE trước đó
cp finder-app/writer "$STAGING/home/"
cp finder-app/finder.sh finder-app/conf/username.txt finder-app/conf/assignment.txt finder-app/finder-test.sh "$STAGING/home/"
sed -i 's|\.\./conf/assignment.txt|conf/assignment.txt|' "$STAGING/home/finder-test.sh"
cp finder-app/autorun-qemu.sh "$STAGING/home/"

# g) Tạo device nodes (tty, console)
# h) Create a minimal init at the root of the ramfs
cat > "$STAGING/init" << 'EOF'
#!/bin/sh
# optional: mount các pseudo-filesystems nếu cần
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# chạy autorun script của bạn
exec /home/autorun-qemu.sh
EOF
chmod +x "$STAGING/init"

# h) Đóng gói initramfs
pushd "$STAGING"
find . | cpio --quiet -H newc -o | gzip > "$OUTDIR/initramfs.cpio.gz"
popd

echo "Done: OUTDIR is $OUTDIR"
echo "  - Kernel: $OUTDIR/Image"
echo "  - Initramfs: $OUTDIR/initramfs.cpio.gz"
