# bfloader - Brainfuck made to fit in 512 bytes.

BF_INITIAL_POINTER = 0xF000
BF_SEPARATOR = 0x0E00
BF_INITIAL_OUT = 0x0F00
BF_ABOUT = 0x1800

MAX_ROW = 0x0D
MAX_COL = 0x4F
MAX_CHAR = 0x0D4F

MEMORY_OFFSET = 0xFFD0
MEMORY_CURRENT_POINTER = MEMORY_OFFSET
MEMORY_CURRENT_CHAR = MEMORY_OFFSET + 4
MEMORY_OUT_CHAR = MEMORY_OFFSET + 12
MEMORY_STACK = MEMORY_OFFSET + 16
MEMORY_FLAG_DEBUG = MEMORY_OFFSET + 20

KEY_EXECUTE = 0x3F00   # F5
KEY_DEBUG = 0x6200     # Ctrl+F5
KEY_TERMINATE = 0x2E03 # Ctrl+C

KEY_UP = 0x48
KEY_DOWN = 0x50
KEY_LEFT = 0x4B
KEY_RIGHT = 0x4D

CHAR_POINTER_RIGHT = 0x3E # >
CHAR_POINTER_LEFT = 0x3C  # <
CHAR_INC = 0x2B           # +
CHAR_DEC = 0x2D           # -
CHAR_OUT = 0x2E           # .
CHAR_IN = 0x2C            # ,
CHAR_LOOP_START = 0x5B    # [
CHAR_LOOP_END = 0x5D      # ]

CHAR_BORDER = 0xCD

.code16
.global init

init:
    # Set text mode, 80x25.
    mov $0x0002, %ax
    int $0x10

restart:
    mov $0xF000, %bx

clear_memory:
    movb $0x00, (%bx)
    inc %bx
    cmp $0xF0FF, %bx
    jne clear_memory

restart_cont:
    # Set cursor shape. (Insert style)
    mov $0x01, %ah
    mov $0x000f, %cx
    int $0x10

    # Set cursor position.
    mov $BF_SEPARATOR, %dx
    call set_cursor_pos

    # Print output separator.
    mov $0x09CD, %ax
    mov $0x000F, %bx
    mov $0x0050, %cx
    int $0x10

    # Set cursor position.
    mov $BF_ABOUT, %dx
    call set_cursor_pos

    # Print about background.
    mov $0x0900, %ax
    mov $0x001F, %bx
    mov $0x0050, %cx
    int $0x10

    mov $about, %si
    mov $0x0e, %ah

print_about:
    lodsb
    cmp $0x00, %al
    je restart_finish

    int $0x10
    jmp print_about

restart_finish:
    # Set cursor position.
    xor %dx, %dx
    call set_cursor_pos

    # Initialize
    movb $0x00, (MEMORY_FLAG_DEBUG)
    movw $BF_INITIAL_POINTER, (MEMORY_CURRENT_POINTER)
    movw $BF_INITIAL_OUT, (MEMORY_OUT_CHAR)
    movw $0x0000, (MEMORY_CURRENT_CHAR)
    mov %sp, (MEMORY_STACK)

    jmp keyboard

keyboard:
    # Get pressed key.
    mov $0x01, %ah
    int $0x16

    # Loop again if no key is pressed.
    jz keyboard
    xor %ah, %ah
    int $0x16

    # Start executing if KEY_EXECUTE is pressed.
    cmp $KEY_EXECUTE, %ax
    je execute

    # Start debugging if KEY_DEBUG is pressed.
    cmp $KEY_DEBUG, %ax
    je debug

    # Move cursor
    cmp $KEY_UP, %ah
    je move_up

    # Move cursor
    cmp $KEY_DOWN, %ah
    je move_down

    # Move cursor
    cmp $KEY_LEFT, %ah
    je move_left

    # Move cursor
    cmp $KEY_RIGHT, %ah
    je move_right

    # Print last character.
    mov $0x0e, %ah
    int $0x10

    # Get more keys.
    jmp keyboard

move_prepare:
    # Read cursor position.
    mov $0x03, %ah
    int $0x16
    ret

move_up:
    call move_prepare
    cmp $0x00, %dh
    je keyboard
    dec %dh
    jmp move_finish

move_left:
    call move_prepare
    cmp $0x00, %dl
    je keyboard
    dec %dl
    jmp move_finish

move_right:
    call move_prepare
    cmp $MAX_COL, %dl
    je keyboard
    inc %dl
    jmp move_finish

