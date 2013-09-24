socket = require "socket"
-- module common
common = {}

local HEADER_LEN = 5

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local cache = {}
-- This function receives a key, and a function which loads the value. The
-- cached value is returned if it exists, avoiding execution of load_func
-- function. Otherwise, load_func is executed and the returned value is cached
-- for following calls to this function.
function common.cache(key, load_func)
  if type(load_func) ~= "function" then
    local aux = load_func
    load_func = function() return aux end
  end
  local v = cache[key]
  if not v then
    -- cache the value
    v = load_func()
    cache[key] = v
  end
  return v
end

-- converts to a Lua string
function common.tostring(data,force_string)
  local t = type(data)
  if t == "table" then
    data = table.tostring(data)
  elseif t == "string" or force_string then
    data = string.format("%q", tostring(data))
  else
    data = tostring(data)
  end
  return data
end

-- Loads a string or a Lua script, depending on the content of str.
function common.load(str,logger, ...)
  local logger = logger or common.logger()
  local f,t,msg
  if str:match(".*%.lua$") then f,msg = loadfile(str)
  else f,msg = load(str, nil) end
  if not f then
    logger:warningf("Impossible to load the given task: %s\n", msg)
    return nil
  end
  local r  = table.pack(pcall(f, ...))
  local ok = table.remove(r,1)
  if not ok then
    -- result has the error message
    logger:warningf("Impossible to load the given task: %s\n", r[1])
    return nil
  end
  return table.unpack(r)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local function send(sock, data, pos)
  local r, status, last = sock:send(data, pos)
  return r or last, status
end

local function recv(sock, len)
  local r, status, partial = sock:receive(len)
  return r or partial, status
end

