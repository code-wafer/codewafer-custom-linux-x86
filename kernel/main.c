// main.c — minimal kernel console that continues from BIOS cursor and launches init
// Compile: gcc -m32 -ffreestanding -fno-pie -O2 -c main.c -o build/main.o

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEM ((volatile unsigned short*)0xB8000)

static int cur_row = 0;
static int cur_col = 0;

/* Inline port I/O (no headers) */
static inline unsigned char inb(unsigned short port) {
    unsigned char ret;
    __asm__ __volatile__("inb %1, %0" : "=a"(ret) : "d"(port));
    return ret;
}

static inline void outb(unsigned short port, unsigned char val) {
    __asm__ __volatile__("outb %0, %1" : : "a"(val), "d"(port));
}

/* Read BIOS hardware cursor to initialize row/col */
static void init_cursor(void) {
    unsigned short pos;
    outb(0x3D4, 0x0F);
    pos = inb(0x3D5);
    outb(0x3D4, 0x0E);
    pos |= ((unsigned short)inb(0x3D5)) << 8;
    cur_row = pos / VGA_WIDTH;
    cur_col = pos % VGA_WIDTH;
}

/* Update hardware cursor to match cur_row/cur_col */
static void update_hw_cursor(void) {
    unsigned short pos = (unsigned short)(cur_row * VGA_WIDTH + cur_col);
    outb(0x3D4, 0x0F);
    outb(0x3D5, (unsigned char)(pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (unsigned char)((pos >> 8) & 0xFF));
}

/* Print one character */
static void putc(char c) {
    if (c == '\n') { cur_row++; cur_col = 0; update_hw_cursor(); return; }
    if (c == '\r') { cur_col = 0; update_hw_cursor(); return; }

    if (cur_row >= VGA_HEIGHT) cur_row = VGA_HEIGHT - 1;

    int idx = cur_row * VGA_WIDTH + cur_col;
    VGA_MEM[idx] = (unsigned short)((0x07 << 8) | (unsigned char)c);

    if (++cur_col >= VGA_WIDTH) { cur_col = 0; cur_row++; }
    update_hw_cursor();
}

/* Print a string */
static void print_string(const char *s) {
    while (*s) putc(*s++);
}

/* Loader-provided disk read (LBA) */
//extern void read_sector(unsigned short lba, unsigned char* buf);

/* Kernel entry point */
void kmain(void) {
    init_cursor();  // continue from BIOS cursor

    print_string("Welcome to custom minimal kernel\n");
    print_string("Kernel: started successfully\n");
    print_string("Kernel: initializing subsystems...\n");

    // Load and run init (hard-coded minimal approach)
    init_cursor();  // refresh from current hardware cursor
    print_string("Kernel: loading init...\n");

    unsigned char* load_addr = (unsigned char*)0x20000;
    //read_sector(52, load_addr);  // init.bin placed at sector 52

    print_string("Kernel: jumping to init...\n");
    void (*init_entry)(void) = (void(*)(void))load_addr;
    init_entry();

    // If init ever returns, halt forever
    for (;;) __asm__ __volatile__("hlt");
}