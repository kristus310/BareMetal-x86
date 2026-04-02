BINS = bootloader.bin app_a.bin app_b.bin

all: disk.img

disk.img: $(BINS)
	dd if=/dev/zero of=disk.img bs=512 count=2880
	dd if=bootloader.bin of=disk.img bs=512 seek=0 conv=notrunc
	dd if=app_a.bin      of=disk.img bs=512 seek=1 conv=notrunc
	dd if=app_b.bin      of=disk.img bs=512 seek=2 conv=notrunc

%.bin: %.asm
	nasm -f bin $< -o $@

run: disk.img
	qemu-system-x86_64 -drive format=raw,file=disk.img,index=0,media=disk

clean:
	rm -f $(BINS) disk.img

.PHONY: all run clean