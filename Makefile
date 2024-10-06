.PHONY: all run clean

BIN := raymarching
CC := clang
CFLAGS := -std=c99 -Wall -g -lm -lglfw -I. \
	  -DVERTEX_SHADERS="{\"vert.glsl\"}" \
	  -DFRAGMENT_SHADERS="{\"frag.glsl\", \"perlin.glsl\"}"

SOURCES := glad.c main.c

all: $(BIN)

$(BIN): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

run: $(BIN)
	./$<

clean:
	rm -f $(BIN)
