#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <stdio.h>
#include <stdlib.h>

#define WRAPPER_SCRIPT\
	"require \"lake\"\n"\
	"dofile(lake.parseArgs(unpack(args)))\n"\
	"lake.doStep()\n"

int main(int argc, char ** argv) {
	lua_State * L = luaL_newstate();
	luaL_openlibs(L);
	//even though I'm doing it exactly like lua.c, it doesn' work so I'm changing it
	lua_createtable(L,argc-1,0);
	for(int i = 1; i < argc; i++){
		lua_pushstring(L, argv[i]);
		lua_rawseti(L,-2, i);
	}
	lua_setglobal(L, "args");//for some reason, "arg" isn't recognized properly, so I'm just gonna unpack the table
	if(luaL_dostring(L, WRAPPER_SCRIPT)){
		printf("lake failed: %s\n", lua_tostring(L, -1));
		lua_close(L);
		return EXIT_FAILURE;
	}
	lua_close(L);
}