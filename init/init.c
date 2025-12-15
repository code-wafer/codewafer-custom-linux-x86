
void init(void) {
    volatile unsigned short* vga = (unsigned short*)0xB8000;
    const char* msg = "Hello from init process!";
    int i = 0;
    while (msg[i]) {
        vga[i] = (0x07 << 8) | msg[i];
        i++;
    }
    for (;;) __asm__ __volatile__("hlt");
}