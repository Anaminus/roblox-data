# Lua Build System

This build system is written in [Lua][lua]. Along with Lua itself, this build
system requires the following modules:

- [LuaFileSystem][lfs]
- [LuaSocket][luasocket]
- [LuaZip][luazip]
- [LuaXML][luaxml]
- [dkjson][dkjson]

## Building

The simplest way to get everything set up is to download [LuaDist][luadist].

1. [Install][luadist-install] the latest version of LuaDist for your system.
2. Ensure the necessary packages have been installed. Every required package
   can be installed in one call:

	luadist install dkjson luafilesystem luasocket luaxml luazip

3. Run the build script, where ever it is located.

	lua build.lua


[lua]: http://www.lua.org/
[lfs]: http://keplerproject.github.io/luafilesystem/
[dkjson]: http://dkolf.de/src/dkjson-lua.fsl/home
[luaxml]: http://viremo.eludi.net/LuaXML/
[luasocket]: http://w3.impa.br/~diego/software/luasocket/
[luazip]: http://www.keplerproject.org/luazip/
[luadist]: http://luadist.org/
[luadist-install]: https://github.com/LuaDist/Repository/wiki/LuaDist%3A-Installation