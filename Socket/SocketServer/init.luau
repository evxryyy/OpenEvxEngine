-- SocketServer Module - Server-side networking API aggregator
-- Provides unified access to all server-side Socket communication types
-- Usage: Socket.Server.Remote, Socket.Server.Function, Socket.Server.UnreliableRemote

-- Import server-side networking modules
local SocketUnreliableRemote = require('@self/SocketUnreliableRemote')  -- For unreliable, high-frequency events
local SocketFunction = require('@self/SocketFunction')                  -- For request-response communication
local SocketRemote = require('@self/SocketRemote')  -- For reliable one-way events

-- Used for type declaration
local Buffer = require('./Buffer')

-- Extended configuration type for server-side remote events with player parameter
type extendedRemoteConfiguration = {
	SocketName : string,           -- Name identifier for the socket connection
	Schema : Buffer.BufferSchema,  -- Data schema defining the structure of transmitted data
	ConnectionCallback : (Player : Player, ValueSchema : Buffer.BufferSchemaValue) -> ()  -- Callback function triggered when data is received from a player
}

-- Extended configuration type for server-side remote functions with player parameter
type extendedFunctionConfiguration = {
	SocketName : string,           -- Name identifier for the socket connection
	Schema : Buffer.BufferSchema,  -- Data schema defining the structure of transmitted data
	Timeout : number?,             -- Optional timeout value for function calls
	ConnectionCallback : (Player : Player, InvokeValueSchema : Buffer.BufferSchemaValue) -> (Buffer.BufferSchema, Buffer.BufferSchemaValue)  -- Callback for handling function invocations from players
}

-- Create the SocketServer namespace for server-side networking
local SocketServer = {}
SocketServer.__index = SocketServer

-- Creates a new remote event component on the server side
-- @param SocketName: Unique identifier for the remote event
-- @param Schema: Data structure definition for the remote event
-- @return: New SocketRemote component instance
function SocketServer.BuildRemote<T...>(SocketName : string, Schema : Buffer.BufferSchema) : SocketRemote.SocketRemoteComponent<T...>
	return SocketRemote.Create(SocketName, Schema)
end

-- Creates a new remote function component on the server side
-- @param SocketName: Unique identifier for the remote function
-- @param Schema: Data structure definition for the remote function
-- @return: New SocketFunction component instance
function SocketServer.BuildFunction<T...>(SocketName : string, Schema : Buffer.BufferSchema) : SocketFunction.SocketFunctionComponent<T...>
	return SocketFunction.Create(SocketName, Schema)
end

-- Creates a new unreliable remote event component on the server side
-- @param SocketName: Unique identifier for the unreliable remote event
-- @param Schema: Data structure definition for the unreliable remote event
-- @return: New SocketUnreliableRemote component instance
function SocketServer.BuildUnreliableRemote<T...>(SocketName : string, Schema : Buffer.BufferSchema) : SocketUnreliableRemote.SocketUnreliableRemoteComponent<T...>
	return SocketUnreliableRemote.Create(SocketName, Schema)
end

-- Creates an extended remote event component with additional configuration options on the server side
-- @param Configuration: Extended configuration object containing socket name, schema, and callback
-- @return: SocketRemote component with connection callback configured for player events
function SocketServer.BuildExtendedRemote<T...>(Configuration : extendedRemoteConfiguration) : SocketRemote.SocketRemoteComponent<T...>
	local Remote = SocketRemote.Create(Configuration.SocketName, Configuration.Schema)
	Remote:Connect(Configuration.ConnectionCallback)
	return Remote
end

-- Creates an extended remote function component with additional configuration options on the server side
-- @param Configuration: Extended configuration object containing socket name, schema, timeout, and callback
-- @return: SocketFunction component with timeout and connection callback configured for player invocations
function SocketServer.BuildExtendedFunction<T...>(Configuration : extendedFunctionConfiguration) : SocketFunction.SocketFunctionComponent<T...>
	local Function = SocketFunction.Create(Configuration.SocketName, Configuration.Schema)
	if Configuration.Timeout then
		Function:SetTimeout(Configuration.Timeout)
	end
	Function:Insert(Configuration.ConnectionCallback)
	return Function
end

-- Creates an extended unreliable remote event component with additional configuration options on the server side
-- @param Configuration: Extended configuration object containing socket name, schema, and callback
-- @return: SocketUnreliableRemote component with connection callback configured for player events
function SocketServer.BuildExtendedUnreliableRemote<T...>(Configuration : extendedRemoteConfiguration) : SocketUnreliableRemote.SocketUnreliableRemoteComponent<T...>
	local UnreliableRemote = SocketUnreliableRemote.Create(Configuration.SocketName, Configuration.Schema)
	UnreliableRemote:Connect(Configuration.ConnectionCallback)
	return UnreliableRemote
end

-- Each provides different communication patterns:
SocketServer.Remote = SocketRemote                      -- Reliable events (RemoteEvent wrapper)
SocketServer.UnreliableRemote = SocketUnreliableRemote -- Unreliable events (UnreliableRemoteEvent wrapper)
SocketServer.Function = SocketFunction                  -- Request-response (RemoteFunction wrapper)

return SocketServer
