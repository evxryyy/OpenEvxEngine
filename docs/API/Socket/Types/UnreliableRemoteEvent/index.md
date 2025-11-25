## Getting Started

All information for creating UnreliableRemoteEvents with `Socket` will be here.

!!! Note
    UnreliableRemoteEvents may drop packets and don't guarantee delivery order and
    has a 1000 byte limit.

----

## Examples

- @Server

```luau linenums="1"
local Socket = require(somewhere.Socket)

--I recommend to put ': Socket.BufferSchema' for intellisense
local UnreliableRemoteSchema : Socket.BufferSchema = {
	Money = "Float64",
}

-- Create a new SocketUnreliableRemote (server-side UnreliableRemoteEvent wrapper)
-- Parameters:
--   "Test" - Unique name for this event endpoint
--   Schema table - Defines expected data structure from clients
--     Money: expects a 64-bit floating point number (double precision)
local UnreliableRemote = Socket.Server.UnreliableRemote.Create("Test",UnreliableRemoteSchema)

-- Set up a listener to handle events fired by clients
-- The handler receives:
--   player: Player who fired the event
--   valueSchema: Deserialized data sent by client (validated against schema above)
UnreliableRemote:Connect(function(player, valueSchema)
	-- Print received data for debugging/logging
	-- Example output: [Player] {Money = 99.99}
	print(player, valueSchema)
end)
```

- @Client

```luau linenums="1"
local Socket = require(somewhere.Socket)

-- Find the existing UnreliableRemoteEvent created by the server
-- Parameters:
--   "Test" - Name of the UnreliableRemoteEvent (must match server's name)
--   Schema table - Defines expected data structure for this event
--     Money: expects a 64-bit floating point number (double precision)
local UnreliableRemote = Socket.Client.UnreliableRemote.Find("Test",{
	Money = "Float64";  -- Must match schema defined on server
})

-- Fire an event to the server with data
-- Parameter:
--   {Money = 15.155} - Data to send to server (must match schema above)
-- Note: This is "fire-and-forget" - no response is expected or returned
UnreliableRemote:Fire({
	Money = 15.155  -- Send money value to server
})
```

This will create a Buffer Networking using UnreliableRemoteEvent

----

## Methods

----

### Server

#### UnreliableRemote.Create()

`UnreliableRemote.Create(Name,Schema)`

```luau linenums="1"
local UnreliableRemote = Socket.Server.UnreliableRemote.Create("Test",UnreliableRemoteSchema)
or
local UnreliableRemote = Socket.Server.BuildUnreliableRemote("Test",UnreliableRemoteSchema)
```

Creates a new UnreliableRemoteEvent and wraps it in a SocketUnreliableRemote component

- @param SocketName: Unique name for the UnreliableRemoteEvent
- @param Schema: Buffer schema for data validation/serialization
- @return: New SocketUnreliableRemote component

----

#### UnreliableRemote.FireClient()

`UnreliableRemote.FireClient(Player,...)`

Fires data to a specific client through the UnreliableRemoteEvent

- Note: Delivery is not guaranteed and packets may be dropped
- @param Player: Target player to send data to
- @param values: Data to send (must match Schema structure)

!!! warning
    Please see the examples for firing data to the server/client.

----

#### UnreliableRemote.FireAll()

`UnreliableRemote.FireAll(...)`

Fires data to a specific client through the UnreliableRemoteEvent
 	
- Note : Delivery is not guaranteed - use for non-critical updates
 
- @param Player : Target player to send data to
- @param values : Data to send (must match Schema structure)

----

#### UnreliableRemote.Connect()

`UnreliableRemote.Connect((Player : Player,values : Buffer.BufferSchemaValue) -> ())`

Connects a callback to handle events from clients

- Note: Events may arrive out of order or be dropped entirely
- @param callback: Function to process client events

----

#### UnreliableRemote.ClearConnections()

`UnreliableRemote.ClearConnections()`

Disconnects all active connections

----

#### UnreliableRemote.Destroy()

