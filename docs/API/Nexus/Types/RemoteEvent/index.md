## Getting Started

On this page you will learn how to create and connect a RemoteEvent from both the client and server side.

----

## Examples

- @Server

```luau linenums="1"
local Nexus = require(somewhere.Nexus)

local MyRemoteEvent = Nexus.Server.RemoteEvent.new("MyRemoteEvent")

MyRemoteEvent:Connect(function(player,...)
	print("Player fired MyRemoteEvent with args:", ...)
end)
```

- @Client

```luau linenums="1"
local Nexus = require(somewhere.Nexus)

local MyRemoteEvent = Nexus.Client.RemoteEvent.new("MyRemoteEvent")

MyRemoteEvent:Fire("Hello World",10)
```

This will print "Player fired MyRemoteEvent with args ..."

----

## Methods

----

### RemoteEvent.new() (Constructor)

`RemoteEvent.new(name : string)`

@Server
  
Creates a new RemoteEvent wrapper instance for server-side usage

- @param Name: The name of the RemoteEvent to wrap
- @return: New RemoteEventComponent instance
- @error: Throws if called from client

---

@Client

Creates a new RemoteEvent wrapper instance

- @param Name: The name of the RemoteEvent to wrap
- @return: New RemoteEventComponent instance
- @error: Throws if called from server or if RemoteEvent not found

----

### RemoteEvent:Connect()

@Server

`RemoteEvent:Connect(callback: (Player, T...) -> ()): () -> ()`

Creates a persistent connection to handle client events

- @param callback: Function to execute when event is received from client (includes Player parameter)
- @return: Disconnect function to remove the connection

----

@Client

`RemoteEvent:Connect(callback: (T...) -> ()): () -> ()`

Creates a persistent connection to the RemoteEvent

- @param callback: Function to execute when event is received from server
- @return: Disconnect function to remove the connection

----

### RemoteEvent:Fire()

@Server

`RemoteEvent:Fire(Player: Player, ...: T...)`

Fires the RemoteEvent to a specific client 

- @param Player: Target player to send the event to
- @param ...: Variable arguments to send to client

----

@Client

`RemoteEvent:Fire(...: T...)`

Fires the RemoteEvent to the server

- @param ...: Variable arguments to send to server

----

### RemoteEvent:Once()

@Server

`RemoteEvent:Once(callback: (Player, T...) -> ())`

Creates a one-time connection that auto-disconnects after first trigger

- @param callback: Function to execute once when event is received from client

----

@Client

`RemoteEvent:Once(callback: (T...) -> ())`

Creates a one-time connection that auto-disconnects after first trigger 

- @param callback: Function to execute once when event is received

----

### RemoteEvent:DisconnectAll()

`RemoteEvent:DisconnectAll()`

Disconnects all active connections for this RemoteEvent

----

### RemoteEvent:Destroy()

`RemoteEvent:Destroy()`

Destroys the RemoteEvent wrapper and cleans up all resources

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
