## Getting Started

All information for creating RemoteEvents with `Socket` will be here.

----

## Examples

- @Server

```luau linenums="1"
local Socket = require(somewhere.Socket)

--I recommend to put ': Socket.BufferSchema' for intellisense
local RemoteSchema : Socket.BufferSchema = {
	Money = "Float64",
}

-- Create a new SocketRemote (server-side RemoteEvent wrapper)
-- Parameters:
--   "Test" - Unique name for this event endpoint
--   Schema table - Defines expected data structure from clients
--     Money: expects a 64-bit floating point number (double precision)
local Remote = Socket.Server.Remote.Create("Test",RemoteSchema)

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

- @Client

```luau linenums="1"
local Socket = require(somewhere.Socket)

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

This will create a Buffer Networking using RemoteEvent

----

## Methods

----

### Server

#### Remote.Create()

`Remote.Create(Name,Schema)`

```luau linenums="1"
local Remote = Socket.Server.Remote.Create("Test",RemoteSchema)
or
local Remote = Socket.Server.BuildRemote("Test",RemoteSchema)
```

Creates a new RemoteEvent and wraps it in a SocketRemote component

- @param SocketName: Unique name for the RemoteEvent
- @param Schema: Buffer schema for data validation/serialization
- @return: New SocketRemote component

----

#### Remote.FireClient()

`Remote.FireClient(Player,...)`

Fires data to a specific client through the RemoteEvent

- @param Player : Target player to send data to
- @param values : Data to send (must match Schema structure)

!!! warning
    Please see the examples for firing data to the server/client.

----

#### Remote.FireAll()

`Remote.FireAll(...)`

Fires data to all clients through the RemoteEvent

@param values : Data to send to all clients (must match Schema structure)

!!! warning
    Please see the examples for firing data to the server/client.

----

#### Remote.Connect()

`Remote.Connect((Player : Player,ValueSchema : Buffer.BufferSchemaValue) -> ())`

Connects a callback to handle events from clients

- @param callback: Function to process client events

----

#### Remote.ClearConnections()

`Remote.ClearConnections()`

Disconnects all active connections

----

#### Remote.Destroy()

`Remote.Destroy()`

Destroys the component and its RemoteEvent

----

### Client

----

#### Remote.Find()

`Remote.Find(Name : string,Schema)`

```luau linenums="1"
-- Find the existing RemoteEvent created by the server
-- Parameters:
--   "Test" - Name of the RemoteEvent (must match server's name)
--   Schema table - Defines expected data structure for this event
local Remote = Socket.Client.Remote.Find("Test",RemoteSchema)
```

Finds an existing RemoteEvent created by the server and wraps it

- @param SocketName: Name of the RemoteEvent to find
- @param Schema: Buffer schema for data validation/serialization
- @return: SocketRemote component wrapping the RemoteEvent

----

#### Remote.Fire()

`Remote.Fire(ValueSchema)`

Fires data to the server through the RemoteEvent

- @param values : Data to send (must match Schema structure)

!!! warning
    Please see the examples for firing data to the server/client.

----

#### Remote.Connect()

`Remote.Connect(callback : (values) -> ())`

```luau linenums="1"
-- Set up a listener to handle events fired by the server
-- The handler receives:
--   valueSchema: Deserialized data sent by client (validated against schema above)
Remote:Connect(function(valueSchema)
	-- Print received data for debugging/logging
	print(player, valueSchema)
end)
```

Connects a callback to handle events from the server

- @param callback: Function to process server events

----

#### Remote.ClearConnections()

`Remote.ClearConnections()`

Disconnects all active connections

----

#### Remote.Destroy()

`Remote.Destroy()`

Destroys the component and its RemoteEvent

----

### Server alias

```luau linenums="1"
-- Aliases for different naming preferences
SocketRemoteConstructor.create = SocketRemoteConstructor.Create
SocketRemoteConstructor.new = SocketRemoteConstructor.Create
SocketRemoteConstructor.New = SocketRemoteConstructor.Create

SocketRemote.fireClient = SocketRemote.FireClient
SocketRemote.fireAll = SocketRemote.FireAll
SocketRemote.connect = SocketRemote.Connect
SocketRemote.Disconnects = SocketRemote.ClearConnections
SocketRemote.disconnects = SocketRemote.ClearConnections
SocketRemote.destroy = SocketRemote.Destroy
SocketRemote.Clean = SocketRemote.Destroy
SocketRemote.clean = SocketRemote.Destroy
```

----

### Client alias

```luau linenums="1"
-- Aliases for different naming preferences
SocketRemoteConstructor.find = SocketRemoteConstructor.Find
SocketRemoteConstructor.get = SocketRemoteConstructor.Find
SocketRemoteConstructor.Get = SocketRemoteConstructor.Find

SocketRemote.fire = SocketRemote.Fire
SocketRemote.connect = SocketRemote.Connect
SocketRemote.Disconnects = SocketRemote.ClearConnections
SocketRemote.disconnects = SocketRemote.ClearConnections
SocketRemote.destroy = SocketRemote.Destroy
SocketRemote.Clean = SocketRemote.Destroy
SocketRemote.clean = SocketRemote.Destroy
```

----
