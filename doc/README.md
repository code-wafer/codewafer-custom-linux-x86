# Custom Minimal Linux OS

This project is a bare-minimal operating system built from scratch for learning purposes.

## Structure
- `boot/` → Bootloader (assembly, runs first)
- `kernel/` → Kernel (C + linker script)
- `scripts/` → Build automation
- `doc/` → Documentation
- `Makefile` → Top-level build system

## Goals
- Understand the boot process (BIOS → bootloader → kernel).
- Write a freestanding kernel in C.
- Learn linker scripts and memory layout.
- Expand step by step: drivers, interrupts, paging, shell.
