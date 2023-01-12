CC=gcc
CFLAGS=-O2 -Wall -Wpedantic
LUA_LIB=-lluajit-5.1
LIB_PATH=/usr/local/lib
INC_PATH=/usr/local/include/luajit-2.1

.PHONY: all
all : lake
	
lake : lake.o
	$(CC) $(CFLAGS) -I$(INC_PATH) -L$(LIB_PATH) -o $@ $^ $(LUA_LIB) -Wl,-R$(LIB_PATH)

lake.o : lake.c
	$(CC) $(CFLAGS) -I$(INC_PATH) -o $@ -c $^

clean :
	@rm lake.o lake