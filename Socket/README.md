## Socket

## What next

## Logs

Version : 1.3
- Added `Socket.Function.InvokeAll` (See API).
- Added `Socket.Remote.FireAll` and `Socket.UnreliableRemote.FireAll` (See API).
- Reviewed all comments and the api for better understanding.
- Now if you put an empty Schema for all remote types it will no longer have the 2 extra bytes.
```lua
ex:

--@Before
MyRemoteEvent:FireClient(Player,{}) --> 16 bytes

--@After
MyRemoteEvent:FireClient(Player,{}) --> 14 bytes
```

----

Version : 1.2
- added extended method for all remote type
```lua
--@Client
SocketClient.GetRemote<T...>(SocketName : string, Schema : Buffer.BufferSchema) --> equivalent to Socket.Client.Remote.get()
SocketClient.GetFunction<T...>(SocketName : string, Schema : Buffer.BufferSchema) --> equivalent to Socket.Client.Function.get()
SocketClient.GetUnreliableRemote<T...>(SocketName : string, Schema : Buffer.BufferSchema) --> equivalent to Socket.Client.UnreliableRemote.get()

SocketClient.GetExtendedRemote<T...>(Configuration : extendedRemoteConfiguration) --> [[
--[[
	local Remote = Socket.Client.GetExtendedRemote({
		SocketName = "HelloWorld",
		Schema = {Message = "String8"},
		ConnectionCallback = function(values)
			print(values)
		end,
	})
	same as
	local Remote = Socket.Client.Remote.get("HelloWorld",{Message = "String8"})
	Remote:Connect(func)
]]
Socket.Client.GetExtendedFunction<T...>(Configuration : extendedFunctionConfiguration) --> equivalent but for RemoteFunction
Socket.Client.GetExtendedUnreliableRemote<T...>(Configuration : extendedRemoteConfiguration) --> equivalent but for UnreliableRemoteEvent

--@Server
SocketServer.BuildRemote<T...>(SocketName : string, Schema : Buffer.BufferSchema) --> equivalent to Socket.Server.Remote.Create()
SocketServer.BuildFunction<T...>(SocketName : string, Schema : Buffer.BufferSchema) --> equivalent to Socket.Server.Function.Create()
SocketServer.BuildUnreliableRemote<T...>(SocketName : string, Schema : Buffer.BufferSchema) --  equivalent to Socket.Server.UnreliableRemote.Create()

SocketServer.BuildExtendedRemote<T...>(Configuration : extendedRemoteConfiguration) --> [[
--[[
	local Remote = Socket.Server.BuildExtendedRemote({
		SocketName = "Test",
		Schema = {Money = "Float64"},
		ConnectionCallback = function(player, valueSchema)
			print(player, valueSchema)
		end
	})
	same as
	local Remote = Socket.Server.Remote.Create("Test",{Money = "Float64"})
	Remote:Connect(func)
]]

Socket.Server.BuildExtendedFunction<T...>(Configuration : extendedFunctionConfiguration) --> equivalent but for RemoteFunction
Socket.Server.BuildExtendedUnreliableRemote<T...>(Configuration : extendedRemoteConfiguration) --> equivalent but for UnreliableRemoteEvent
```

Version : 1.1
- Fixed a bug where Socket was requiring Buffer module like this ```./Buffer``` instead of ```@self/Buffer```

Version : 1.0
- Released the module.

## Notes

- You can find disabled scripts inside you are free to remove it they are just for examples.
- For string data type that require more than 64 byte please use something like this :
  ```lua
	local schema : Socket.BufferSchema = {
		Value = {
			Type = "String",
			Length = 1024
		} -- This will require 1024 bytes
	}
  ```
- I also recommend to learn the Buffer module i made so you will know how its serialized and deserialized also you will know every type that you can write correctly.

## Examples

-----------

### RemoteFunction

-----------

Server : 

```lua
-- Import the Socket module (contains all networking utilities)
local Socket = require(path.to.Socket)

-- Create a new SocketFunction (server-side RemoteFunction wrapper)
-- Parameters:
--   "TestFunc" - Unique name for this function endpoint
--   Schema table - Defines expected data structure from client
--     Message: expects a string (up to 8 bytes/chars, based on Buffer implementation)
local Function = Socket.Server.Function.Create("TestFunc",{
	Message = "String8";  -- Client must send a table with {Message = "some string"}
})

-- Set up the server handler that will be called when a client invokes this function
-- The handler receives:
--   player: Player who invoked the function
--   invokeValueSchema: Deserialized data sent by client (validated against schema above)
Function:InsertHandle(function(player, invokeValueSchema)
	-- Define response schema - what data structure we'll send back to client
	local schema : Socket.BufferSchema = {
		Value = "I8"  -- Will send back an integer (8-bit)
	}
	-- Define actual response values matching the schema
	local value = {Value = 18}  -- Sends {Value = 18} back to client
	-- Return both schema and value - they'll be serialized and sent to client
	return schema, value
end)
```

