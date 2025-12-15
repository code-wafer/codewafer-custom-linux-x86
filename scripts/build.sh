#!/bin/bash
set -e
mkdir -p build

echo "[1] Building kernel..."
make -C kernel clean && make -C kernel
cp kernel/kernel.bin build/kernel.bin

echo "[2] Building init process..."
# compile init/init.c into a flat binary
gcc -m32 -ffreestanding -fno-pie -c init/init.c -o build/init.o
ld -m elf_i386 -nostdlib -Ttext 0x20000 -o build/init.elf build/init.o
objcopy -O binary build/init.elf build/init.bin


echo "[3] First-pass loader (dummy header)..."
cat > build/defines.inc <<EOF
%define LOADER_SECTORS 0
%define KERNEL_START 0
%define KERNEL_SECTORS 0
%define KERNEL_BYTES 0
EOF
nasm -f bin boot/loader.asm -o build/loader.bin -Ibuild/

echo "[4] Generating defines.inc..."
LOADER_SECTORS=$(( ( $(stat -c%s build/loader.bin) + 511 ) / 512 ))
KERNEL_SECTORS=$(( ( $(stat -c%s build/kernel.bin) + 511 ) / 512 ))
KERNEL_START=$((1 + LOADER_SECTORS))        # kernel placed right after loader
KERNEL_BYTES=$(( KERNEL_SECTORS * 512 ))

cat > build/defines.inc <<EOF
%define LOADER_SECTORS $LOADER_SECTORS
%define KERNEL_START $KERNEL_START
%define KERNEL_SECTORS $KERNEL_SECTORS
%define KERNEL_BYTES $KERNEL_BYTES
EOF

echo "[5] Assembling boot + loader with header..."
nasm -f bin boot/boot.asm   -o build/boot.bin   -Ibuild/
nasm -f bin boot/loader.asm -o build/loader.bin -Ibuild/

echo "[6] Creating disk image..."
dd if=/dev/zero of=build/disk.img bs=512 count=2880
dd if=build/boot.bin   of=build/disk.img bs=512 seek=0 conv=notrunc
dd if=build/loader.bin of=build/disk.img bs=512 seek=1 conv=notrunc
dd if=build/kernel.bin of=build/disk.img bs=512 seek=$KERNEL_START conv=notrunc

echo "[7] Build complete!"
echo "Run: qemu-system-i386 -drive format=raw,file=build/disk.img -serial stdio"