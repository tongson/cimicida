LUA= ../..
LUAINC= $(LUA)/src

CC= gcc
CFLAGS= $(INCS) $(WARN) -Os $G -fPIC -fomit-frame-pointer
WARN= -pedantic -Wall -Wextra
INCS= -I$(LUAINC)
MAKESO= $(CC) -shared

MYNAME= cimicida
MYLIB= $(MYNAME)
T= $(MYNAME).so
OBJS= $(MYLIB).o

all: o so

o:	$(MYLIB).o

so:	$T

$T:	$(OBJS)
	$(MAKESO) -o $@ $(OBJS)

clean:
	rm -f $(OBJS)
