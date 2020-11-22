# bfloader - Brainfuck made to fit in 512 bytes.
#
# Reserved registers:
# BP = debug flag (Ctrl+F5)
# DI = current pointer
# SI = current char

MAX_ROW = 0x15
MAX_COL = 0x4F
MAX_CHAR = 0x154F

BF_INITIAL_POINTER = 0xF000
BF_SEPARATOR = (MAX_ROW + 1) * 0x100
BF_INITIAL_OUT = BF_SEPARATOR + 0x100
BF_ABOUT = BF_INITIAL_OUT + 0x100

MAX_OUT_CHAR = BF_INITIAL_OUT + MAX_COL

MEMORY_OFFSET = 0xFFD0
MEMORY_OUT_CHAR = MEMORY_OFFSET

KEY_EXECUTE = 0x3F00   # F5
KEY_DEBUG = 0x6200     # Ctrl+F5
KEY_TERMINATE = 0x2E03 # Ctrl+C

KEY_UP = 0x48
KEY_DOWN = 0x50
KEY_LEFT = 0x4B
KEY_RIGHT = 0x4D
KEY_BACKSPACE = 0x08
KEY_HOME = 0x47
KEY_END = 0x4F

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
    # Set cursor shape. (Insert style)
    mov $0x01, %ah
    mov $0x000f, %cx
    int $0x10

    # Set cursor position.
    mov $BF_SEPARATOR, %dx
    call set_cursor_pos

    # Clear output.
    mov $0x0900, %ax
    mov $0x000F, %bx
    mov $0x06FF, %cx
    int $0x10

    # Print output separator.
    mov $0xCD, %al
    mov $0x0050, %cx
    int $0x10

    # Clear memory.
    mov $BF_INITIAL_POINTER, %bx

clear_memory:
    movb %ch, (%bx)
    inc %bx
    cmp $0xF0FF, %bx
    jne clear_memory

restart_cont:
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
    test %al, %al
    jz restart_finish

    int $0x10
    jmp print_about

restart_finish:
    # Set cursor position.
    xor %dx, %dx
    call set_cursor_pos

    # Initialize
    xor %bp, %bp # BP = debug flag
    movw $BF_INITIAL_POINTER, %di # DI = current pointer
    movw $BF_INITIAL_OUT, (MEMORY_OUT_CHAR)
    xor %si, %si # SI = current char
    push $-1

    jmp keyboard

keyboard:
    # Read cursor position.
    mov $0x03, %ah
    int $0x16

    xor %ah, %ah
    int $0x16

    # Start executing if KEY_EXECUTE is pressed.
    cmp $KEY_EXECUTE, %ax
    je execute

    # Start debugging if KEY_DEBUG is pressed.
    cmp $KEY_DEBUG, %ax
    je debug

    # Move cursor
    cmp $KEY_HOME, %ah
    je move_first

    # Move cursor
    cmp $KEY_END, %ah
    je move_last

    # Move cursor
    cmp $KEY_UP, %ah
    je move_up

    # Move cursor
    cmp $KEY_DOWN, %ah
    je move_down

    # Move cursor
    cmp $KEY_LEFT, %ah
    je move_prev

    # Handle backspace
    cmp $KEY_BACKSPACE, %al
    je move_prev

    # Move cursor
    cmp $KEY_RIGHT, %ah
    je move_next

    # Print last character.
    mov $0x09, %ah
    mov $0x0007, %bx
    mov $0x0001, %cx
    int $0x10

    jmp move_next

    # Get more keys.
    jmp keyboard

move_first:
    xor %dl, %dl
    jmp move_finish

move_last:
    mov $MAX_COL, %dl
    jmp move_finish

move_next:
    cmp $MAX_COL, %dl
    je move_next_line
    inc %dl
    jmp move_finish

move_next_line:
    cmp $MAX_ROW, %dh
    je keyboard
    xor %dl, %dl
    inc %dh
    jmp move_finish

move_prev:
    test %dl, %dl
    jz move_prev_line
    dec %dl
    jmp move_finish

move_prev_line:
    test %dh, %dh
    jz keyboard
    mov $MAX_COL, %dl
    dec %dh
    jmp move_finish

move_up:
    test %dh, %dh
    jz keyboard
    dec %dh
    jmp move_finish

move_down:
    cmp $MAX_ROW, %dh
    je keyboard
    inc %dh

move_finish:
    # Set cursor position.
    call set_cursor_pos
    jmp keyboard

debug:
    inc %bp # BP = debug flag

execute:
    # Set cursor shape. (Default)
    mov $0x01, %ah
    mov $0x0001, %cx
    int $0x10

loop:
    test %bp, %bp # BP = debug flag
    jnz loop_wait

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
    xor %bp, %bp # BP = debug flag

step:
    # Set cursor position.
    mov %si, %dx # SI = current char
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
    # Read key.
    xor %ah, %ah
    int $0x16
    
    cmp $KEY_TERMINATE, %ax
    je restart

    # Save character.
    mov %al, (%di) # DI = current pointer
    jmp next

cmd_out:
    # Set cursor position.
    mov (MEMORY_OUT_CHAR), %dx
    call set_cursor_pos

    # Print last character.
    mov (%di), %al
    mov $0x0e, %ah
    int $0x10

    cmpw $MAX_OUT_CHAR, (MEMORY_OUT_CHAR)
    je reset_out_char

    incw (MEMORY_OUT_CHAR)

    jmp next

reset_out_char:
    movw $BF_INITIAL_OUT, (MEMORY_OUT_CHAR)
    mov (MEMORY_OUT_CHAR), %dx
    call set_cursor_pos

    jmp next

cmd_loop_start:
    # Push cursor position to stack.
    push %si # SI = current char
    jmp next

cmd_loop_end:
    # Copy stack value to %ax.
    pop %ax
    push %ax

    # Go back to loop start if current value is not equal to 0.
    mov (%di), %bx # DI = current pointer
    test %bl, %bl
    jnz cmd_loop_end_back

    # Remove loop from stack otherwise.
    pop %ax
    jmp next

cmd_loop_end_back:
    # Go back to loop start.
    mov %ax, %si # SI = current char
    jmp next

cmd_pointer_left:
    # Switch current pointer to left.
    dec %di # DI = current pointer
    jmp next

cmd_pointer_right:
    # Switch current pointer to right.
    inc %di # DI = current pointer
    jmp next
    
cmd_inc:
    # Increment value of current pointer.
    incb (%di) # DI = current pointer
    jmp next

cmd_dec:
    # Decrement value of current pointer.
    decb (%di) # DI = current pointer

next:
    # Increment value of current character.
    inc %si # SI = current char
    mov %si, %ax # SI = current char

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
    mov %ax, %si # SI = current char
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
