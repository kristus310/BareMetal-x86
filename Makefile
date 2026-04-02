all:
	nasm -f bin bootloader.asm -o bootloader.bin
	nasm -f bin app_a.asm     -o app_a.bin
	nasm -f bin app_b.asm     -o app_b.bin

	dd if=/dev/zero of=disk.img bs=512 count=2048

	dd if=bootloader.bin of=disk.img bs=512 seek=0 conv=notrunc
	dd if=app_a.bin     of=disk.img bs=512 seek=1 conv=notrunc
	dd if=app_b.bin     of=disk.img bs=512 seek=2 conv=notrunc

run:
	qemu-system-x86_64 -drive format=raw,file=disk.img