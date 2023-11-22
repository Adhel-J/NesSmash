# NesSmash

To run the game, run the NESmash.nes ROM with your favorite NES emulator

to compile the code, run "ca65 src/"filename".asm" on each modified file

after that, run the command "ld65 src/backgrounds.o src/controllers.o src/NESmash.o src/reset.o -C nes.cfg -o NESmash.nes"
