**Lua-RPC** is a simple premote procedure call protocol implemented in Lua. This
is meant to be a proof of concept. Please don't use it in productive environments.


Dependencies
============

- luasocket: http://w3.impa.br/~diego/software/luasocket/
- any class commons enabled class library: https://github.com/bartbes/Class-Commons
  --> hump.class is included

Usage example
=============

server.lua:

    require 'class' -- any class commons enabled library
    local RPC = require 'rpc'
    
    -- open server at port 12345 on localhost
    server = RPC.server(12345, '127.0.0.1')
    
    -- register 'print' function as remotely callable
    server:register('print', print)
    
    -- register a function that returns a value
    server:register('twice', function(x) return 2 * x end)
    
    -- yet another way to define callable functions
    function server.registry.thrice(x) return 3 * x end
    
    -- run the server
    while true do
        server:serve()
    end


client.lua:

    require 'class'
    local RPC = require 'rpc'
    
    -- create new client to call functions from server at localhost:12345
    client = RPC.client('127.0.0.1', 12345)
    
    -- set actions what to do on success/failure of the remote call.
    -- these are the defaults
    client.on_success = print
    client.on_failure = error
    
    -- queue some functions
    client.rpc.print("Hello world!\nHello remote server!")
    client.rpc.twice(2)
    
    -- you can also define function-specific callbacks.
    -- prototype is client:call(function_name, on_success, on_failure, ...)
    client:call('thrice', function(result) print('3 * 2 = ', result) end, function(err) print("RPC error:", err), 3)

