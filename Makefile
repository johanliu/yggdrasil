all:
	nasm -f bin $(BOOT) -o boot.bin
	nasm -f bin $(USER) -o user.bin
	dd if=boot.bin of=TEST.vhd bs=512 count=1 conv=notrunc
	dd if=user.bin of=TEST.vhd bs=512 seek=100 conv=notrunc