`UnreliableRemote.Destroy()`

Destroys the component and its UnreliableRemoteEvent

----

### Client

----

#### UnreliableRemote.Find()

`UnreliableRemote.Find(Name : string,Schema)`

```luau linenums="1"
-- Find the existing UnreliableRemoteEvent created by the server
-- Parameters:
--   "Test" - Name of the UnreliableRemoteEvent (must match server's name)
--   Schema table - Defines expected data structure for this event
local UnreliableRemote = Socket.Client.UnreliableRemote.Find("Test",UnreliableRemoteSchema)
```

Finds an existing UnreliableRemoteEvent created by the server and wraps it

- @param SocketName: Name of the UnreliableRemoteEvent to find
- @param Schema: Buffer schema for data validation/serialization
- @return: SocketUnreliableRemote component wrapping the UnreliableRemoteEvent

----

#### UnreliableRemote.Fire()

`UnreliableRemote.Fire(...)`

Fires data to the server through the UnreliableRemoteEvent

- Note: Delivery is not guaranteed and packets may be dropped
- @param values: Data to send (must match Schema structure)

!!! warning
    Please see the examples for firing data to the server/client.

----

#### UnreliableRemote.Connect()

`UnreliableRemote.Connect(callback : (values) -> ())`

```luau linenums="1"
-- Set up a listener to handle events fired by the server
-- The handler receives:
--   valueSchema: Deserialized data sent by client (validated against schema above)
UnreliableRemote:Connect(function(valueSchema)
	-- Print received data for debugging/logging
	print(player, valueSchema)
end)
```

Connects a callback to handle events from the server

- Note: Events may arrive out of order or be dropped entirely
- @param callback: Function to process server events

----

#### UnreliableRemote.ClearConnections()

`UnreliableRemote.ClearConnections()`

Disconnects all active connections

----

#### UnreliableRemote.Destroy()

`UnreliableRemote.Destroy()`

Destroys the component and its UnreliableRemoteEvent

----

### Server alias

```luau linenums="1"
-- Aliases for different naming preferences
SocketUnreliableRemoteConstructor.create = SocketUnreliableRemoteConstructor.Create
SocketUnreliableRemoteConstructor.new = SocketUnreliableRemoteConstructor.Create
SocketUnreliableRemoteConstructor.New = SocketUnreliableRemoteConstructor.Create

SocketUnreliableRemote.fireClient = SocketUnreliableRemote.FireClient
SocketUnreliableRemote.fireAll = SocketUnreliableRemote.FireAll
SocketUnreliableRemote.connect = SocketUnreliableRemote.Connect
SocketUnreliableRemote.Disconnects = SocketUnreliableRemote.ClearConnections
SocketUnreliableRemote.disconnects = SocketUnreliableRemote.ClearConnections
SocketUnreliableRemote.destroy = SocketUnreliableRemote.Destroy
SocketUnreliableRemote.Clean = SocketUnreliableRemote.Destroy
SocketUnreliableRemote.clean = SocketUnreliableRemote.Destroy
```

----

### Client alias

```luau linenums="1"
-- Aliases for different naming preferences
SocketUnreliableRemoteConstructor.find = SocketUnreliableRemoteConstructor.Find
SocketUnreliableRemoteConstructor.get = SocketUnreliableRemoteConstructor.Find
SocketUnreliableRemoteConstructor.Get = SocketUnreliableRemoteConstructor.Find

SocketUnreliableRemote.fire = SocketUnreliableRemote.Fire
SocketUnreliableRemote.connect = SocketUnreliableRemote.Connect
SocketUnreliableRemote.Disconnects = SocketUnreliableRemote.ClearConnections
SocketUnreliableRemote.disconnects = SocketUnreliableRemote.ClearConnections
SocketUnreliableRemote.destroy = SocketUnreliableRemote.Destroy
SocketUnreliableRemote.Clean = SocketUnreliableRemote.Destroy
SocketUnreliableRemote.clean = SocketUnreliableRemote.Destroy
```

----
