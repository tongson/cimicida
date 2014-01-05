local ct = require"cwtest"
local c = require"cimicida"
local execsh, system, script = c.execsh, c.system, c.script
local chroot, chdir = c.chroot, c.chdir
local hasv = c.hasv
local mktemp, rm = os.tmpname, os.remove

local T = ct.new()

T:start"c.execsh"
   do
      local b, t = nil, nil
      local _, ppid = execsh[[cat /proc/self/status|grep PPid|awk '{print $2}']]

      -- Every execsh invocation should have the same PPid.
      _, t = execsh[[cat /proc/self/status|grep PPid|awk '{print $2}']]
      T:yes(hasv(t, ppid[1]))

      b, t = execsh[[ls /]]
      T:yes(hasv(t, "sbin"))
      T:yes(b)

      b, t = execsh[[ping -c1 127.0.0.1]]
      T:yes(hasv(t, "--- 127.0.0.1 ping statistics ---"))
      T:yes(b)

      b, t = execsh[[ping -c1 unknown]]
      T:no(b)

      b, t = execsh[[mktemp]]
      local file = t[1]
      T:yes(b)
      T:yes(rm(file))

      local tmpfile = os.tmpname()
      b, t = execsh([[rm ]]..tmpfile)
      T:yes(b)
   end
T:done()

T:start"c.system"
   do
      local b, c = nil, nil
      local good = [[
      echo yo
      echo 12
      ]]
      local bad = [[
      rm /dlASalkaAkk
      echo 123
      ]]

      b, c = system[[ls /]]
      T:yes(b)
      T:eq(c, 0)

      b, c = system[[echo yo]]
      T:yes(b)
      T:eq(c, 0)

      b, c = system[[ls /sb*]]
      T:no(b)
      T:eq(c, 2)

      b, c = system[[rm /etc/_XxX]]
      T:no(b)
      T:eq(c, 1)

      b, c = system[[echo $AAA]]
      T:no(b)
      T:eq(c, 1)

      b, c = system(good)
      T:yes(b)
      T:eq(c, 0)

      b, c = system(bad)
      T:no(b)
      T:eq(c, 1)
   end
T:done()

T:start"c.script"
   do
      local pre = [[exec 0>&- 2>&- 1>/dev/null
      ]]
      local oscript = script
      local script =
         function (str)
            return script(pre..str)
         end
      local b, c = nil, nil
      local good = [[
      echo yo
      echo 12
      ]]
      local bad = [[
      rm /dlASalkaAkk
      echo 123
      ]]

      b, c = script[[ls /]]
      T:yes(b)
      T:eq(c, 0)

      b, c = script[[echo yo]]
      T:yes(b)
      T:eq(c, 0)

      b, c = script[[ls /sb*]]
      T:yes(b)
      T:eq(c, 0)

      b, c = script[[rm /etc/_XxX]]
      T:no(b)
      T:eq(c, 1)

      b, c = script[[echo $AAA]]
      T:yes(b)
      T:eq(c, 0)

      b, c = script(good)
      T:yes(b)
      T:eq(c, 0)

      b, c = script(bad)
      T:yes(b)
      T:eq(c, 0)
   end
T:done()

T:start"c.chroot"
   do
      local b, c = nil, nil

      b, c = chroot[[/tmp]]
      T:no(b)
      T:eq(c, "Unable to chroot to '/tmp' (Operation not permitted)")

      b, c = chroot[[/nonexistent]]
      T:no(b)
      T:eq(c, "Unable to chroot to '/nonexistent' (No such file or directory)")
   end
T:done()

T:start"c.chdir"
   do
      local t = nil

      _, t = chdir[[/nonexistent]]
      T:eq(t, "Unable to change directory to '/nonexistent' (No such file or directory)")

      -- look for /etc/fstab
      chdir[[/etc]]
      _, t = execsh[[ls]]
      T:yes(hasv(t, "fstab"))

      -- look for /dev/shm
      chdir[[/dev]]
      _, t = execsh[[ls]]
      T:yes(hasv(t, "shm"))
   end
T:done()

