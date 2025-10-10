## Getting Started

Most stuff of the lastest version of `Socket` that impact the module itself will be here.

----

## Extended Build/Get Methods

```luau linenums="1"
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

----