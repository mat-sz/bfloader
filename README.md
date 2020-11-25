# bfloader

<p align="center">
  <a href="https://demo.matsz.dev/bfloader/">
    <strong>Click here to open an online demo.</strong>
  </a>
</p>

<p align="center">
  <a href="https://demo.matsz.dev/bfloader/">
    <img src="https://raw.githubusercontent.com/mat-sz/bfloader/master/screenshot.png" alt="Screenshot">
  </a>
</p>

Boot sector [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck) IDE and interpreter, fits in 512 bytes.

**This project is optimized for the resulting binary size, not performance.**

You can download prebuilt binaries [here](https://github.com/mat-sz/bfloader/releases).

## Running in QEMU

```
make && qemu-system-x86_64 bfloader.bin
```

## Usage

After running, type in your Brainfuck program using your keyboard (use arrow keys and Home/End keys to move the cursor) and press <kbd>F5</kbd> to execute it (or <kbd>Ctrl</kbd> + <kbd>F5</kbd> to start step by step execution).
The output will be shown in between the separator and the blue line.

To stop the execution or to reset after completed execution hold <kbd>Ctrl</kbd> + <kbd>C</kbd>. While debugging press <kbd>F5</kbd> to continue the program from the current step until the end.

## Limitations

- Program length is limited to 21 lines of 80 columns each (1680 characters).
- Each cell is 1 byte long. (256 different values, wrapping).
- Program memory space starts at 0xF000. It is possible to overwrite memory segments that shouldn't be overwritten.
- Program's output is limited to 1 line of 80 columns (80 characters).
- The editor isn't very advanced.
