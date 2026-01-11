CC32 = riscv32-unknown-elf
CCFLAGS = -march=rv32imf -mabi=ilp32f -O3 -fno-math-errno -T linksc.ld -lm -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -g -ggdb -o AES.elf

build: rom_generator
	$(CC32)-gcc AES_code.c uart.c AES_D.c irq.c crt0.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata -j .sdata AES.elf AES.bin
	./rom_generator AES.bin
	cp AES.data memory_contents
rom_generator:
	gcc ../rom_generator.c -o rom_generator