local function recv_loop(sock, len)
  local data,r,status = ""
  while #data < len do
    r,status = recv(sock, len - #data)
    if status == "timeout" then coroutine.yield("timeout")
    elseif status == "closed" or not r then data=false break
    end
    data = data .. r
  end
  return data,status
end

local function send_loop(sock, data)
  local len = #data
  local send_len,status,ok = 0,nil,true
  while send_len < len do
    send_len,status = send(sock, data, send_len + 1)
    if status == "timeout" then coroutine.yield(status)
    elseif status == "closed" or not send_len then ok=false break
    end
  end
  return ok,status
end

-- A wrapper which sends a string of data throughout a socket as a packet formed
-- by a header of 5 bytes (a uint32 encoded using our binarizer), and after that
-- the message.
function common.send_wrapper(sock, data)
  sock:settimeout(0) -- do not block
  local len     = #data
  local len_str = binarizer.code.uint32(len)
  assert(#len_str == HEADER_LEN, "Unexpected header length")
  if len > 256 then
    local ok,msg = send_loop(sock, len_str)
    if not ok then return false,msg end
    local ok,msg = send_loop(sock, data)
    if not ok then return false,msg end
  else
    local aux = len_str..data
    local ok,msg = send_loop(sock, aux)
    if not ok then return false,msg end
  end
  return true
end

-- A wrapper which receives data send following the previous function, so the
-- length of the message is decoded reading the first 5 bytes, and then the
-- whole message is read.
function common.recv_wrapper(sock)
  sock:settimeout(0) -- do not block
  local data,msg = recv_loop(sock, HEADER_LEN)
  if not data then return false,msg end
  local len  = binarizer.decode.uint32(data)
  local data,msg = recv_loop(sock, len)
  if not data then return false,msg end
  return data
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local logger_methods,
logger_class_metatable = class("common.logger")

function logger_class_metatable:__call(stdout,stderr)
  if stdout == nil then stdout = io.stdout end
  if stderr == nil then stderr = io.stderr end  
  local obj = { stdout = stdout, stderr = stderr }
  return class_instance(obj,self,true)
end

function logger_methods:debug(...)
  if self.stderr then
    --
  end
end

function logger_methods:debugf(format,...)
  if self.stderr then
    -- self.stderr:write(string.format(format, ...))
  end
end

function logger_methods:warningf(format,...)
  if self.stderr then
    self.stderr:write(string.format(format, ...))
  end
end

function logger_methods:print(...)
  if self.stdout then
    local arg = table.pack(...)
    self.stdout:write("#\t" .. table.concat(arg,"\t") .. "\n")
  end
end

function logger_methods:raw_print(...)
  if self.stdout then
    self.stdout:write(table.concat(arg,"\t") .. "\n")
  end
end

function logger_methods:printf(format,...)
  if self.stdout then
    self.stdout:write(string.format("#\t"..format, ...))
  end
end

function logger_methods:raw_printf(format,...)
  if self.stdout then
    self.stdout:write(string.format(format, ...))
  end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function common.make_connection_handler(select_handler,message_reply,
					connections)
  return function(conn,data)
    local action
    local receive_at_end = true
    if data then
      action,data = data:match("^([^%s]*)(.*)$")
      if message_reply[action] == nil then
	select_handler:send(conn, "UNKNOWN ACTION")
      elseif type(message_reply[action]) == "string" then
	select_handler:send(conn, message_reply[action])
      else
	local ans = message_reply[action](conn, data)
	if ans == nil then receive_at_end = false
	else select_handler:send(conn, ans)
	end
      end
      if action == "EXIT" then
	-- following instruction allows chaining of several actions
	select_handler:close(conn, function() connections:mark_as_dead(conn) end)
      elseif receive_at_end then
	-- following instruction allows chaining of several actions
	select_handler:receive(conn,
			       common.make_connection_handler(select_handler,
							      message_reply,
							      connections))
      end
    end
  end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local select_methods,select_class_metatable=class("common.select_handler")

function select_class_metatable:__call()
  local obj =  {
    data = {},
    recv_query  = {},
    send_query  = {},
  }
  return class_instance(obj,self,true)
end

function select_methods:clean(conn)
  self.data[conn]       = nil
  self.recv_query[conn] = nil
  self.send_query[conn] = nil
end

function select_methods:accept(conn, func)
  local func = func or function() end
  self.recv_query[conn] = true
  self.data[conn] = self.data[conn] or {}
  table.insert(self.data[conn],
	       {
		 op   = "accept",
		 func = func,
	       })
end

function select_methods:receive(conn, func)
  local func = func or function() end
  self.recv_query[conn] = true
  self.data[conn] = self.data[conn] or {}
  table.insert(self.data[conn],
	       {
		 op = "receive",
		 co = coroutine.create(function()
					 return func(conn,common.recv_wrapper(conn))
				       end),
	       })
end

function select_methods:send(conn, func)
  local func = func or function() end
  if type(func) == "string" then
    local str = func
    func = function() return str end
  end
  self.send_query[conn] = true
  self.data[conn] = self.data[conn] or {}
  table.insert(self.data[conn],
	       {
		 op = "send",
		 co = coroutine.create(function()
					 return common.send_wrapper(conn,func())
				       end),
	       })
end

function select_methods:close(conn, func)
  local func = func or function() end
  if type(func) == "string" then func = function() return func end end
  self.data[conn] = self.data[conn] or {}
  table.insert(self.data[conn],
	       { op = "close", func=func })
end

local process = {
  
  receive = function(conn,co,recv_map,send_map)
    if recv_map[conn] then
      local ok,ret,msg = coroutine.resume(co)
      local msg = msg or ret
      assert(ok, "Error in receive function: " .. tostring(msg))
      if msg == "timeout" then return false end
      recv_map[conn] = nil
      -- TODO: make an error message when closing
      if msg == "closed" then return "close" end
      -- TODO: check error
      return true
    end
    return false
  end,
  
  accept = function(conn,func,recv_map,send_map)
    if recv_map[conn] then
      conn:settimeout(0)
      local new_conn,msg = conn:accept()
      if msg == "timeout" then return false end
      if not new_conn then
	fprintf(io.stderr, "Error at accept function: %s\n", msg)
	return false
      end
      func(conn, new_conn)
      recv_map[conn] = nil
      return true
    end
    return false
  end,
  
  send = function(conn,co,recv_map,send_map)
    if send_map[conn] then
      local ok,msg = coroutine.resume(co)
      assert(ok, "Error in send function: " .. tostring(msg))
      if msg == "timeout" then return false end
      send_map[conn] = nil
      -- TODO: make an error message when closing
      if msg == false then return "close" end
      -- TODO: check error
      return true
    end
    return false
  end,
  
  close = function(conn,func,recv_map,send_map)
    conn:close()
    func(conn)
    return "close"
  end,
}


function select_methods:execute(timeout)
  local clock = util.stopwatch()
  clock:go()
  local cpu,wall = clock:read()
  local next_query
  repeat
    next_query = false
    local recv_list = iterator(pairs(self.recv_query)):select(1):table()
    local send_list = iterator(pairs(self.send_query)):select(1):table()
    --
    local recv_list,send_list,msg = socket.select(recv_list, send_list,
						  timeout)
    if msg == "timeout" then break end
    local recv_map = recv_list -- table.invert(recv_list)
    local send_map = send_list -- table.invert(send_list)
    --
    for conn,data in pairs(self.data) do
      if #data == 0 then
	self.send_query[conn] = nil
	self.recv_query[conn] = nil
	self.data[conn] = nil
      else
	local d = data[1]
	local processed = process[d.op](conn,d.func or d.co,recv_map,send_map)
	if processed == "close" then
	  self.data[conn] = nil
	  self.recv_query[conn] = nil
	  self.send_query[conn] = nil
	elseif processed then table.remove(self.data[conn], 1)
	end
      end
      --
      iterator(ipairs(self.data[conn] or {})):select(2):field("op"):
      apply(function(v)
	      if v=="accept" then
		self.recv_query[conn] = true
	      elseif v=="receive" then
		self.recv_query[conn] = true
		next_query = true
	      elseif v == "send" then
		self.send_query[conn] = true
		next_query = true
	      end
	    end)
    end
    cpu,wall = clock:read()
  until not next_query or wall > timeout
end

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

local connections_set_methods,
connections_set_class_metatable = class("common.connections_set")

function connections_set_class_metatable:__call()
  local obj = { connections = {}, dead_connections = {} }
  return class_instance(obj,self,true)
end

function common.connections_set.connect(address,port)
  local ok,error_msg,s,data = true
  s,error_msg = socket.tcp()
  if not s then fprintf(io.stderr, "ERROR: %s\n", error_msg) return false,error_msg end
  ok,error_msg=s:connect(address,port)
  if not ok then fprintf(io.stderr, "ERROR: %s\n", error_msg) return false,error_msg end
  return s
end

-- creates a new coroutine and adds it to the previous table
function connections_set_methods:add(conn)
  table.insert(self.connections, conn)
end

function connections_set_methods:mark_as_dead(conn)
  self.dead_connections[conn] = true
end

function connections_set_methods:remove_dead_conections()
  -- list of connections to be removed (by index)
  local remove = iterator(ipairs(self.connections)):
  filter(function(k,v) return self.dead_connections[v] end):select(1):
  reduce(table.insert, {})
  -- remove the listed connections
  for i=#remove,1,-1 do
    local pos = remove[i]
    self.dead_connections[pos] = nil
    table.remove(self.connections, pos)
  end
end

function connections_set_methods:close()
  iterator(ipairs(self.connections)):apply(function(i,c)c:close()end)
  self.connections = {}
  self.dead_connections = {}
end
