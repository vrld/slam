local socket = require 'socket'
assert(common and common.class, "A Class Commons implementation is required")

-- TODO: more serializers
local function is_serializable(t,v)
	return t == "number" or
	       t == "boolean" or
	       t == "string" or
	       t == "nil" or
	       (getmetatable(v) or {}).__tostring ~= nil
end

local function serialize(...)
	local args = {n = select('#', ...), ...}
	local serialized = {}
	for i = 1,args.n do
		local t, v = type(args[i]), args[i]
		if not is_serializable(t,v) then
			error(("Cannot serialize values of type `%s'."):format(t))
		end
		serialized[i] = ("%s<%s>"):format(t,tostring(v))
	end
	return table.concat(serialized, ",")
end

local converter = {
	['nil'] = function() return nil end,
	string  = function(v) return v end,
	number  = tonumber,
	boolean = function(v) return v == 'true' end,
}
local function deserialize_helper(iter)
	local token = iter()
	if not token then return end

	local t,v = token:match('(%w+)(%b<>)')
	return (converter[t] or error)(v:sub(2,-2)), deserialize_helper(iter)
end
local function deserialize(str)
	return deserialize_helper(str:gmatch('%w+%b<>'))
end

--
-- RPC SERVER
--
local server = {}

local function capabilities(self, pattern)
	pattern = pattern or ".*"
	local ret = {}
	for name, _ in pairs(self.registry) do
		if name:match(pattern) then
			ret[#ret+1] = name
		end
	end
	return table.concat(ret, "\n")
end

function server:init(port, address)
	port = port or 0
	address = address or '*'
	self.socket = assert(socket.bind(address, port))
	self.socket:settimeout(0)
	self.address, self.port = self.socket:getsockname()
	self.registry = {}

	function self.registry.capabilities(...) return capabilities(self, ...) end
end

function server:register(name, func)
	assert(name, "Missing argument: `name'")
	assert(func, "Missing argument: `func'")
	self.registry[name] = func
end

function server:remove(name)
	assert(name, "Missing argument: `name'")
	self.registry[name] = nil
end

function server:defined(name)
	assert(name, "Missing argument: `name'")
	return self.registry[name] ~= nil
end

local function execute(self, func, args)
	if not self.registry[func] then
		return false, ("Tried to execute unknown function `%s'"):format(func)
	end

	return (function(pcall_ok, ...)
		if pcall_ok then
			return true, serialize(...)
		end
		return false, ...
	end)(pcall(self.registry[func], deserialize(args)))
end

function server:serve()
	assert(self.socket, "Server socket not initialized")

	local client,err = self.socket:accept()
	if client then
		local line = client:receive('*l')
		local bytes = tonumber(line:match('^RPC:(%d+)$'))
		if bytes then
			line = client:receive(bytes)
			local token, func, args = line:match('^([^:]+):([^:]+):(.*)%s*')
			if token and func and args then
				local ok, ret = execute(self, func, args)
				local str = ("RPC:%s:%s:%s\r\n"):format(token, tostring(ok), ret)
				client:send(str)
			end
		end
		client:close()
	elseif not client and err ~= 'timeout' then
		error(err)
	end
end

--
-- RPC CLIENT
--
local client = {}

function client:init(address, port)
	assert(address and port, "Need server address and port")
	self.address, self.port = address, port
	self.workers = {}
	self.on_success = print
	self.on_failure = error
	self.rpc = setmetatable({}, {__index = function(_,func)
		return function(...) return self:call(func, self.on_success, self.on_failure,...) end
	end})
end

local function query(self, func, args)
	local client = socket.tcp()
	client:settimeout(10)
	local _, err = client:connect(self.address, self.port)
	if err then
		return false, ("Cannot connect to %s[%s]: %s"):format(self.address, self.port, err)
	end
	client:settimeout(0)

	local token = ("%d-%s"):format(os.time(), math.random())
	local str = ("%s:%s:%s\r\n"):format(token, func, args)

	_, err = client:send(("RPC:%d\r\n"):format(str:len()))
	if err then
		client:close()
		return false, ("Cannot send query header to %s[%s]: %s"):format(self.address, self.port, err)
	end

	_, err = client:send(str)
	if err then
		client:close()
		return false, ("Cannot send query message to %s[%s]: %s"):format(self.address, self.port, err)
	end

	local lines = {}
	while true do
		local line, err = client:receive('*l')
		if line then
			lines[#lines+1] = line
		elseif err == "closed" then
			local ret = table.concat(lines,'\n')
			local ret_token, success, values = ret:match("^RPC:([^:]+):([^:]+):(.*)%s*$")
			if not (ret_token and success and values) then
				return false, ("Malformated answer: `%s'"):format(ret)
			end

			if ret_token == token then
				return (success == 'true'), values
			else
				return false, ("Token mismatch: expected `%s', got `%s'"):format(token, ret_token)
			end
		end
		-- err == 'timeout'
		coroutine.yield()
	end
end

function client:call(func, on_success, on_failure, ...)
	local args = serialize(...)
	local q = coroutine.create(function() return query(self, func, args) end)
	local worker = function()
		local coroutine_ok, call_ok, returns = coroutine.resume(q)
		if coroutine_ok and call_ok ~= nil and returns ~= nil then
			if call_ok then
				on_success(deserialize(returns))
			else
				on_failure(returns)
			end
			return false
		end
		return coroutine_ok
	end
	self.workers[worker] = worker
end

function client:dispatch()
	local to_remove = {}
	for _, worker in pairs(self.workers) do
		if not worker() then
			to_remove[worker] = worker
		end
	end

	for _, worker in pairs(to_remove) do
		self.workers[worker] = nil
	end
end

--
-- THE MODULE
--
return {
	server = common.class("RPC.server", server),
	client = common.class("RPC.client", client),
}
