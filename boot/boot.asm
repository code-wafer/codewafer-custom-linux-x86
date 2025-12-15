; boot.asm — loads the loader from sector 2 and jumps to it
; Assemble: nasm -f bin boot.asm -o build/boot.bin -Ibuild/

[org 0x7C00]
%include "build/defines.inc"

start:
    ; Preserve boot drive (DL) from BIOS
    mov [boot_drive], dl

    ; DS must be sane for lodsb in print_string
    xor ax, ax
    mov ds, ax

    ; Print boot message
    mov si, msg_boot
    call print_string

    ; Reset disk (AH=00)
    xor ah, ah
    mov dl, [boot_drive]
    int 0x13

    ; Read LOADER_SECTORS starting at CHS sector 2 (1=boot)
    xor ax, ax
    mov es, ax
    mov bx, 0x7E00               ; destination for loader

    mov ah, 0x02                 ; BIOS read sectors
    mov al, LOADER_SECTORS
    mov ch, 0                    ; cylinder
    mov dh, 0                    ; head
    mov cl, 2                    ; sector (1-based: 1=boot, 2=loader start)
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; Jump to loader in real mode
    jmp 0x0000:0x7E00

disk_error:
    mov si, msg_disk_error
    call print_string
.halt:
    hlt
    jmp .halt

; BIOS teletype (real mode, DS:SI)
print_string:
    mov ah, 0x0E
.next:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

msg_boot       db "Boot: loading loader...", 0x0D, 0x0A, 0
msg_disk_error db "Disk read error!", 0x0D, 0x0A, 0
boot_drive     db 0

times 510-($-$$) db 0
dw 0xAA55