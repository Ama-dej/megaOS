#!/bin/bash
avra src/main.asm -o bin/megaOS.hex -I src/
rm src/*.hex src/*.obj
