# bfloader

Boot sector Brainfuck interpreter, fits in 512 bytes.

**This project is optimized for the resulting binary size, not performance.**

## Running in QEMU

```
make && qemu-system-x86_64 bfloader.bin
```

## Usage

After running, type in your Brainfuck program using your keyboard and press Enter to execute it.
The output will be shown in the lower half of your screen.

Currently there is no way to stop the execution without rebooting the computer/virtual machine.
