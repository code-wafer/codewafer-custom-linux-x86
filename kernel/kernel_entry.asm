; Assemble: nasm -f elf32 kernel_entry.asm -o build/kernel_entry.o

[bits 32]
global _start
extern kmain

_start:
    ; Flat segments (assumes loader installed GDT: code=0x08, data=0x10)
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    ; Mask hardware interrupts to avoid unexpected IRQs (optional but safe)
    ; PIC: mask all
    mov al, 0xFF
    out 0x21, al
    out 0xA1, al

    ; Disable interrupts in CPU
    cli

    ; Safe stack for C
    mov esp, 0x80000

    ; Jump into C
    call kmain

.halt:
    cli
    hlt
    jmp .halt