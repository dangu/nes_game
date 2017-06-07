#!/bin/sh
python test.py && ../../nesasm/nesasm main.asm && fceux main.nes
