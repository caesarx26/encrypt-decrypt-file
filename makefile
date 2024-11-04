OBJS    = blowfish.o procs.o
ASM     = yasm -g dwarf2 -f elf64
CC      = g++ -g -std=c++11

all: blowfish

blowfish.o: blowfish.cpp
	$(CC) -c blowfish.cpp

procs.o: procs.asm
	$(ASM) procs.asm -l procs.lst

blowfish: $(OBJS)
	$(CC) -no-pie -o blowfish $(OBJS) -lcrypto++

# -----
# clean by removing object files.

clean:
	rm $(OBJS)
	rm procs.lst
	rm blowfish
