.PHONY: all clean run

all: image

image:
	./scripts/build.sh

run:
	qemu-system-i386 -drive format=raw,file=disk.img

clean:
	$(MAKE) -C kernel clean
	rm -f boot.bin disk.img