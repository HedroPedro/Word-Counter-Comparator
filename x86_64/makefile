AS=nasm
ASFLAGS=-felf64
LD=ld

.PHONY: all clean

all: main

main: main.o
	$(LD) -o $@ $^

main.o: main.asm
	$(AS) $(ASFLAGS) -o $@ $^

clean:
	rm -rf main.o main
