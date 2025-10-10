## Getting Started

On this page you will learn how to properly handle a RemoteFunction from both the client and server side.

----

## Examples

- @Server

```luau linenums="1"
local Nexus = require(somewhere.Nexus)

local MyRemoteFunction = Nexus.Server.RemoteFunction.new("MyRemoteFunction")

MyRemoteFunction:Handle(function(player, ...)
	print(player,...)
	return math.random(0,100)
end)
```

- @Client

```luau linenums="1"
local Nexus = require(somewhere.Nexus)

local MyRemoteFunction = Nexus.Client.RemoteFunction.new("MyRemoteFunction")

local num = MyRemoteFunction:Invoke("Give me my number !!")
print(num)
```

This will print and return the number generated on the server side.

----

## Methods

----

### RemoteFunction.new() (Constructor)

`RemoteFunction.new(name : string)`

@Server

Creates a new RemoteFunction wrapper instance for server-side usage

- @param Name: The name of the RemoteFunction to wrap
- @return: New RemoteFunctionComponent instance
- @error: Throws if called from client

----

@Client

Creates a new RemoteFunction wrapper instance
    
- @param Name: The name of the RemoteFunction to wrap
- @return: New RemoteFunctionComponent instance
- @error: Throws if called from server or if RemoteFunction not found

----

### RemoteFunction:Handle()

@Server

`RemoteFunction:Handle(callback: (Player, T...) -> T...)`

Sets the callback function to handle client invocations

- @param callback: Function to execute when invoked by client (includes Player parameter)
- @return: Self for method chaining

----

@Client

`RemoteFunction:Handle(callback: (T...) -> T...)`

Sets the callback function to handle server invocations

- @param callback: Function to execute when invoked by server
- @return: Self for method chaining

----

### RemoteFunction:Invoke()

@Server

`RemoteFunction:Invoke(Player,... : T...) : any`

Invokes the RemoteFunction on a specific client with timeout protection

- @param Player: Target player to invoke the function on
- @param ...: Variable arguments to send to client
- @return: Response from client or nil if timeout

----

@Client

`RemoteFunction:Invoke(... : T...) : any`

Invokes the RemoteFunction on the server with timeout protection

- @param ...: Variable arguments to send to server
- @return: Response from server or nil if timeout

----

### RemoteFunction:RemoveHandler()

`RemoteFunction:RemoveHandler()`

Removes the current handler function

- @return: Self for method chaining

----

### RemoteFunction:SetTimeout()

`RemoteFunction:SetTimeout(n : number)`

Sets the invocation timeout duration

- @param n: Timeout duration in seconds
- @return: Self for method chaining

----

### RemoteFunction:Destroy()

`RemoteFunction:Destroy()`

Destroys the RemoteFunction wrapper and cleans up all resources

----

## Alias

```luau lineums="1"
-- Constructor method aliases
Constructor.find = Constructor.new
Constructor.get = Constructor.new
Constructor.Get = Constructor.new
Constructor.Find = Constructor.new
Constructor.New = Constructor.new

-- Component method aliases (camelCase convention)
Component.invoke = Component.Invoke
Component.handle = Component.Handle
Component.destroy = Component.Destroy
Component.removeHandler = Component.RemoveHandler
Component.setTimeout = Component.SetTimeout
```