# lake
lua(jit)-based make alternative

# Prerequisites
* A luajit install that provides the include files and .dll/.so to link against (`git clone https://luajit.org/git/luajit.git`)
  * Linux: use `make install`
  * Windows: use `mingw32-make` or similar, then create a `C:\luajit` folder and move the below files to it, then add the folder to the system path
    * headers: `luaxlib.h`, `lua.h`, `luaconf.h`, `luajit.h`, `lualib.h`
    * binaries: `luajit.exe`, `lua51.dll`
  * Note: vanilla lua could be used as well but `lake.guessOS` accuracy may suffer without `jit.os`
* The LuaFileSystem library (`https://github.com/lunarmodules/luafilesystem.git`)
  * Linux: in `/usr/local/lib/lua/5.1`
  * Windows: in `C:\lake`
  * Note: (not technically required, but incremental builds will be disabled without it)
 
 # Installation
 * Windows: `mingw32-make -f Makefile.win`
   * Create `C:\lake` and move `lake.exe`, `lfs.dll` (from prerequisites), and the `lua` folder to it, then add to path
 * Linux: `make`
   * move `lake` executable to `/usr/local/bin/`
   * move `lua/lake.lua` (just the file) to `/usr/local/share/lua/5.1`
   * move `lfs.so` to `/usr/local/lib/lua/5.1`, if not already there
* Bootstrap: `lake`
  * then follow the above instructions for the corresponding OS

# Usage

`lake --help` will provide commandline usage tips for the tool

The scripts themselves are just lua files that use the implicitly linked `lake.lua` library bundled with the application, anything valid in lua/luajit is valid in a script.

the provided `make.lua` is a functional bootstrap buildscript and shows most features of the syntax and lake library functions.
