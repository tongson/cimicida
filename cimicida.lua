--- Lua utilities
-- @module cimicida
local io, string, os, table = io, string, os, table
local core = {
  type         = type,
  pcall        = pcall,
  load         = load,
  setmetatable = setmetatable,
  pairs        = pairs,
  ipairs       = ipairs
}
local cimicida = {}
local ENV = {}
_ENV = ENV

--- Output formatted string to the current output.
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARARGS)
function cimicida.printf (str, ...)
  io.write(string.format(str, ...))
end

--- Output formatted string to a specified output.
-- @param fd stream/descriptor
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARARGS)
function cimicida.outf (fd, str, ...)
  local o = io.output()
  io.output(fd)
  local ret, err = io.write(string.format(str, ...))
  io.output(o)
  return ret, err
end

-- Append a line break and string to an input string.
-- @param str Input string (STRING)
-- @param a String to append to str (STRING)
-- @return new string (STRING)
function cimicida.appendln (str, a)
  return string.format("%s\n%s", str, a)
end

--- Output formatted string to STDERR and return 1 as the exit status.
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARGS)
function cimicida.errorf (str, ...)
  cimicida.outf(io.stderr, str, ...)
  core.exit(1)
end


--- Call cimicida.errorf if the first argument is not nil or not false.
-- @param v value to evaluate (VALUE)
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARGS)
function cimicida.perror (v, str, ...)
  if v then
    return true
  else
    cimicida.errorf(str, ...)
  end
end

--- Output formatted string to STDERR.
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARGS)
function cimicida.warningf (str, ...)
  cimicida.outf(io.stderr, str, ...)
end

--- Time in the strftime(3) format %H:%M.
-- @return the time as a string (STRING)
function cimicida.timehm ()
  return os.date("%H:%M")
end


--- Date in the strftime(3) format %Y-%m-%d.
-- @return the date as a string (STRING)
function cimicida.dateymd ()
  return os.date("%Y-%m-%d")
end

--- Timestamp in the strftime(3) format %Y-%m-%d %H:%M:%S %Z%z.
-- @return the timestamp as a string (STRING)
function cimicida.timestamp ()
  return os.date("%Y-%m-%d %H:%M:%S %Z%z")
end

--- Check if a table has an specified value.
-- @param tbl table to search (TABLE)
-- @param value value to look for in tbl (VALUE)
-- @return a boolean value, true if v is found, nil otherwise (BOOLEAN)
function cimicida.hasv (tbl, value)
  for _, tval in core.pairs(tbl) do
    tval = string.gsub(tval, '[%c]', '')
    if tval == value then return true end
  end
end

--- Convert an array to a record.
-- Array values are converted into field names
-- @param tbl table to convert (TABLE)
-- @param def default value for each field in the record (VALUE)
-- @return the converted table (TABLE)
function cimicida.arr_to_rec (tbl, def)
  local t = {}
  for n = 1, #tbl do t[tbl[n]] = def end
  return t
end

