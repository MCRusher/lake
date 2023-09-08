CC=gcc
CFLAGS=-O2 -Wall -Wpedantic
LUA_LIB=-lluajit-5.1
LIB_PATH=/usr/lib
INC_PATH=/usr/include/luajit-2.1

.PHONY: all
all : lake
	
lake : lake.o
	$(CC) $(CFLAGS) -I$(INC_PATH) -L$(LIB_PATH) -o $@ $^ $(LUA_LIB)

lake.o : lake.c
	$(CC) $(CFLAGS) -I$(INC_PATH) -o $@ -c $^

.PHONY: install
install : lake
	cp lake /usr/local/bin/lake
	mkdir -p /usr/local/share/lua/5.1/
	cp lua/lake.lua /usr/local/share/lua/5.1/lake.lua 

clean :
	@rm lake.o lake