move_down:
    call move_prepare
    cmp $MAX_ROW, %dh
    je keyboard
    inc %dh

move_finish:
    # Set cursor position.
    call set_cursor_pos
    jmp keyboard

debug:
    movb $0x01, (MEMORY_FLAG_DEBUG)

execute:
    # Set cursor shape. (Default)
    mov $0x01, %ah
    mov $0x0001, %cx
    int $0x10

loop:
    cmpb $0x00, (MEMORY_FLAG_DEBUG)
    jne loop_wait

    # Get pressed key.
    mov $0x01, %ah
    int $0x16
    jz step

loop_wait:
    # Wait for pressed key.
    xor %ah, %ah

loop_should_terminate:
    int $0x16
    
    cmp $KEY_TERMINATE, %ax
    je restart
    
    cmp $KEY_EXECUTE, %ax
    jne step
    movb $0x00, (MEMORY_FLAG_DEBUG)

step:
    # Set cursor position.
    mov (MEMORY_CURRENT_CHAR), %dx
    call set_cursor_pos

    # Read character. (to %al)
    mov $0x08, %ah
    int $0x10

    cmp $CHAR_INC, %al
    je cmd_inc

    cmp $CHAR_DEC, %al
    je cmd_dec

    cmp $CHAR_LOOP_START, %al
    je cmd_loop_start

    cmp $CHAR_LOOP_END, %al
    je cmd_loop_end

    cmp $CHAR_POINTER_LEFT, %al
    je cmd_pointer_left

    cmp $CHAR_POINTER_RIGHT, %al
    je cmd_pointer_right

    cmp $CHAR_OUT, %al
    je cmd_out

    cmp $CHAR_IN, %al
    je cmd_in
    
    # Unsupported character.
    jmp next

cmd_in:
    # Get pressed key.
    mov $0x01, %ah
    int $0x16

    # Loop again if no key is pressed.
    jz cmd_in

    # Read key.
    xor %ah, %ah
    int $0x16

    # Save character.
    mov (MEMORY_CURRENT_POINTER), %bx
    mov %al, (%bx)
    jmp next

cmd_out:
    # Set cursor position.
    mov (MEMORY_OUT_CHAR), %dx
    call set_cursor_pos

    incw (MEMORY_OUT_CHAR)

    # Print last character.
    mov (MEMORY_CURRENT_POINTER), %bx
    mov (%bx), %al
    mov $0x0e, %ah
    int $0x10
    jmp next

cmd_loop_start:
    # Push cursor position to stack.
    pushw (MEMORY_CURRENT_CHAR)
    jmp next

cmd_loop_end:
    # Go to next if nothing on stack.
    cmp (MEMORY_STACK), %sp
    je next

    # Copy stack value to %ax.
    popw %ax
    pushw %ax

    # Go back to loop start if current value is not equal to 0.
    mov (MEMORY_CURRENT_POINTER), %bx
    cmpb $0x00, (%bx)
    jnz cmd_loop_end_back

    # Remove loop from stack otherwise.
    popw %ax
    jmp next

cmd_loop_end_back:
    # Go back to loop start.
    movw %ax, (MEMORY_CURRENT_CHAR)
    jmp next

cmd_pointer_left:
    # Switch current pointer to left.
    decw (MEMORY_CURRENT_POINTER)
    jmp next

cmd_pointer_right:
    # Switch current pointer to right.
    incw (MEMORY_CURRENT_POINTER)
    jmp next
    
cmd_inc:
    # Increment value of current pointer.
    mov (MEMORY_CURRENT_POINTER), %bx
    incb (%bx)
    jmp next

cmd_dec:
    # Decrement value of current pointer.
    mov (MEMORY_CURRENT_POINTER), %bx
    decb (%bx)
    jmp next

next:
    # Increment value of current character.
    incw (MEMORY_CURRENT_CHAR)
    mov (MEMORY_CURRENT_CHAR), %ax

    # Check if it's past the last character (if it is, end program).
    cmpw $MAX_CHAR, %ax
    jg end

    # Check if it's last column, if yes, go to next row.
    cmp $0x50, %al
    je next_row
    jmp loop

next_row:
    xor %al, %al
    inc %ah
    mov %ax, (MEMORY_CURRENT_CHAR)
    jmp loop

end:
    jmp loop_wait

set_cursor_pos:
    mov $0x02, %ah
    xor %bh, %bh
    int $0x10
    ret

about: .asciz "bfloader   F5 Run   Ctrl+F5 Debug"

.fill 510-(.-init), 1, 0
.word 0xaa55
