## Getting Started

On this page you will learn how to create and connect an UnreliableRemoteEvent from both the client and server side.

----

## Examples

- @Server

```luau linenums="1"
local Nexus = require(somewhere.Nexus)

local MyUnreliableRemoteEvent = Nexus.Server.UnreliableRemoteEvent.new("MyUnreliableRemoteEvent")

MyUnreliableRemoteEvent:Connect(function(player,...)
	print("Player fired MyUnreliableRemoteEvent with args:", ...)
end)
```

- @Client

```luau linenums="1"
local Nexus = require(somewhere.Nexus)

local MyUnreliableRemoteEvent = Nexus.Client.UnreliableRemoteEvent.new("MyUnreliableRemoteEvent")

MyUnreliableRemoteEvent:Fire("Hello World",10)
```

This will print "Player fired MyUnreliableRemoteEvent with args ..."

----

## Methods

----

### UnreliableRemoteEvent.new() (Constructor)

`UnreliableRemoteEvent.new(name : string)`

@Server

Creates a new UnreliableRemoteEvent wrapper instance for server-side usage

- @param Name: The name of the UnreliableRemoteEvent to wrap
- @return: New UnreliableRemoteEventComponent instance
- @error: Throws if called from client

---

@Client

Creates a new UnreliableRemoteEvent wrapper instance

- @param Name: The name of the UnreliableRemoteEvent to wrap
- @return: New UnreliableRemoteEventComponent instance
- @error: Throws if called from server or if UnreliableRemoteEvent not found

----

### UnreliableRemoteEvent:Connect()

@Server

`UnreliableRemoteEvent:Connect(callback: (Player, T...) -> ()): () -> ()`

Creates a persistent connection to handle client events

- @param callback: Function to execute when event is received from client (includes Player parameter)
- @return: Disconnect function to remove the connection

----

@Client

`UnreliableRemoteEvent:Connect(callback: (T...) -> ()): () -> ()`

Creates a persistent connection to the UnreliableRemoteEvent

- @param callback: Function to execute when event is received from server
- @return: Disconnect function to remove the connection

----

### UnreliableRemoteEvent:Fire()

@Server

`UnreliableRemoteEvent:Fire(Player: Player, ...: T...)`

Fires the UnreliableRemoteEvent to a specific client

- @param Player: Target player to send the event to
- @param ...: Variable arguments to send to client

----

@Client

`UnreliableRemoteEvent:Fire(...: T...)`

Fires the UnreliableRemoteEvent to the server

- @param ...: Variable arguments to send to server

----

### UnreliableRemoteEvent:Once()

@Server

`UnreliableRemoteEvent:Once(callback: (Player, T...) -> ())`

Creates a one-time connection that auto-disconnects after first trigger

- @param callback: Function to execute once when event is received from client

----

@Client

`UnreliableRemoteEvent:Once(callback: (T...) -> ())`

Creates a one-time connection that auto-disconnects after first trigger

- @param callback: Function to execute once when event is received

----

### UnreliableRemoteEvent:DisconnectAll()

`UnreliableRemoteEvent:DisconnectAll()`

Disconnects all active connections for this UnreliableRemoteEvent

----

### UnreliableRemoteEvent:Destroy()

`UnreliableRemoteEvent:Destroy()`

Destroys the UnreliableRemoteEvent wrapper and cleans up all resources

----

## Alias

```luau linenums="1"
-- Constructor method aliases
Constructor.find = Constructor.new
Constructor.get = Constructor.new
Constructor.Get = Constructor.new
Constructor.Find = Constructor.new
Constructor.New = Constructor.new

-- Component method aliases (camelCase convention)
Component.connect = Component.Connect
Component.fire = Component.Fire
Component.destroy = Component.Destroy
Component.once = Component.Once
Component.disconnectAll = Component.DisconnectAll
```
