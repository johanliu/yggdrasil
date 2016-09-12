; Bootloader

include constant.inc

;===============================================

SECTION mbr align=16 vstart=BOOTSEG

		mov ax, cs
		mov ss, ax
		mov sp, BOOTSEG

	; Setup GDT in real mode, transfer linear address to logical address in reverse
		mov eax, [cs:gdt_base]
		xor edx, edx
		mov ebx, 16 ; >>4
		div ebx

		mov ds, eax       ; Code segment address
		mov ebx, edx      ; Offset in code segment

	; #0 entry of GDT is placeholder
		mov dword [ebx + 0x00], 0x00
		mov dword [ebx + 0x04], 0x00

	; #1 Kernel code segment entry
		mov dword [ebx + 0x08], 0x0000ffff     ; Base = 0, Limit = 0xFFFFF, DPL = 00
		mov dword [ebx + 0x0c], 0x00cf9800     ; 4K Size, Code Segment, UP

	; #2 Kernel data segment and stack segment entry
		mov dword [ebx + 0x10], 0x8000ffff     ; Base = 0, Limit = 0xFFFFF, DPL = 00
		mov dword [ebx + 0x14], 0x00cf9200     ; 4K Size, Data Segment, UP

		mov  word [cs:gdt_size], SIZEOFGDT     ; Save GDT size

		lgdt [cs:gdt_size]

	; Open A20
		in  al, 0x92
		or  al, 0x02
		out 0x92, al

	; Close interrupt in real mode
		cli

	; Open protected mode in cr0
		mov eax, cr0
		or  eax, 1
		mov cr0, eax

	; Jump to protected mode, refresh register and pipeline
		jmp dword 0x0008:flush

	[bits 32]

flush:
	; Load Kernel data segment selector
		mov ecx, 0x0010
		mov ds, ecx
		mov es, ecx
		mov fs, ecx
		mov gs, ecx
		mov ss, ecx

	; Load kernel stack segment selector and offset
		mov esp, 0x7000
		xor ecx, ecx
	
	; TODO
	; Load Kernel into mem

page:
		mov ebx, KERNEL_PDT_PHY_ADDRESS    ; The physical address of kernel PDT

	; Set physical address of PDT to last entry of itself in order to operate later
		mov dword [ebx + 0xFFC], 0x00020003   ; P = 1, RW = 1, US = 0

		mov ebx, 0x00021003     ; The first PT entry used for kernel
		mov dword [ebx + 0x000], edx   ; The lower private address of kernel PT
		mov dword [ebx + 0x800], edx   ; The corresponding global address of kernel PT

	; Now, let's map kernel physical memory address to first PT
		mov ebx, KERNEL_PT_PHY_ADDRESS
		xor eax, eax
		xor esi, esi

.p1:
		mov edx, eax
		or edx, 0x00000003    ; P = 1, RW = 1, US = 0
		mov [ebx + esi * 4], edx     ; Each entry size of PT is 4B, so multiple by 4
		add eax, 0x1000    ; Next physical address is 0xX000 - 0xXFFF, 4K per page
		inc esi
		cmp esi, 256    ; 1024 / 4 = 256
		jl .p1

	; Set first PDBR 
		mov eax, KERNEL_PDT_PHY_ADDRESS    ; PCD = 0, PWD = 0
		mov cr3, eax

	; Reallocate GDT to global private address because we might flush lower private
	; address
		sgdt [gdt_base]
		add dword [gdt_base + 2], 0x80000000 ; lower 2 bytes is limit of gdt, so we ignore it
		lgdt [gdt_base]

	; Adjust stack pointer
		add esp, 0x80000000

	; Open Page functionality
		mov eax, cr0
		or eax, 0x80000000
		mov cr0, eax

		mov cx, message_end - message
		mov bx, message - BOOTSEG

		xor eax, eax
		mov esi, 0x00

	; For display, In order to read from code segment, set TYPE 1010

.display:
		mov  byte al, [cs:bx]
		mov  byte [si], al
		inc  si
		mov  byte [si], 0x07
		inc  si
		inc  bx
		loop .display
	
	; Jump to Kernel main entry
		jmp [KERNEL_START_LINEAR_ADDRESS + 4]

		gdt_size dw 0
		gdt_base dd 0x00008000     ; Allign on 4k page

		message db 'Bootloader successed! Transfer to Kernel!'

message_end:

		times	510 - ($ - $$)	db 0
								dw 0xaa55
