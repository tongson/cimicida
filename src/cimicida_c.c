#define _LARGEFILE_SOURCE       1
#define _FILE_OFFSET_BITS 64

#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "flopen.h"

typedef luaL_Stream LStream;

static int cchroot(lua_State *L) {
    const char *path = luaL_checkstring(L, 1);
    if (chroot(path) == -1) {
        lua_pushnil(L);
        luaL_error(L, "Unable to chroot to " LUA_QS " (%s)",
                                path, strerror(errno));
    }
    lua_pushboolean(L, 1);
    return 1;
}

static int cflclose (lua_State *L) {
    FILE *f = *(FILE**)luaL_checkudata(L, 1, LUA_FILEHANDLE);
    int res = close(fileno(f));
    if (res == -1) {
        lua_pushnil(L);
        luaL_error(L, "Unable to close " LUA_QS " (%s)",
                                f, strerror(errno));
    }
    lua_pushboolean(L, 1);
    return 1;
}

static int cflopen (lua_State *L) {
    const char *path = luaL_checkstring(L, 1);
    int flags = luaL_optint(L, 2, O_NONBLOCK | O_RDWR);
    mode_t mode = luaL_optint(L, 3, 0700);

    LStream *p = (LStream *)lua_newuserdata(L, sizeof(LStream));
    p->closef = NULL;
    luaL_setmetatable(L, LUA_FILEHANDLE);
    p->f = NULL;
    p->closef = &cflclose;

    int fd = flopen(path, flags, mode);
    if (fd == -1) {
        lua_pushnil(L);
        luaL_error(L, "Unable to lock " LUA_QS " (%s)",
                                path, strerror(errno));
    }
    p->f = fdopen(fd, 'rw');
    return 1;
}

static int cchdir(lua_State *L) {
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
    {"chroot", cchroot},
    {"flclose", cflclose},
    {"flopen", cflopen},
    {"chdir", cchdir},
    {NULL, NULL}
};

LUALIB_API int luaopen_cimicida_c(lua_State *L) {
    luaL_newlib(L, syslib);
    return 1;
}

