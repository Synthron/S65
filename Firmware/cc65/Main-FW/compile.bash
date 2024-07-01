#!/bin/bash

# define directories
OUTPUT_DIR="../output"
OUT="output"
SOURCE_DIR="source"
LIBRARY_DIR="../../lib"
CONFIG_FILE="memory.cfg"

# look for all source files in the directory and compile them, include libraries

cd $OUT
rm *
cd ..

echo "Compiling all source files"

cd $SOURCE_DIR
for file in *.s
do 
    ca65 --cpu 65c02 $file -o $OUTPUT_DIR/$file.o -l $OUTPUT_DIR/$file.list -I $LIBRARY_DIR
done
echo "done"

# string all object files together and link them

echo "Linking all object files"

cd $OUTPUT_DIR
OBJECTS=""
for file in *.o
do 
    OBJECTS+="$file"
    OBJECTS+=" " 
done
echo "done"

echo "compiling everything into bin and map file"

ld65 -C ../$CONFIG_FILE -m main.map $OBJECTS -o rom.bin -Ln rom.lbl
echo "done"

if [ $# != 0 ]
  then
    if [ "$1" == "-d" ]
      then 
        echo "show hexdump for debug:"
        hexdump -C rom.bin
    elif [ "$1" == "-f" ]
      then
        echo "uploading to Programmer"
        minipro -p SST39SF040 -w rom.bin
        echo "done"
    fi
fi