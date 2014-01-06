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

static int Cchroot(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	if (chroot(path) == -1) {
		lua_pushboolean(L, 0);
		lua_pushfstring(L, "Unable to chroot to " LUA_QS " (%s)",
				path, strerror(errno));
	return 2;
	}
	lua_pushboolean(L, 1);
	return 1;
}

static int Cflclose(lua_State *L)
{
	FILE *f = *(FILE**)luaL_checkudata(L, 1, LUA_FILEHANDLE);
	int res = close(fileno(f));
	if (res == -1) {
		lua_pushboolean(L, 0);
		lua_pushfstring(L, "Unable to close " LUA_QS " (%s)",
				f, strerror(errno));
	return 2;
	}
	lua_pushboolean(L, 1);
	return 1;
}

static int Cflopen(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	int flags = luaL_optint(L, 2, O_NONBLOCK | O_RDWR);
	mode_t mode = luaL_optint(L, 3, 0700);

	LStream *p = (LStream *)lua_newuserdata(L, sizeof(LStream));
	p->closef = NULL;
	luaL_setmetatable(L, LUA_FILEHANDLE);
	p->f = NULL;
	p->closef = &Cflclose;

	int fd = flopen(path, flags, mode);
	if (fd == -1) {
		lua_pushboolean(L, 0);
		lua_pushfstring(L, "Unable to lock " LUA_QS " (%s)",
				path, strerror(errno));
	return 2;
	}
	p->f = fdopen(fd, "rw");
	return 1;
}

static int Cchdir(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	if (chdir(path) == -1) {
		lua_pushboolean(L, 0);
		lua_pushfstring(L, "Unable to change directory to " LUA_QS " (%s)",
				path, strerror(errno));
	return 2;
	}
	lua_pushboolean(L, 1);
	return 1;
}

static const luaL_Reg syslib[] =
{
	{"chroot", Cchroot},
	{"flclose", Cflclose},
	{"flopen", Cflopen},
	{"chdir", Cchdir},
	{NULL, NULL}
};

LUALIB_API int luaopen_cimicida_c(lua_State *L)
{
	luaL_newlib(L, syslib);
	return 1;
}

