CC = CC or "gcc"
MAKE = MAKE or (lake.guessOS("Windows") and "mingw32-make" or "make")
CFLAGS = CFLAGS or "-O2 -Wall -Wpedantic"
LIB_PATH = LIB_PATH or (lake.guessOS("Windows") and "C:/luajit" or "/usr/local/lib")
INC_PATH = INC_PATH or (lake.guessOS("Windows") and  "C:/luajit" or "/usr/local/include/luajit-2.1")
LUA_LIB = LUA_LIB or (lake.guessOS("Windows") and "lua51" or "luajit-5.1")
PREFIX = PREFIX or (lake.guessOS("Windows") and "C:/lake" or "/usr/local/")
OUT = OUT or lake.nativeBinaryName("lake")

local build = lake.format("{} {} -L\"{}\" -I\"{}\" {}", CC, CFLAGS, LIB_PATH, INC_PATH, lake.rpath(LIB_PATH))

lake.phonyStep("all", {OUT})

lake.step(OUT, {"lake.o"},function(name, prereqs)
    lake.execute("{} -o {} {} -l{}", build, name, lake.cat(prereqs, " "), LUA_LIB)
end)

lake.step("lake.o", {"lake.c"},function(name, prereqs)
    lake.execute("{} -o {} -c {}", build, name, lake.cat(prereqs, " "))
end)

lake.phonyStep("clean",{},function()
    lake.rm("lake.o", OUT, lake.nativeDLLName("lfs"), "luajit", "luafilesystem")
end)

lake.phonyStep("prereqs",{},function()
    local lfs_name = lake.nativeDLLName("lfs")
    local lfs_prefix = lake.guessOS("Windows") and lake.path(PREFIX, lfs_name) or lake.path(PREFIX, "lib/lua/5.1", lfs_name)
    lake.execute("git clone https://luajit.org/git/luajit.git")
    lake.execute("git clone https://github.com/lunarmodules/luafilesystem.git")
    lake.execute("cd luajit && {}", MAKE)
    if not lake.guessOS("Windows") then --make install doesn't work on windows
        lake.execute("cd luajit && {} install PREFIX=\"{}\"", MAKE, PREFIX)
    else
        lake.mkdir(LIB_PATH)
        lake.mkdir(INC_PATH)
        lake.mkdir(PREFIX)
        lake.copyTo("luajit/src", LIB_PATH,
            "lua51.dll",
            "luajit.exe"
        )
        lake.copyTo("luajit/src", INC_PATH,
            "lauxlib.h",
            "lua.h",
            "luaconf.h",
            "luajit.h",
            "lualib.h"
        )
        --can be deleted if C:/luajit is added to path, alternatively, C:/luajit can be deleted as well
        lake.copyFile("luajit/src/lua51.dll", lake.path(PREFIX, "lua51.dll"))
        lake.printf("!!!Note: lua51.dll can be deleted from \"{}\" if \"{}\" is added to system path", PREFIX, LIB_PATH)
    end
    lake.execute("{} --shared -fPIC -Iluajit/src -o {} luafilesystem/src/lfs.c -l{}", build, lfs_name, LUA_LIB)
    lake.copyFile(lfs_name, lfs_prefix)
end)

lake.phonyStep("install", {OUT},function()
    local lfs_name = lake.nativeDLLName("lfs")
    if lake.guessOS("Windows") then
        lake.mkdir(PREFIX)
        lake.mkdir(lake.path(PREFIX, "lua"))
        if lake.exists(lfs_name) then
            lake.copyFile(lfs_name, lake.path(PREFIX, lfs_name))
        end
        lake.copyTo("./", PREFIX,
            OUT,
            "lua/lake.lua"
        )
    else
        if lake.exists(lfs_name) then
            lake.copyFile(lfs_name, lake.path(PREFIX, "lib/lua/5.1", lfs_name))
        end
        lake.copy({
            OUT,
            "lua/lake.lua"
        },{
            lake.path(PREFIX, "bin", OUT),
            lake.path(PREFIX, "share/lua/5.1/lake.lua")
        })
    end
end)
