# kernel/Makefile

CC = gcc
LD = ld
CFLAGS = -m32 -ffreestanding -fno-builtin -fno-stack-protector -nostdlib -Wall -Wextra -c
LDFLAGS = -m elf_i386 -T linker.ld

SRC = main.c
OBJ = $(SRC:.c=.o)

all: kernel.bin

kernel.bin: $(OBJ) linker.ld
	$(LD) $(LDFLAGS) -o $@ $(OBJ)

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f *.o kernel.bin