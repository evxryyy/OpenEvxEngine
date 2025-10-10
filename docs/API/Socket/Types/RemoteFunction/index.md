## Getting Started

To properly handle remote functions with `Socket`, everything will be explained here.

----

## Examples

- @Server

```luau linenums="1"
local Socket = require(somewhere.Socket)

--I recommend to put ': Socket.BufferSchema' for intellisense
local FunctionSchema : Socket.BufferSchema = {
	Message = "String8";  -- Client must send a table with {Message = "some string"}
}

-- Create a new SocketFunction (server-side RemoteFunction wrapper)
-- Parameters:
--   "TestFunc" - Unique name for this function endpoint
--   Schema table - Defines expected data structure from client
--     Message: expects a string (up to 8 bytes/chars, based on Buffer implementation)
local Function = Socket.Server.Function.Create("TestFunc",FunctionSchema)

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

- @Client

```luau linenums="1"
local Socket = require(somewhere.Socket)

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

This will create a Buffer Networking using RemoteFunction

----

## Methods

----

### Server

#### RemoteFunction.Create()

`RemoteFunction.Create(Name,Schema)`

```luau linenums="1"
local Function = Socket.Server.Function.Create("TestFunc",FunctionSchema)
```

Creates a new RemoteFunction and wraps it in a SocketFunction component

- @param SocketName: Unique name for the RemoteFunction
- @param InvokeSchema: Buffer schema for validating/deserializing client data
- @return: New SocketFunction component

----

#### RemoteFunction.InsertHandle()

`RemoteFunction.InsertHandle(callback : (Player,Values) -> (Buffer.BufferSchema,Buffer.BufferSchemaValue))`

Sets up handler for client invokes (OnServerInvoke)

- @param callback: Function to process client requests

----

#### RemoteFunction.RemoveHandler()

`RemoteFunction.RemoveHandler()`

Remove the current listener of OnServerInvoke

----

#### RemoteFunction.FireClient()

`RemoteFunction.FireClient`

```luau linenums="1"
--@Server

local age = Function:FireClient(game.Players:GetPlayers()[1],{
	Message = "Anything" -- 8 characters 'String8' , see the examples 
},Schema)

warn(age) --> the random generated number

--@Client

--@OnClientInvoke Listener
Remote:InsertHandle(function(invokeValueSchema)
	local ageSchema : Socket.BufferSchema = {
		Age = "U8" -- unsigned int 8-bit
	}
	local values = {
		Age = math.random(0,255) % 255 + 1 --> random number (0-255)
	}
	return ageSchema,values --> the order is really important.
end)
```

Invokes a specific client with buffer-serialized data

- @param Player: Target player to invoke
- @param InvokeValueSchema: Data to send (must match InvokeSchema)
- @param ReturnSchema: Schema for deserializing client's response
- @return: Deserialized response from client, or nil on timeout/error

----

#### RemoteFunction.SetTimeout()

```luau linenums="1"
RemoteFunction.SetTimeout(n : number)
```

Sets timeout duration for InvokeClient operations

- @param value: Timeout in seconds (converted to positive)

----

#### RemoteFunction.Destroy()

`RemoteFunction.Destroy()`

Destroys the component and its RemoteFunction

----

### Client

----

#### RemoteFunction.Find()

`RemoteFunction.Find(Name,Schema)`

Finds an existing RemoteFunction created by the server and wraps it

- @param SocketName: Name of the RemoteFunction to find
- @param InvokeSchema: Buffer schema for data validation/serialization
- @return: SocketFunction component wrapping the RemoteFunction

----

#### RemoteFunction.Fire()

!!! Warning
    See the [Examples](#examples) to see the code example or just go to [FireClient](#remotefunctionfireclient)


Invokes the server's OnServerInvoke handler with buffer-serialized data

- @param InvokeValueSchema: Data to send (must match InvokeSchema structure)
- @param ReturnSchema: Schema for deserializing server's response
- @return: Deserialized response from server, or nil on timeout/error

----

#### RemoteFunction.InsertHandle()

`RemoteFunction.InsertHandle(callback : (Values) -> (Buffer.BufferSchema,Buffer.BufferSchemaValue))`

Sets up handler for when server invokes this client

- Only used if server calls InvokeClient on this RemoteFunction
- @param callback: Function to handle server invokes

----

#### RemoteFunction.RemoveHandler()

`RemoteFunction.RemoveHandler()`

Remove the current listener of OnClientInvoke

----

#### RemoteFunction.SetTimeout()

```luau linenums="1"
RemoteFunction.SetTimeout(n : number)
```

Configures timeout for InvokeServer operations

- @param value: Timeout in seconds (converted to positive)

----

#### RemoteFunction.Destroy()

`RemoteFunction.Destroy()`

Cleans up the component (does not destroy the RemoteFunction)

----