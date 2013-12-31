local C = require"cimicida_c"
local c = C

local close, lines, open, popen =
      io.close, io.lines, io.open, io.popen

local concat, execute =
      table.concat, os.execute

local ipairs, print =
      ipairs, print

_ENV=nil

--- Use io.popen (popen(3)) to run a command.
-- then convert each line from the output
-- to a table entry. If no output then
-- use the error code as the first and only
-- table entry.
-- The exec emulates the fork, fork, exec dance so
-- the executable replaces the shell.
-- @param str is the command or executable to run
-- @return a table of lines from the output and a boolean
function C.execsh (str)
	local cmd = {}
	cmd[1] = [[set -efu
	exec ]]
	cmd[2] = str
	cmd[3] = [[ 0>&- 2>&-]]
	local tbl = {}
	local strm = popen(concat(cmd), 'r')
	strm:flush()
	for ln in strm:lines() do
		tbl[#tbl + 1] = ln
	end
	local _, _, code = strm:close()
	if not (code == 0) then return false, {code} end
	return true, tbl
end

--- Use os.execute (system(3)) to run a script or command.
-- This is preferrable over execsh if you don't need the output
-- This also emulates fork*2+exec.
-- @param str is a string of script or command
-- @return true if command executed successfully,
-- false otherwise. After this the exit code.
function C.system (str)
	local cmd = {}
	cmd[1] = [[set -efu
	exec ]]
	cmd[2] = str
	cmd[3] = [[ 0>&- 2>&- >/dev/null]]
	local _, _, code = execute(concat(cmd))
	if not (code == 0) then return false, code end
	return true, 0
end

--- Use os.execute (system(3)) to run a script.
-- similar to C.system above but without using exec
-- or setting options.
-- This is effectively running 'sh -c script'
-- @param str is the script
-- @return true if command executed successfully,
-- false otherwise. After this the exit code.
function C.script (str)
	local _, _, code = execute(str)
	if not (code == 0) then return false, code end
	return true, 0
end

return C


