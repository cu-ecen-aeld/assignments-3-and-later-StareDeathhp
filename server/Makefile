CC = $(CROSS_COMPILE)gcc

aesdsocket: aesdsocket.o
	$(CC) -o aesdsocket aesdsocket.o

all: aesdsocket

default: aesdsocket

clean: 
		rm -f aesdsocket
		rm -f aesdsocket.o