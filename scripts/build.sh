#!/bin/bash
# build.sh - Automates building bootloader + kernel + disk image
set -e  # Exit immediately if a command fails

echo "[1] Assembling bootloader..."
nasm -f bin boot/boot.asm -o boot.bin

echo "[2] Building kernel..."
cd kernel
make clean
make
cd ..

echo "[3] Creating disk image..."
# Create a 1.44MB floppy image (2880 sectors × 512 bytes)
dd if=/dev/zero of=disk.img bs=512 count=2880

# Write bootloader to first sector
dd if=boot.bin of=disk.img conv=notrunc

# Write kernel starting at sector 2
dd if=kernel/kernel.bin of=disk.img seek=1 conv=notrunc

echo "[4] Build complete!"
echo "Run with: qemu-system-i386 -hda disk.img"