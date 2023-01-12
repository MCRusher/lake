# lake
lua(jit)-based make alternative

# Prerequisites
* A luajit install that provides the include files and .dll/.so to link against (`git clone https://luajit.org/git/luajit.git`)
  * Linux: use `make install`
  * Windows: use `mingw32-make` or similar, then create a `C:\luajit` folder and move the below files to it, then add the folder to the system path
    * headers: `luaxlib.h`, `lua.h`, `luaconf.h`, `luajit.h`, `lualib.h`
    * binaries: `luajit.exe`, `lua51.dll`
* The LuaFileSystem library (`https://github.com/lunarmodules/luafilesystem.git`)
  * Linux: in `/usr/local/lib/lua/5.1`
  * Windows: in `C:\lake`
 
 # Installation
 * Windows: `mingw32-make -f Makefile.win`
   * Create `C:\lake` and move `lake.exe`, `lfs.dll` (from prerequisites), and the `lua` folder to it, then add to path
 * Linux: `make`
   * move `lake` executable to `/usr/local/bin/`
   * move `lua/lake.lua` (just the file) to `/usr/local/share/lua/5.1`
   * move `lfs.so` to `/usr/local/lib/lua/5.1`, if not already there
* Bootstrap: `lake`
  * then follow the above instructions for the corresponding OS
