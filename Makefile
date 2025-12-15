.PHONY: all clean run

all: image

image:
	./scripts/build.sh

run:
	qemu-system-i386 -drive format=raw,file=build/disk.img

clean:
	$(MAKE) -C kernel clean
	rm -f *.bin disk.img