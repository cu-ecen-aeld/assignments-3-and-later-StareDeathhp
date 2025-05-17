CC       := $(CROSS_COMPILE)gcc
CFLAGS   := -Wall -Werror -std=gnu99

all: writer

writer: writer.o
	$(CC) $(CFLAGS) -o $@ $^

writer.o: writer.c
	$(CC) $(CFLAGS) -c writer.c

clean:
	rm -f writer *.o