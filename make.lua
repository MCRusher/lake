--Example crossplatform lake buildscript for building lake
--Invoked with lake -f:example_make.lua

--luajit needs to have lfs installed for full functionality

--These variables can be overwritten
CC = CC or "gcc"
CFLAGS = CFLAGS or "-O2 -Wall -Wpedantic"
LUA_LIB = LUA_LIB or (lake.guessOS("Windows") and "-llua51" or "-lluajit-5.1")
PREFIX = PREFIX or (lake.guessOS("Windows") and "C:\\lake" or "/usr/local/")
OUT = OUT or lake.nativeBinaryName("lake")

--OS path guessing with user prompt fallback
LIB_PATH = LIB_PATH or (function()
	local path = lake.guessOS("Windows") and "C:\\luajit" or "/usr/local/lib"
	if not lake.exists(path) then
		path = lake.inputValidDir("Enter path containing luajit shared object/dll: ")
	end
	return "-L" .. path
end)()

INC_PATH = INC_PATH or (function()
	local path = lake.guessOS("Windows") and  "C:\\luajit" or "/usr/local/include/luajit-2.1"
	if not lake.exists(path) then
		path = lake.inputValidDir("Enter path containing luajit include files: ")
	end
	return "-I" .. path
end)()

--combining common elements of commands into a single string
local build = lake.format("{} {} {} {}", CC, CFLAGS, LIB_PATH, INC_PATH)

--[[
The first defined step will be executed if step is not specified
 The first/specified step will always be run even if current
The first argument is the name of then step, for non-phony steps it should be the name of an output of the step
The second argument is a list of prerequisite steps that must be done first
The third argument is the string or function to be executed to complete the step
 If the third argument is a function, it optionally gets the step's name and list of prereq names as arguments
  to facilitate ease of code reuse
]]--
lake.phonyStep("all", {OUT})

lake.step(OUT, {"lake.o"},function(name, prereqs)
	--r is only needed if usr/local/lib is not in the path (hard to check for), and not at all for Windows
	local r = ""
	if not lake.guessOS("Windows") then
		r = "-Wl,-R" .. LUA_LIB:sub(3)
	end
    lake.execute("{} -o {} {} {} {}", build, name, table.concat(prereqs, " "), LUA_LIB, r)
end)

lake.step("lake.o", {"lake.c"},function(name, prereqs)
    lake.execute("{} -o {} -c {}", build, name, table.concat(prereqs, " "))
end)

--phony steps are always run no matter
lake.phonyStep("clean",{},function()
    lake.rm("lake.o", OUT)
end)
