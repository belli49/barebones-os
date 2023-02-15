# Change COMP to the path of the TARGET compiler
COMP := $$HOME/opt/cross/bin
TARGET := i686-elf

CC := $(COMP)/$(TARGET)-gcc
AS := $(COMP)/$(TARGET)-as

# Kernel
CFLAGS := -std=gnu99 -ffreestanding -O2 -Wall -Wextra
OBJS := boot.o kernel.o

# Crts
CRTI_OBJ = crti.o
CRTBEGIN_OBJ := $(shell $(CC) $(CFLAGS) -print-file-name=crtbegin.o)
CRTEND_OBJ := $(shell $(CC) $(CFLAGS) -print-file-name=crtend.o)
CRTN_OBJ = crtn.o

OBJ_LINK_LIST := $(CRTI_OBJ) $(CRTBEGIN_OBJ) $(OBJS) $(CRTEND_OBJ) $(CRTN_OBJ)
INTERNAL_OBJS := $(CRTI_OBJ) $(OBJS) $(CRTN_OBJ)

# targets
all: boot kernel link verify makeiso

cross-compiler-version:
	$(CC) --version

boot: boot.s
	$(AS) boot.s -o boot.o

kernel: kernel.c
	$(CC) -c kernel.c -o kernel.o $(CFLAGS)
	$(AS) crti.s -o crti.o
	$(AS) crtn.s -o crtn.o

link: linker.ld $(OBJ_LINK_LIST)
	$(CC) -T linker.ld -o myos.bin -ffreestanding -O2 $(OBJ_LINK_LIST) -nostdlib -lgcc

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
	rm -rf $(INTERNAL_OBJS) kernel.o myos.bin myos.iso ./isodir
