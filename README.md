# OS project

This project contains a basic "Hello World" OS to test the cross compiler/GRUB boot.

The cross-compiler used was built with gcc 12.2.0 and binutils-2.40.

The following are instructions to build the compiler/cross compiler and to build and run the project (source: OSdev wiki: https://wiki.osdev.org/Creating_an_Operating_System).

## Building the compiler
First download and extract `gcc-12.2.0` and `binutils-2.40` to `$HOME/src/`.
We will then build and bootstrap gcc to build the cross-compiler for the OS.

### Preparation
```sh
export PREFIX="$HOME/opt/gcc-12.2.0"
```

### Binutils
```sh
cd $HOME/src
mkdir build-binutils
cd build-binutils
../binutils-2.40/configure --prefix="$PREFIX" --disable-nls --disable-werror
make -j5
make install
```

Adding -j5 (in case of a 4 core processor) to make uses threads to speed up the process.

### GCC
```sh
cd $HOME/src
 
# In new GCC versions, you can ask gcc to download the prerequisites
cd gcc-12.2.0
./contrib/download_prerequisites
cd $HOME/src # Returning the main src folder
 
mkdir build-gcc
cd build-gcc
../gcc-12.2.0/configure --prefix="$PREFIX" --disable-nls --enable-languages=c,c++
make -j5
make install
```

Then export the compiler to current shell session with
```sh
export PATH="$HOME/opt/gcc-12.2.0/bin:$PATH"
```

## Building the cross-compiler
We will then use the compiler created above to make a cross-compiler using the same GCC and binutils version.
The following assumes that the compiler is located at `$HOME/opt/cross/`, else change the `PREFIX` env variable.

Here, we are compiling to target i686-elf (common x86 architecture).

### Preparation
```sh
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"
```

### Binutils
```sh
cd $HOME/src
 
mkdir build-binutils
cd build-binutils
../binutils-2.40/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
make -j5
make install
```

### GCC
```sh
cd $HOME/src
 
# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
which -- $TARGET-as || echo $TARGET-as is not in the PATH
 
mkdir build-gcc
cd build-gcc
../gcc-12.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
make all-gcc
make all-target-libgcc
make install-gcc
make install-target-libgcc
```

Then, add to current shell session with
```sh
export PATH="$HOME/opt/cross/bin:$PATH"
```

## Buiding the OS iso
After creating the kernel.c, boot.s and linker.ld files, we can build the ISO of the OS.
To do this, we can simply change the `COMP` variable to the path of our i686-elf-gcc 12.2.0 compiler in the Makefile and run `make all`.o

Alternatively, follow the next steps.

### Kernel entry point
Here, we are using GRUB to boot the OS.
To assemble the boot.s use

```sh
i686-elf-as boot.s -o boot.o
```

### Kernel
To compile the kernel, use

```sh
i686-elf-gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
```

### Linking kernel
To link the kernel, use

```sh
i686-elf-gcc -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc
```

Notice here that we do not have access to the stdlib (hence, we use the option -nostdlib).
But the compiler still needs libgcc, so we have to add -lgcc for it to compile properly.

### Verifying Multiboot and booting the kernel
Use GRUB to check if the header is correct with

```sh
grub-file --is-x86-multiboot myos.bin
```

and check exit status with `echo $?` to see if it exited with return value 0.

If everything is correct, to boot the kernel, create a `grub.cfg` file with

```sh
menuentry "myos" {
	multiboot /boot/myos.bin
}
```

and use the following commands:

```sh
mkdir -p isodir/boot/grub
cp myos.bin isodir/boot/myos.bin
cp grub.cfg isodir/boot/grub/grub.cfg
grub-mkrescue -o myos.iso isodir
```

With this, we get and ISO file with the OS.
We can boot it in a VM using qemu with

```sh
qemu-system-i386 -cdrom myos.iso
```

To boot it in real hardware, we can just install the ISO (e.g. in a USB stick).
