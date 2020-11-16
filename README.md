# bfloader

Boot sector Brainfuck interpreter, fits in 512 bytes.

**This project is optimized for the resulting binary size, not performance.**

## Running in QEMU

```
make && qemu-system-x86_64 bfloader.bin
```
