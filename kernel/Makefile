CC      = gcc
LD      = ld
OBJCOPY = objcopy
NASM    = nasm

CFLAGS  = -m32 -ffreestanding -fno-builtin -fno-stack-protector -nostdlib -Wall -Wextra
LDFLAGS = -m elf_i386 -T linker.ld -nostdlib

all: kernel.bin

main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o

kernel_entry.o: kernel_entry.asm
	$(NASM) -f elf32 kernel_entry.asm -o kernel_entry.o

kernel.elf: kernel_entry.o main.o linker.ld
	$(LD) $(LDFLAGS) -o kernel.elf kernel_entry.o main.o

kernel.bin: kernel.elf
	$(OBJCOPY) -O binary kernel.elf kernel.bin

clean:
	rm -f *.o kernel.elf kernel.bin