--- Convert string to table.
-- Each line is a table value
-- @param str string to convert (STRING)
-- @return the table (TABLE)
function cimicida.ln_to_tbl (str)
  local tbl = {}
  if not str then
    return tbl
  end
  for ln in string.gmatch(str, "([^\n]*)\n") do
    tbl[#tbl + 1] = ln
  end
  return tbl
end

--- Split alphanumeric matches of a string into table values.
-- @param str string to convert (STRING)
-- @return the table (TABLE)
function cimicida.word_to_tbl (str)
  local t = {}
  for s in string.gmatch(str, "%w+") do
    t[#t + 1] = s
  end
  return t
end

--- Split non-space character matches of a string into table values.
-- @param str string to convert (STRING)
-- @return the table (TABLE)
function cimicida.str_to_tbl (str)
  local t = {}
  for s in string.gmatch(str, "%S+") do
    t[#t + 1] = s
  end
  return t
end

--- Escape a string for pattern usage
-- From lua-nucleo.
-- @param str string to escape (STRING)
-- @return a new string (STRING)
function cimicida.escape_pattern (str)
  local matches =
  {
    ["^"] = "%^",
    ["$"] = "%$",
    ["("] = "%(",
    [")"] = "%)",
    ["%"] = "%%",
    ["."] = "%.",
    ["["] = "%[",
    ["]"] = "%]",
    ["*"] = "%*",
    ["+"] = "%+",
    ["-"] = "%-",
    ["?"] = "%?",
    ["\0"] = "%z"
  }
  return string.gsub(str, ".", matches)
end

--- Filter table values.
-- Adapted from <http://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating>
-- @param tbl table to operate on (TABLE)
-- @param patt pattern to filter (STRING)
-- @param plain set to true if doing plain matching (BOOLEAN)
-- @return modified table (TABLE)
function cimicida.filtertval (tbl, patt, plain)
  plain = plain or nil
  local s, c = #tbl, 0
  for n = 1, s do
    if string.find(tbl[n], patt, 1, plain) then
      tbl[n] = nil
    end
  end
  for n = 1, s do
    if tbl[n] ~= nil then
      c = c + 1
      tbl[c] = tbl[n]
    end
  end
  for n = c + 1, s do
    tbl[n] = nil
  end
  return tbl
end

--- Convert file into a table.
-- Each line is a table value
-- @param file file to convert (STRING)
-- @return a table (TABLE)
function cimicida.file_to_tbl (file)
  local _, fd = core.pcall(io.open, file, "re")
  if fd then
    io.flush(fd)
    local tbl = {}
    for ln in fd:lines("*L") do
      tbl[#tbl + 1] = ln
    end
    io.close(fd)
    return tbl
  end
end

--- Find a string in a table value.
-- string is a plain string not a pattern
-- @param tbl table to traverse (TABLE)
-- @param str string to find (STRING)
-- @param patt boolean setting for plain strings (BOOLEAN)
-- @return the matching index if string is found, nil otherwise (NUMBER)
function cimicida.tfind (tbl, str, patt)
  patt = patt or nil
  local ok, found
  for n = 1, #tbl do
    ok, found = core.pcall(Lua.find, tbl[n], str, 1, patt)
    if ok and found then
      return n
    end
  end
end

--- Do a shallow copy of a table.
-- An nul table is created in the copy when table is encountered
-- @param tbl table to be copied (TABLE)
-- @return the copy as a table (TABLE)
function cimicida.shallowcp (tbl)
  local copy
  copy = {}
  for f, v in core.pairs(tbl) do
    if core.type(v) == "table" then
      copy[f] = {} -- first level only
    else
      copy[f] = v
    end
  end
  return copy
end

--- Split a path into its immediate location and file/directory components.
-- @param path path to split (STRING)
-- @return location (STRING)
-- @return file/directory (STRING)
function cimicida.splitp (path)
  local l = string.len(path)
  local c = string.sub(path, l, l)
  while l > 0 and c ~= "/" do
    l = l - 1
    c = string.sub(path, l, l)
  end
  if l == 0 then
    return '', path
  else
    return string.sub(path, 1, l - 1), string.sub(path, l + 1)
  end
end


--- Check if a path is a file or not.
-- @param file path to the file (STRING)
-- @return true if path is a file, nil otherwise (BOOLEAN)
function cimicida.isfile (file)
  local fd = io.open(file, "rb")
  if fd then
    io.close(fd)
    return true
  end
end

--- Read a file/path.
-- @param file path to the file (STRING)
-- @return the contents of the file, nil if the file cannot be read or opened (STRING or NIL)
function cimicida.fopen (file)
  local str
  for s in io.lines(file, 2^12) do
    str = string.format("%s%s", str or "", s)
  end
  if string.len(str) ~= 0 then
    return str
  end
end

--- Write a string to a file/path.
-- @param path path to the file (STRING)
-- @param str string to write (STRING)
-- @param mode io.open mode (STRING)
-- @return true if the write succeeded, nil and the error message otherwise (BOOLEAN)
function cimicida.fwrite (path, str, mode)
  local setvbuf, write = io.setvbuf, io.write
  mode = mode or "we+"
  local fd = io.open(path, mode)
  if fd then
    fd:setvbuf("no")
    local _, err = fd:write(str)
    io.flush(fd)
    io.close(fd)
    if err then
      return nil, err
    end
    return true
  end
end

--- Get line.
-- Given a line number return the line as a string.
-- @param ln line number (NUMBER)
-- @param file (STRING)
-- @return the line (STRING)
function cimicida.getln (ln, file)
  local str = cimicida.fopen(file)
  local i = 0
  for line in string.gmatch(str, "([^\n]*)\n") do
    i = i + 1
    if i == ln then return line end
  end
end

--- Simple string interpolation.
-- Given a record, interpolate by replacing field names with the respective value
-- Example:
-- tbl = { "field" = "value" }
-- str = [[ this is the {{ field }} ]]
-- If passed with these arguments 'this is the {{ field }}' becomes 'this is the value'
-- @param str string to interpolate (STRING)
-- @param tbl table (record) to deduce values from (TABLE)
-- @return processed string (STRING)
function cimicida.sub (str, tbl)
  local t, _ = {}, nil
  _, str = core.pcall(string.gsub, str, "{{[%s]-([%g]+)[%s]-}}",
    function (s)
      t.type = core.type
      local code = [[
        V=%s
        if type(V) == "function" then
          V=V()
        end
      ]]
      local lua = string.format(code, s)
      local chunk, err = core.load(lua, lua, "t", core.setmetatable(t, {__index=tbl}))
      if chunk then
        chunk()
        return t.V
      else
        return s
      end
    end) -- pcall
  return str
end

--- Generate a string based on the values returned by os.execute or px.exec.
--- Usually used inside cimicida.mmsg
-- @param proc process name (STRING)
-- @param status exit status (STRING)
-- @param code exit code (NUMBER)
-- @return a formatted string (STRING)
function cimicida.exitstr (proc, status, code)
  if status == "exit" or status == "exited" then
    return string.format("%s: Exited with code %s", proc, code)
  end
  if status == "signal" or status == "killed" then
    return string.format("%s: Caught signal %s", proc, code)
  end
end

--- Check if "yes" or a "true" was passed.
-- @param s string (STRING)
-- @return the boolean true if the string matches, nil otherwise (BOOLEAN)
function cimicida.truthy (s)
  if s == "yes" or
     s == "YES" or
     s == "true" or
     s == "True" or
     s == "TRUE" then
     return true
  end
end

--- Convert a "no" or a "false" was passed.
-- @param s string (STRING)
-- @return the boolean true if the string matches, nil otherwise (BOOLEAN)
function cimicida.falsy (s)
  if s == "no" or
     s == "NO" or
     s == "false" or
     s == "False" or
     s == "FALSE" then
     return true
  end
end

--- Wrap io.popen also known as popen(3)
-- The command has a script preamble.
-- 1. Exit immediately if a command exits with a non-zero status
-- 2. Pathname expansion is disabled.
-- 3. STDIN is closed
-- 4. Copy STDERR to STDOUT
-- 5. Finally replace the shell with the command
-- @param str command to popen(3) (STRING)
-- @param cwd current working directory (STRING)
-- @param ignore_error boolean setting to ignore errors (BOOLEAN)
-- @param return_code boolean setting to return exit code (BOOLEAN)
-- @return the output as a string if the command exits with a non-zero status, nil otherwise (STRING or BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
function cimicida.popen (str, cwd, _ignore_error, _return_code)
  local result = {}
  local header = [[  set -ef
  export LC_ALL=C
  exec 0>&- 2>&1
  ]]
  if cwd then
    str = string.format("%scd %s\n%s", header, cwd, str)
  else
    str = string.format("%s%s", header, str)
  end
  local pipe = io.popen(str, "re")
  io.flush(pipe)
  local tbl = {}
  for ln in pipe:lines() do
    tbl[#tbl + 1] = ln
  end
  local _
  _, result.status, result.code = io.close(pipe)
  result.bin = "io.popen"
  if _return_code then
    return result.code, result
  elseif _ignore_error or result.code == 0 then
    return tbl, result
  else
    return nil, result
  end
end

--- Wrap io.popen also known as popen(3)
-- Unlike cimicida.popen this writes to the pipe
-- The command has a script preamble.
-- 1. Exit immediately if a command exits with a non-zero status
-- 2. Pathname expansion is disabled.
-- 3. STDOUT is closed
-- 4. STDERR is closed
-- 5. Finally replace the shell with the command
-- @param str command to popen(3) (STRING)
-- @param data string to feed to the pipe (STRING)
-- @return the true if the command exits with a non-zero status, nil otherwise (BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
function cimicida.pwrite (str, data)
  local result = {}
  local write = io.write
  str = [[  set -ef
  export LC_ALL=C
  exec ]] .. str
  local pipe = io.popen(str, "we")
  io.flush(pipe)
  pipe:write(data)
  local _
  _, result.status, result.code = io.close(pipe)
  if result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Wrap os.execute also known as system(3).
-- The command has a script preamble.
-- 1. Exit immediately if a command exits with a non-zero status
-- 2. Pathname expansion is disabled.
-- 3. STDERR and STDIN are closed
-- 4. STDOUT is piped to /dev/null
-- 5. Finally replace the shell with the command
-- @param str command to pass to system(3) (STRING)
-- @return true if exit code is equal to zero, nil otherwise (BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
function cimicida.system (str)
  local result = {}
  local set = [[  set -ef
  export LC_ALL=C
  exec 0>&- 2>&- 1>/dev/null
  exec ]]
  local redir = [[ 0>&- 2>&- 1>/dev/null ]]
  local _
  _, result.status, result.code = os.execute(set .. str .. redir)
  result.bin = "os.execute"
  if result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Wrap os.execute also known as system(3).
-- Similar to cimicida.system but it does not replace the shell.
-- Suitable for scripts.
-- @param str string to pass to system(3) (STRING)
-- @return true if exit code is equal to zero, nil otherwise (BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
function cimicida.execute (str)
  local result = {}
  local set = [[  set -ef
  exec 0>&- 2>&- 1>/dev/null
  ]]
  local _
  _, result.status, result.code = os.execute(set .. str)
  if result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Run a shell pipe.
-- @param ... a vararg containing the command pipe. The first argument should be popen or execute
-- @return the output from cimicida.popen or cimicida.execute, nil if popen or execute was not passed (STRING or BOOLEAN)
function cimicida.pipeline (...)
  local pipe = {}
  local cmds = {...}
  for n = 2, #cmds do
    pipe[#pipe + 1] = table.concat(cmds[n], " ")
    if n ~= #cmds then pipe[#pipe + 1] = " | " end
  end
  if cmds[1] == "popen" then
    return cimicida.popen(table.concat(pipe))
  elseif cmds[1] == "execute" then
    return cimicida.execute(table.concat(pipe))
  else
    return
  end
end

--- Time a function run.
-- @param f the function (FUNCTION)
-- @param ... a vararg containing the arguments for the function (VARGS)
-- @return the seconds elapsed as a number (NUMBER)
-- @return the return values of the function (VALUE)
function cimicida.time(f, ...)
  local t1 = os.time()
  local fn = {f(...)}
  return table.unpack(fn), os.difftime(os.time() , t1)
end

--- Escape quotes ",'.
-- @param str string to quote (STRING)
-- @return quoted string (STRING)
function cimicida.escapep (str)
  str = string.gsub(str, [["]], [[\"]])
  str = string.gsub(str, [[']], [[\']])
  return str
end

--- Log to a file.
-- @param file path name of the file (STRING)
-- @param ident identification (STRING)
-- @param msg string to log (STRING)
-- @return a boolean value, true if not errors, nil otherwise (BOOLEAN)
function cimicida.log (file, ident, msg)
  local setvbuf = io.setvbuf
  local openlog = function (f)
    local fd = io.open(f, "ae+")
    if fd then
      return fd
    end
  end
  local fd = openlog(file)
  local log = "%s %s: %s\n"
  local timestamp = os.date("%a %b %d %T")
  fd:setvbuf("line")
  local _, err = cimicida.outf(fd, log, timestamp, ident, msg)
  io.flush(fd)
  io.close(fd)
  if err then
    return nil, err
  end
  return true
end

--- Insert a value to a table position if the first argument is not nil or not false.
-- Wraps table.insert().
-- @param bool value to evaluate (VALUE)
-- @param list table to insert to (TABLE)
-- @param pos position in the table (NUMBER)
-- @param value value to insert (VALUE)
-- @return the result of table.insert() (VALUE)
function cimicida.insert_if (bool, list, pos, value)
  if bool then
    if core.type(value) == "table" then
      for n, i in core.ipairs(value) do
        local p = n - 1
        table.insert(list, pos + p, i)
      end
    else
      table.insert(list, pos, value)
    end
  end
end

--- Return the second argument if the first argument is not nil or not false.
-- For value functions there should be no evaluation in the arguments.
-- @param bool value to evaluate (VALUE)
-- @param value to return (VALUE)
-- @return the value if bool is not nil or not false
function cimicida.return_if (bool, value)
  if bool then
    return (value)
  end
end

--- Return the second argument if the first argument is nil or false.
-- @param bool value to evaluate (VALUE)
-- @param value to return (VALUE)
-- @return the value if bool is nil or false
function cimicida.return_if_not (bool, value)
  if bool == false or bool == nil then
    return value
  end
end

return cimicida
