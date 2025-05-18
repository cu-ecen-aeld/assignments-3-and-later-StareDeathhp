CC = gcc
.DEFAULT_GOAL := build

#clean previous build
clean:                      #clean needs to be first so we wont anything else first
	rm -f writer.o writer


ifeq ($(BUILD),cross)
    $(info CROSS-COMPILATION ENABLED)
	CC = /home/aov634vbox/Downloads/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-gcc  #$(PATH) #aarch64-none-linux-gnu-
 
else
    $(info NATIVE COMPILATION: Using default GCC)
endif
$(info Compiler selected: $(CC))
build: writer

CROSS_COMPILE: 
	$(MAKE) build BUILD=cross

# Compile the object file from source
writer.o: writer.c
	$(CC) -c writer.c -o writer.o

# Link the object file to create the executable
writer: writer.o
	$(CC) writer.o -o writer









