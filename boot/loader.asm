; loader.asm — reads kernel (LBA if available, else CHS), switches to PM, jumps to 0x001000
; Assemble: nasm -f bin boot/loader.asm -o build/loader.bin -Ibuild/
; Requires defines.inc: LOADER_SECTORS, KERNEL_START (LBA of kernel), KERNEL_SECTORS

[org 0x7E00]
%include "build/defines.inc"

; ------------------------------------------------
; Real mode loader
; ------------------------------------------------
start:
    ; Ensure DS is sane for lodsb in print_string
    xor ax, ax
    mov ds, ax

    ; Save boot drive from BIOS (DL)
    mov [boot_drive], dl

    ; Loader message
    mov si, msg_loader
    call print_string

    ; Reset disk (AH=00)
    xor ah, ah
    mov dl, [boot_drive]
    int 0x13

    ; Destination buffer for kernel: ES:BX = 0000:1000 (phys 0x001000)
    xor ax, ax
    mov es, ax
    mov bx, 0x1000

    ; Detect INT 13h extensions (AH=41h)
    mov ah, 0x41
    mov bx, 0x55AA
    mov dl, [boot_drive]
    int 0x13
    jc use_chs
    cmp bx, 0xAA55
    jne use_chs

    ; ---------------------------
    ; LBA path (AH=42h)
    ; ---------------------------
    mov si, msg_lba
    call print_string

    ; DAP must be 16 bytes and referenced via DS:SI
dap:
    db 0x10, 0x00                 ; size=16, reserved=0
    dw KERNEL_SECTORS             ; number of sectors to read
    dw 0x1000                     ; buffer offset
    dw 0x0000                     ; buffer segment
    dd KERNEL_START               ; starting LBA (low dword)
    dd 0                          ; starting LBA (high dword)

    ; Point DS:SI to DAP
    xor ax, ax
    mov ds, ax
    mov si, dap

    ; Optional reset, then extended read AH=42h
    xor ah, ah
    mov dl, [boot_drive]
    int 0x13

    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    jmp after_read

use_chs:
    ; ---------------------------
    ; CHS path (AH=02h)
    ; ---------------------------
    mov si, msg_chs
    call print_string

read_kernel_chs:
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov dh, 0
    mov cl, KERNEL_START + 1      ; CHS sectors are 1-based
    mov dl, [boot_drive]
    int 0x13
    jnc after_read

    ; On error: reset and retry
    xor ah, ah
    int 0x13
    mov si, msg_retry
    call print_string
    jmp read_kernel_chs

after_read:
    ; Enable A20 via port 0x92
    in al, 0x92
    or al, 0x02
    out 0x92, al

    ; Setup flat GDT and enter protected mode
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x01                  ; set PE
    mov cr0, eax
    jmp 0x08:pm_entry             ; far jump loads CS

; ------------------------------------------------
; Protected mode: 32-bit code
; ------------------------------------------------
pm_entry:
    [bits 32]

    ; Flat segments: data selectors = 0x10
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    ; Stack
    mov esp, 0x9000

    ; Hand off to kernel entry at linear 0x001000
    mov eax, 0x001000
    jmp eax

disk_error:
    mov si, msg_disk_error
    call print_string
.halt:
    hlt
    jmp .halt

; ------------------------------------------------
; BIOS teletype string printer (real mode, DS:SI)
; ------------------------------------------------
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

; ------------------------------------------------
; Data
; ------------------------------------------------
msg_loader     db "Loader: loading kernel...", 0x0D, 0x0A, 0
msg_lba        db "Using LBA read...", 0x0D, 0x0A, 0
msg_chs        db "Using CHS read...", 0x0D, 0x0A, 0
msg_retry      db "Retrying disk read...", 0x0D, 0x0A, 0
msg_disk_error db "Disk read error!", 0x0D, 0x0A, 0
boot_drive     db 0

; ------------------------------------------------
; GDT: flat 0..4GiB code/data
; ------------------------------------------------
gdt:
    dq 0x0000000000000000            ; null
    dq 0x00cf9a000000ffff            ; code: base=0, limit=0xFFFFF, flags=0x9A, gran=1, 32-bit
    dq 0x00cf92000000ffff            ; data: base=0, limit=0xFFFFF, flags=0x92, gran=1, 32-bit

gdt_descriptor:
    dw gdt_end - gdt - 1
    dd gdt
gdt_end: