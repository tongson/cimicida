local C = require"cimicida_c"
local c = C

local close, lines, open, popen =
      io.close, io.lines, io.open, io.popen

local concat, execute =
      table.concat, os.execute

local ipairs, print =
      ipairs, print

_ENV=nil

--- Use io.popen (popen(3)) to run a command
-- then convert each line from the output
-- to a table entry. If no output then
-- use the error code as the first and only
-- table entry.
-- @param str is the command or executable to run
-- @return a table of lines from the output and a boolean
function C.execsh (str)
	local tbl = {}
	local strm = popen(str, 'r')
	strm:flush()
	for ln in strm:lines() do
		tbl[#tbl + 1] = ln
	end
	local _, _, code = strm:close()
	if not (code == 0) then return false, {code} end
	return true, tbl
end


--- Use os.execute (system(3)) to run a script or command
-- This is preferrable over execsh if you don't need the output
-- @param str is a string of script or command
-- @return error code and boolean
function C.system (str)
	local cmd = {}
	cmd[1] = [[
	set -efu
	exec 0>&- 2>&- >/dev/null
	]]
	cmd[2] = str
	local _, _, code = execute(concat(cmd))
	if not (code == 0) then return false, {code} end
	return true, {0}
end

return C


