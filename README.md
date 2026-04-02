# BareMetal-x86

Minimalist x86 assembly environment running directly on hardware. No OS, no layers, just code.

## Current State
- [x] Custom 512-byte bootloader
- [x] Basic I/O via BIOS interrupts
- [x] Multi-app loading (bootloader -> app_a, app_b)
- [x] Interactive command buffer with backspace support
- [x] Box-drawing menu UI
- [ ] Return to bootloader from app (Planned)
- [ ] More apps (Planned)

## Structure
```
├── bootloader.asm  # Main file - the bootloader
├── app_a.asm       # Sector 2 / app A - Guess The Number
├── app_b.asm       # Sector 3 / app B - Show the time
└── Makefile        # Project builder - Makefile
```

## Building
Requires `nasm` and `qemu` for testing.

### Automatically, with Makefile (RECOMMENDED)
```bash
make                # Builds everything and creates disk.img
make run            # Opens it in QEMU
make clean          # Removes all .bin and disk.img
```

### Manually
```bash
nasm -f bin bootloader.asm -o bootloader.bin
nasm -f bin app_a.asm -o app_a.bin
nasm -f bin app_b.asm -o app_b.bin

dd if=/dev/zero of=disk.img bs=512 count=2880
dd if=bootloader.bin of=disk.img bs=512 seek=0 conv=notrunc
dd if=app_a.bin      of=disk.img bs=512 seek=1 conv=notrunc
dd if=app_b.bin      of=disk.img bs=512 seek=2 conv=notrunc

qemu-system-x86_64 -drive format=raw,file=disk.img,index=0,media=disk
```

## Disk layout

| Sektor (BIOS) | dd seek | Obsah        |
|---------------|---------|--------------|
| 1             | 0       | Bootloader   |
| 2             | 1       | App A        |
| 3             | 2       | App B        |

## Notes
- Runs in **real mode** (16-bit), no OS
- All I/O via BIOS interrupts (`int 0x10`, `int 0x13`, `int 0x16`)
- Apps load at address `0x8000`, bootloader jumps there via `jmp 0x8000`
- Boot sector must be exactly 512 bytes ending with `0x55AA`