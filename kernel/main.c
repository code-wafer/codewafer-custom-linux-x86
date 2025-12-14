void clear_screen() {
    unsigned short * video_memory = (unsigned short*) 0xb8000;
    for(int i=0; i<80*25*2 ; i+=2) {
        video_memory[i] = ' ';
        video_memory[i+1] = 0x07;
    }
}


void print_string(const char *str) {

    unsigned short* video_memory = (unsigned short*) 0xb8000;
    for(int i=0; str[i] != '\0'; ++i) {
        video_memory[i] = (video_memory[i] & 0xFF00) | str[i];
    }
}

void kernelMain() {
    //clear_screen();
    print_string("Welcome to custom minmal kernel");
    print_string("Kernel: started successfully\n");
    print_string("Kernel: initializing subsystems...\n");
    while(1);
}
