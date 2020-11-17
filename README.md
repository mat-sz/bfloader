# bfloader

Boot sector Brainfuck interpreter, fits in 512 bytes.

**This project is optimized for the resulting binary size, not performance.**

## Running in QEMU

```
make && qemu-system-x86_64 bfloader.bin
```

## Usage

After running, type in your Brainfuck program using your keyboard and press <kbd>F5</kbd> to execute it (or <kbd>Ctrl</kbd> + <kbd>F5</kbd> to start step by step execution).
The output will be shown in the lower half of your screen.

To stop the execution hold <kbd>Ctrl</kbd> + <kbd>C</kbd>. While debugging press <kbd>F5</kbd> to continue the program from the current step until the end.
