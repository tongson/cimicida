#include <errno.h>
#include <unistd.h>
#include <string.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static int lchroot (lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    if (chroot(path) == -1) {
        lua_pushnil(L);
        luaL_error(L, "Unable to chroot to " LUA_QS " (%s)",
                                path, strerror(errno));
    }
    lua_pushboolean(L, 1);
    return 1;
}

static int lchdir (lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    if (chdir(path) == -1) {
        lua_pushnil(L);
        luaL_error(L, "Unable to change directory to " LUA_QS " (%s)",
                                path, strerror(errno));
    }
    lua_pushboolean(L, 1);
    return 1;
}

static const luaL_Reg syslib[] = {
  {"chroot", lchroot},
  {"chdir", lchdir},
  {NULL, NULL}
};

LUALIB_API int luaopen_cimicida(lua_State *L) {
  luaL_newlib(L, syslib);
  return 1;
}

