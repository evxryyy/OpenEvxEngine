## Socket

## What next

## Logs

Version : 1.0
- Released the module.

## Examples

### RemoteEvent
```lua
-- SERVER SIDE

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

-- CLIENT SIDE

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

