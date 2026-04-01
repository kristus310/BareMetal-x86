# BareMetal-x86

Minimalist x86 assembly environment running directly on hardware. No OS, no layers, just code.

## Current State
- [x] Custom 512-byte bootloader
- [x] Basic I/O via BIOS interrupts
- [x] Simple command buffer (WIP)
- [ ] Multi-sector loading (Planned)

## Building
Requires `nasm` and `qemu` for testing.

```bash
nasm -f bin bootloader.asm -o output.bin
qemu-system-x86_64 output.bin