	BOOTSEG  equ 0x7c00
	GDTLIMIT equ 31

	SECTION mbr align=16 vstart=BOOTSEG

	mov ax, cs
	mov ss, ax
	mov sp, BOOTSEG

	;   Setup GDT in real mode, transfer linear address to logical address
	mov ax, [cs:gdt_base]
	mov dx, [cs:gdt_base + 0x02]
	mov bx, 16; >>4
	div bx
	mov ds, ax
	mov bx, dx

	;   First entry of GDT is null
	mov dword [bx + 0x00], 0x00
	mov dword [bx + 0x04], 0x00

	;   Kernel code segment entry
	mov dword [bx + 0x08], 0x7c0001ff
	;   mov dword [bx + 0x0c], 0x00409800
	mov dword [bx + 0x0c], 0x00409a00

	;   Kernel data segment entry, Display memory for TEST only
	mov dword [bx + 0x10], 0x8000ffff
	mov dword [bx + 0x14], 0x0040920b

	;   Kernel stack segment entry
	mov dword [bx + 0x18], 0x00007a00
	mov dword [bx + 0x1c], 0x00409600

	mov  word [cs:gdt_size], GDTLIMIT
	lgdt [cs:gdt_size]

	;   Open A20
	in  al, 0x92
	or  al, 0x02
	out 0x92, al

	; Close interrupt in real mode
	cli

	;   Open protected mode
	mov eax, cr0
	or  eax, 1
	mov cr0, eax

	;   Jump to protected mode, refresh register and pipeline
	jmp dword 0x0008:flush - BOOTSEG

[bits 32]

flush:
	;   Get Kernel data entry
	mov cx, 0x0010
	mov ds, cx
	xor cx, cx

	mov cx, message_end - message
	mov bx, message - BOOTSEG

	xor ax, ax
	mov si, 0x00

	; For display, In order to read from code segment, set TYPE 1010

.display:
	mov  byte al, [cs:bx]
	mov  byte [si], al
	inc  si
	mov  byte [si], 0x07
	inc  si
	inc  bx
	loop .display

	; Halt the computer
	hlt

	gdt_size dw 0
	gdt_base dd 0x00007e00

	message db 'Hello, Protected Mode!'

message_end:

	times 510 - ($ - $$) db 0
	dw    0xaa55
