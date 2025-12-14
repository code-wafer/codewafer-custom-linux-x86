; boot.asm - minimal bootloader
bits 16         ; 16-bit real mode
org 0x7C00      ; BIOS loads Boot Sector from here


strat :
    cli         ; diable interrupt flag - disable h/w interrupts
    mov si, msg ; load the msg address into si register
    call print  ; call print routine to diplay the msg
    hlt         ; halt cpu - stop exicution (infinite sleep)

print :
    lodsb       ; load byte SI into AL, then increment SI
    or al, al   ; check if al == 0 (null terminator)
    jz done     ; if zero jump to done
    mov ah, 0x0E; BIOS teletype function (int 0X10, ah=0x0E) - prints the character in  at the current cursor position and advances the cursor.
    int 0X10    ; print charcter AL to screen - provide the video services
    jmp print   ; repeat untill condition hit (al == 0)

done :
    ret         ; return from print


msg db 'Bootloader: loading kernel...', 0

times 510 - ($ - $$) db 0       ; Boot section must be exactly 512 bytes

; where $ - current location counter
; $$ - start of the section
; $ - $$ how many bytes we written so far
; 510 - ($ -$$) how many left untill offset 510
; db 0 where remaining bytes are zero
; this ensures the bootloader is correct size

dw 0xAA55       ; last 2 bytes of valid boot sector must be 0xAA55 (littel endian)

; BIOS check this signature to decides if the sector is bootable
