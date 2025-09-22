-- SocketRemote Module (Client) - Client-side RemoteEvent wrapper with buffer networking
-- Provides type-safe event communication with automatic buffer serialization

local RunService = game:GetService("RunService")
local Buffer = require('../Buffer')

-- Parent folder where RemoteEvents are stored by the server
local Remotes = script.Parent.Parent:WaitForChild("SocketServer"):WaitForChild("SocketRemote")

-- Cache for created SocketRemote components
local RemotesList = {}

-- Waits for a RemoteEvent created by the server
-- @param SocketName: Name of the RemoteEvent to find
-- @return: RemoteEvent instance or nil if not found within timeout
local function SearchRemote(SocketName : string) : RemoteEvent?
	local RemoteEvent = Remotes:WaitForChild(SocketName,10)
	return RemoteEvent
end

-- Constructor for finding and wrapping existing RemoteEvents
local SocketRemoteConstructor = {}
SocketRemoteConstructor.__index = SocketRemoteConstructor

-- Component methods for interacting with RemoteEvents
local SocketRemote = {}
SocketRemote.__index = SocketRemote

-- Type definition for SocketRemote component
export type SocketRemoteComponent<T...> = typeof(setmetatable({} :: {
	_Remote : RemoteEvent;                -- Reference to server-created RemoteEvent
	_Schema : Buffer.BufferSchema;        -- Schema for data validation/serialization
	_Connections : {RBXScriptConnection}; -- Array of active connections for cleanup
},SocketRemote))

-- Callback type for handling server events
-- @param ValueSchema: Deserialized data from server
type Callback = (ValueSchema : Buffer.BufferSchemaValue) -> ()

-- Finds an existing RemoteEvent created by the server and wraps it
-- @param SocketName: Name of the RemoteEvent to find
-- @param Schema: Buffer schema for data validation/serialization
-- @return: SocketRemote component wrapping the RemoteEvent
function SocketRemoteConstructor.Find<T...>(SocketName : string,Schema : Buffer.BufferSchema) : SocketRemoteComponent<T...>
	-- Validate input parameters
	assert(
		typeof(SocketName) == "string" and
			typeof(Schema) == "table"
		,"SocketName and Schema argument must be \"string\" , \"table\"")
	assert(RunService:IsClient(),("%s is only for Client-Side"):format("SocketClient.SocketRemote"))
	-- Return cached component if already created
	if(RemotesList[SocketName]) then
		return RemotesList[SocketName] :: SocketRemoteComponent<T...>
	end
	-- Create new component wrapping the server's RemoteEvent
	local self = setmetatable({
		_Remote = SearchRemote(SocketName),
		_Schema = Schema,
		_Connections = {},
	},SocketRemote)
	-- Error if RemoteEvent doesn't exist (server didn't create it)
	if(self._Remote == nil) then
		error("RemoteEvent not found: "..SocketName,2)
	end
	-- Cache the component for reuse
	RemotesList[SocketName] = self
	return self
end

-- Fires data to the server through the RemoteEvent
-- @param ValueSchema: Data to send (must match Schema structure)
function SocketRemote.Fire<T...>(self : SocketRemoteComponent<T...>,ValueSchema : Buffer.BufferSchemaValue)
	-- Default to empty table if no data provided
	if(type(ValueSchema) ~= "table") then ValueSchema = {} end
	-- Serialize data into buffer format
	local SerializedBuffer = Buffer.Serialize(self._Schema,ValueSchema)
	-- Send buffer to server
	self._Remote:FireServer(SerializedBuffer.buffer)
	-- Clean up buffer to free memory
	SerializedBuffer:Destroy()
	SerializedBuffer = nil	
end

-- Connects a callback to handle events from the server
-- @param callback: Function to process server events
function SocketRemote.Connect<T...>(self : SocketRemoteComponent<T...>,callback : Callback)
	-- Validate callback is a function
	assert(type(callback) == "function","A function is required.")
	-- Connect to OnClientEvent and store connection for cleanup
	table.insert(self._Connections,	self._Remote.OnClientEvent:Connect(function(stack_buffer : buffer)
		-- Deserialize server's buffer data
		local bufferComponent = Buffer.from(stack_buffer)
		local values = Buffer.Deserialize(self._Schema,bufferComponent)
		-- Execute callback in protected coroutine
		local thread = coroutine.create(callback)
		local success,err = coroutine.resume(thread,values)
		-- Clean up buffer
		bufferComponent:Destroy()
		bufferComponent = nil
		-- Propagate errors if callback failed
		if(not success and err) then error(err,2) end
	end))
end

-- Disconnects all active connections
function SocketRemote.ClearConnections<T...>(self : SocketRemoteComponent<T...>)
	-- Disconnect each stored connection
	for _,connection in self._Connections do
		connection:Disconnect()
		connection = nil
	end
	-- Clear the connections array
	table.clear(self._Connections)
end

-- Destroys the component and cleans up all resources
function SocketRemote.Destroy<T...>(self : SocketRemoteComponent<T...>)
	-- Clear all connections first
	self:ClearConnections()
	-- Remove from cache
	for name, component in pairs(RemotesList) do
		if component == self then
			RemotesList[name] = nil
			break
		end
	end
	-- Clean up component
	table.clear(self :: any)
	setmetatable(self :: any,nil)
	self = nil :: any
end

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

return SocketRemoteConstructor
