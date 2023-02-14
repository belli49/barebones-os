TARGET := i686-elf
# Change COMP to the path of the TARGET compiler
COMP := $$HOME/opt/cross/bin

all: boot kernel link verify makeiso

cross-compiler:
	$(COMP)/$(TARGET)-gcc --version

boot: boot.s
	$(COMP)/$(TARGET)-as boot.s -o boot.o

kernel: kernel.c
	$(COMP)/$(TARGET)-gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

link: boot.o kernel.o linker.ld
	$(COMP)/$(TARGET)-gcc -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc

verify: myos.bin
	grub-file --is-x86-multiboot myos.bin

makeiso: myos.bin
	mkdir -p isodir/boot/grub
	cp myos.bin isodir/boot/myos.bin
	cp grub.cfg isodir/boot/grub/grub.cfg
	grub-mkrescue -o myos.iso isodir

run: myos.iso
	qemu-system-i386 -cdrom myos.iso

clean:
	rm -rf boot.o kernel.o myos.bin myos.iso ./isodir
