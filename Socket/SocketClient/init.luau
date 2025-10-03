-- SocketClient Module - Client-side networking API aggregator
-- Provides unified access to all client-side Socket communication types
-- Usage: Socket.Client.Remote, Socket.Client.Function, Socket.Client.UnreliableRemote

-- Import client-side networking modules
local SocketUnreliableRemote = require('@self/SocketUnreliableRemote')  -- For unreliable, high-frequency events
local SocketFunction = require('@self/SocketFunction')                  -- For request-response communication
local SocketRemote = require('@self/SocketRemote')   -- For reliable one-way events

-- Used for type declaration
local Buffer = require('./Buffer')

-- Extended configuration type for remote events with additional metadata
type extendedRemoteConfiguration = {
	SocketName : string,           -- Name identifier for the socket connection
	Schema : Buffer.BufferSchema,  -- Data schema defining the structure of transmitted data
	ConnectionCallback : (ValueSchema : Buffer.BufferSchemaValue) -> ()  -- Callback function triggered when data is received
}

-- Extended configuration type for remote functions with additional metadata
type extendedFunctionConfiguration = {
	SocketName : string,           -- Name identifier for the socket connection
	Schema : Buffer.BufferSchema,  -- Data schema defining the structure of transmitted data
	Timeout : number?,             -- Optional timeout value for function calls
	ConnectionCallback : (InvokeValueSchema : Buffer.BufferSchemaValue) -> (Buffer.BufferSchema, Buffer.BufferSchemaValue)  -- Callback for handling function invocations
}

-- Create the SocketClient namespace
local SocketClient = {}
SocketClient.__index = SocketClient

-- Retrieves a remote event component with the specified schema
-- @param SocketName: Unique identifier for the remote event
-- @param Schema: Data structure definition for the remote event
-- @return: SocketRemote component configured with the given parameters
function SocketClient.GetRemote<T...>(SocketName : string, Schema : Buffer.BufferSchema) : SocketRemote.SocketRemoteComponent<T...>
	return SocketRemote.get(SocketName, Schema) 
end

-- Retrieves a remote function component with the specified schema
-- @param SocketName: Unique identifier for the remote function
-- @param Schema: Data structure definition for the remote function
-- @return: SocketFunction component configured with the given parameters
function SocketClient.GetFunction<T...>(SocketName : string, Schema : Buffer.BufferSchema) : SocketFunction.SocketFunctionComponent<T...>
	return SocketFunction.get(SocketName, Schema)
end

-- Retrieves an unreliable remote event component with the specified schema
-- @param SocketName: Unique identifier for the unreliable remote event
-- @param Schema: Data structure definition for the unreliable remote event
-- @return: SocketUnreliableRemote component configured with the given parameters
function SocketClient.GetUnreliableRemote<T...>(SocketName : string, Schema : Buffer.BufferSchema) : SocketUnreliableRemote.SocketUnreliableRemoteComponent<T...>
	return SocketUnreliableRemote.get(SocketName, Schema) 
end

-- Retrieves an extended remote event component with additional configuration options
-- @param Configuration: Extended configuration object containing socket name, schema, and callback
-- @return: SocketRemote component with connection callback configured
function SocketClient.GetExtendedRemote<T...>(Configuration : extendedRemoteConfiguration) : SocketRemote.SocketRemoteComponent<T...>
	local Remote = SocketRemote.get(Configuration.SocketName, Configuration.Schema)
	Remote:Connect(Configuration.ConnectionCallback)
	return Remote
end

-- Retrieves an extended remote function component with additional configuration options
-- @param Configuration: Extended configuration object containing socket name, schema, timeout, and callback
-- @return: SocketFunction component with timeout and connection callback configured
function SocketClient.GetExtendedFunction<T...>(Configuration : extendedFunctionConfiguration) : SocketFunction.SocketFunctionComponent<T...>
	local Function = SocketFunction.get(Configuration.SocketName, Configuration.Schema)
	if Configuration.Timeout then
		Function:SetTimeout(Configuration.Timeout)
	end
	Function:Insert(Configuration.ConnectionCallback)
	return Function
end

-- Retrieves an extended unreliable remote event component with additional configuration options
-- @param Configuration: Extended configuration object containing socket name, schema, and callback
-- @return: SocketUnreliableRemote component with connection callback configured
function SocketClient.GetExtendedUnreliableRemote<T...>(Configuration : extendedRemoteConfiguration) : SocketUnreliableRemote.SocketUnreliableRemoteComponent<T...>
	local UnreliableRemote = SocketRemote.get(Configuration.SocketName, Configuration.Schema)
	UnreliableRemote:Connect(Configuration.ConnectionCallback)
	return UnreliableRemote
end

-- Each provides different communication patterns:
SocketClient.Remote = SocketRemote                      -- Reliable events (RemoteEvent wrapper)
SocketClient.UnreliableRemote = SocketUnreliableRemote -- Unreliable events (UnreliableRemoteEvent wrapper)
SocketClient.Function = SocketFunction                  -- Request-response (RemoteFunction wrapper)


return SocketClient
