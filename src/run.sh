#!/bin/sh
#python test.py && ../../nesasm/nesasm main.asm && fceux main.nes
#../../nesasm/nesasm -S main.asm  # && fceux main.nes
#../../nesasm/nesasm main.asm && fceux main.nes
../../nesasm/nesasm -l 1 -S main.asm
#../../nesasm/nesasm sprites.asm && fceux sprites.nes
