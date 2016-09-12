BOOTSEG equ 0x7c00
SIZEOFGDT equ 23
KERNEL_PHY_ADDRESS equ 0x00040000      ; The physical memory address of kernel
KERNEL_SECTOR equ 0x00000001           ; The sector number of kernel on hard disk
KERNEL_PDT_PHY_ADDRESS equ 0x00020000      ; The physical memory address pf kernel PDT
KERNEL_PT_PHY_ADDRESS equ 0x00021000
KERNEL_START_LINEAR_ADDRESS equ 0x80040000
