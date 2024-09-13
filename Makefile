.PHONY: all run clean

BIN := raymarching
CC := gcc
CFLAGS := -std=c99 -Wall -O2 -lm -lglfw -I.
SOURCES := glad.c main.c

all: compile_commands.json

compile_commands.json: $(BIN)
	bear --output $@ -- make $<

$(BIN): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

run: $(BIN)
	./$<

clean:
	rm -f compile_commands.json $(BIN)