---------

Client :

```lua
-- Import the Socket module (contains all networking utilities)
local Socket = require(path.to.Socket)

-- Find the existing RemoteFunction created by the server
-- Parameters:
--   "TestFunc" - Name of the RemoteFunction (must match server's name)
--   Schema table - Defines expected data structure for this function
--     Message: expects a string (up to 8 bytes/chars, based on Buffer implementation)
local Remote = Socket.Client.Function.Find("TestFunc",{
	Message = "String8",  -- Must match schema defined on server
})

-- Invoke the server function and wait for response
-- Parameters:
--   {Message = "Hello"} - Data to send to server (must match input schema)
--   {Value = "I8"} - Schema defining expected response structure from server
-- Returns: Deserialized response table or nil if timeout/error
local result = Remote:Fire({Message = "Hello"},{Value = "I8"})

-- Print the result received from server
-- Expected output: {Value = 18} (based on server example that returns {Value = 18})
print(result)
```

-----------

## RemoteEvent

-----------

Server : 

```lua
-- Import the Socket module (contains all networking utilities)
local Socket = require(path.to.Socket)

-- Create a new SocketRemote (server-side RemoteEvent wrapper)
-- Parameters:
--   "Test" - Unique name for this event endpoint
--   Schema table - Defines expected data structure from clients
--     Money: expects a 64-bit floating point number (double precision)
local Remote = Socket.Server.Remote.Create("Test",{
	Money = "Float64";  -- Clients must send data matching this schema: {Money = 123.45}
})

-- Set up a listener to handle events fired by clients
-- The handler receives:
--   player: Player who fired the event
--   valueSchema: Deserialized data sent by client (validated against schema above)
Remote:Connect(function(player, valueSchema)
	-- Print received data for debugging/logging
	-- Example output: [Player] {Money = 99.99}
	print(player, valueSchema)
end)
```

-----------

Client : 

```lua
-- Import the Socket module (contains all networking utilities)
local Socket = require(path.to.Socket)

-- Find the existing RemoteEvent created by the server
-- Parameters:
--   "Test" - Name of the RemoteEvent (must match server's name)
--   Schema table - Defines expected data structure for this event
--     Money: expects a 64-bit floating point number (double precision)
local Remote = Socket.Client.Remote.Find("Test",{
	Money = "Float64";  -- Must match schema defined on server
})

-- Fire an event to the server with data
-- Parameter:
--   {Money = 15.155} - Data to send to server (must match schema above)
-- Note: This is "fire-and-forget" - no response is expected or returned
Remote:Fire({
	Money = 15.155  -- Send money value to server
})
```

-----------

## UnreliableRemoteEvent

-----------

Server : 

```lua
-- WARNING: UnreliableRemoteEvents have a 1000 byte maximum payload size

-- Import the Socket module (contains all networking utilities)
local Socket = require(path.to.Socket)

-- Create a new SocketUnreliableRemote (server-side UnreliableRemoteEvent wrapper)
-- Parameters:
--   "Test" - Unique name for this unreliable event endpoint
--   Schema table - Defines expected data structure from clients
--     Money: expects a 64-bit floating point number (8 bytes)
local Remote = Socket.Server.UnreliableRemote.Create("Test",{
	Money = "Float64";  -- 8 bytes - well within 1000 byte limit
})

-- Set up a listener to handle unreliable events fired by clients
-- IMPORTANT: Some events may be dropped or arrive out of order
-- The handler receives:
--   player: Player who fired the event
--   valueSchema: Deserialized data sent by client (if packet arrived)
Remote:Connect(function(player, valueSchema)
	-- Print received data for debugging
	-- Note: This may not print every event sent by client due to packet loss
	print(player, valueSchema)
end)
```

-----------

Client :

```lua
-- WARNING: UnreliableRemoteEvents have a 1000 byte maximum payload size

-- Import the Socket module (contains all networking utilities)
local Socket = require(path.to.Socket)

-- Find the existing UnreliableRemoteEvent created by the server
-- Parameters:
--   "Test" - Name of the UnreliableRemoteEvent (must match server's name)
--   Schema table - Defines expected data structure for this event
--     Money: expects a 64-bit floating point number (8 bytes)
local Remote = Socket.Client.UnreliableRemote.Find("Test",{
	Money = "Float64";  -- 8 bytes - well within 1000 byte limit
})

-- Fire an unreliable event to the server
-- Parameter:
--   {Money = 15.155} - Data to send (must match schema)
-- IMPORTANT: This packet may be dropped and never reach the server
Remote:Fire({
	Money = 15.155  -- Send money value - may not arrive!
})
```
