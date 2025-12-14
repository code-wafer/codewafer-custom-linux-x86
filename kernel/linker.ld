ENTRY(kernelMain)


SECTIONS {
    . = 0x100000;

    .text : AT(0x100000) {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    .data : {
        *(.data*)
    }

    .bss : {
        *(.bss)
        *(COMMON)
    }

    . = ALIGN(4096);
}