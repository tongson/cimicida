local C = require"cimicida_c"
local c = C

local close, lines, open, popen =
      io.close, io.lines, io.open, io.popen

local execute =
      os.execute

local gsub = string.gsub

local ipairs, print =
      ipairs, print

_ENV=nil

--- Use pairs to traverse a table and check for a value.
-- @param tbl is the tbl to traverse
-- @param value is the value to look for
-- @return a boolean as the result of the search
function c.hasv (tbl, value)
   for _, v in pairs(tbl) do
      if v == value then return true end
   end
   return false
end

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
	local set = [[set -efu
	exec ]]
	local redir = [[ 0>&- 2>&-]]
	local t = {}
	local s = popen(set..str..redir, 'r')
	s:flush()
	for l in s:lines() do
		t[#t+1] = l
	end
	local _, _, code = s:close()
	if code ~= 0 then
		return false, {code}
	end
	return true, t
end

--- Use os.execute (system(3)) to run a script or command.
-- This is preferrable over execsh if you don't need the output
-- This also emulates fork*2+exec.
-- @param str is a string of script or command
-- @return true if command executed successfully,
-- false otherwise. After this the exit code.
function C.system (str)
	local set = [[set -efu
   exec 0>&- 2>&- 1>/dev/null
	exec ]]
	local redir = [[ 0>&- 2>&- 1>/dev/null]]
	local _, _, code = execute(set..str..redir)
	if code ~= 0 then
		return false, code
	end
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
	if code ~= 0 then
		return false, code
	end
	return true, 0
end

--- Primitive templating with `string.gsub`.
-- Variables are marked as `{{ var }}`, where `var`
-- is a key from a table. Variables and keys can only
-- contain alphanumeric characters and underscores.
-- These variables will be replaced with the corresponding
-- value of the variable (key).
-- @param str is the string (template)
-- @param tbl is the table
-- @return processed string
function C.templit (str, tbl)
	return (str:gsub([[{{ ([%w_]+) }}]], tbl))
end

return C
