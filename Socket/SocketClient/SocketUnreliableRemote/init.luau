-- SocketUnreliableRemote Module (Client) - Client-side UnreliableRemoteEvent wrapper with buffer networking
-- Provides type-safe unreliable event communication with automatic buffer serialization
-- Note: UnreliableRemoteEvents may drop packets and don't guarantee delivery order

local RunService = game:GetService("RunService")

local Buffer = require('../Buffer')
local Utilities = require("../Utilities")

-- Parent folder where UnreliableRemoteEvents are stored by the server
local UnreliableRemotes = script.Parent.Parent:WaitForChild("SocketServer"):WaitForChild("SocketUnreliableRemote")

-- Cache for created SocketUnreliableRemote components
local UnreliableRemotesList = {}

-- Waits for an UnreliableRemoteEvent created by the server
-- @param SocketName: Name of the UnreliableRemoteEvent to find
-- @return: UnreliableRemoteEvent instance or nil if not found within timeout
local function SearchRemote(SocketName : string) : UnreliableRemoteEvent?
	local UnreliableRemoteEvent = UnreliableRemotes:WaitForChild(SocketName,10)
	return UnreliableRemoteEvent
end

-- Constructor for finding and wrapping existing UnreliableRemoteEvents
local SocketUnreliableRemoteConstructor = {}
SocketUnreliableRemoteConstructor.__index = SocketUnreliableRemoteConstructor

-- Component methods for interacting with UnreliableRemoteEvents
local SocketUnreliableRemote = {}
SocketUnreliableRemote.__index = SocketUnreliableRemote

-- Type definition for SocketUnreliableRemote component
export type SocketUnreliableRemoteComponent<T...> = typeof(setmetatable({} :: {
	_Remote : UnreliableRemoteEvent;      -- Reference to server-created UnreliableRemoteEvent
	_Schema : Buffer.BufferSchema;        -- Schema for data validation/serialization
	_Connections : {RBXScriptConnection}; -- Array of active connections for cleanup
},SocketUnreliableRemote))

-- Callback type for handling server events
-- @param ValueSchema: Deserialized data from server
type Callback = (values : Buffer.BufferSchemaValue) -> ()

--[[
 	Finds an existing UnreliableRemoteEvent created by the server and wraps it
 	
 	<strong>@param SocketName</strong> : Name of the UnreliableRemoteEvent to find
 	<strong>@param Schema</strong> : Buffer schema for data validation/serialization
 	
 	<strong>@return</strong> : SocketUnreliableRemote component wrapping the UnreliableRemoteEvent
]]
function SocketUnreliableRemoteConstructor.Find<T...>(SocketName : string,Schema : Buffer.BufferSchema) : SocketUnreliableRemoteComponent<T...>
	-- Validate input parameters
	assert(
		typeof(SocketName) == "string" and
			typeof(Schema) == "table"
		,"SocketName and Schema argument must be \"string\" , \"table\"")
	assert(RunService:IsClient(),("%s is only for Client-Side"):format("SocketClient.SocketUnreliableRemote"))
	-- Return cached component if already created
	if(UnreliableRemotesList[SocketName]) then
		return UnreliableRemotesList[SocketName] :: SocketUnreliableRemoteComponent<T...>
	end
	-- Create new component wrapping the server's UnreliableRemoteEvent
	local self = setmetatable({
		_Remote = SearchRemote(SocketName),
		_Schema = Schema,
		_Connections = {},
	},SocketUnreliableRemote)
	-- Error if UnreliableRemoteEvent doesn't exist (server didn't create it)
	if(self._Remote == nil) then
		error("UnreliableRemoteEvent not found: "..SocketName,2)
	end
	-- Cache the component for reuse
	UnreliableRemotesList[SocketName] = self
	return self
end

--[[
 	Fires data to the server through the UnreliableRemoteEvent

 	<strong>Note</strong> : Delivery is not guaranteed and packets may be dropped

 	<strong>@param ValueSchema</strong> : Data to send (must match Schema structure)
]]
function SocketUnreliableRemote.Fire<T...>(self : SocketUnreliableRemoteComponent<T...>,values : Buffer.BufferSchemaValue)
	-- Default to empty table if no data provided
	if(type(values) ~= "table") then values = {} end
	--If 0 zero data is intended then we fire nil instead of the serialized buffer
	if(Utilities.GetTableCount(values) == 0 and Utilities.GetTableCount(self._Schema) == 0) then
		self._Remote:FireServer()
		return
	end 
	-- Serialize data into buffer format
	local SerializedBuffer = Buffer.Serialize(self._Schema,values)
	-- Send buffer to server (unreliable - may not arrive)
	self._Remote:FireServer(SerializedBuffer.buffer)
	-- Clean up buffer to free memory
	SerializedBuffer:Destroy()
	SerializedBuffer = nil	
end

--[[
 	Connects a callback to handle events from the server
 
 	<strong>Note</strong> : Events may arrive out of order or be dropped entirely

 	<strong>@param callback</strong> : Function to process server events
]]
function SocketUnreliableRemote.Connect<T...>(self : SocketUnreliableRemoteComponent<T...>,callback : Callback)
	-- Validate callback is a function
	assert(type(callback) == "function","A function is required.")
	-- Connect to OnClientEvent and store connection for cleanup
	table.insert(self._Connections,	self._Remote.OnClientEvent:Connect(function(stack_buffer : buffer)
		-- Check if the buffer is nil and if schema is empty then fire callback with nil values
		if(not stack_buffer and Utilities.GetTableCount(self._Schema) == 0) then
			local thread = coroutine.create(callback)
			local success,err = coroutine.resume(thread)
			if(not success and err) then error(err,2) end
			return
		end
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
function SocketUnreliableRemote.ClearConnections<T...>(self : SocketUnreliableRemoteComponent<T...>)
	-- Disconnect each stored connection
	for _,connection in self._Connections do
		connection:Disconnect()
		connection = nil
	end
	-- Clear the connections array
	table.clear(self._Connections)
end

-- Destroys the component and cleans up all resources
function SocketUnreliableRemote.Destroy<T...>(self : SocketUnreliableRemoteComponent<T...>)
	-- Clear all connections first
	self:ClearConnections()
	-- Remove from cache
	for name, component in pairs(UnreliableRemotesList) do
		if component == self then
			UnreliableRemotesList[name] = nil
			break
		end
	end
	-- Clean up component
	table.clear(self :: any)
	setmetatable(self :: any,nil)
	self = nil :: any
end

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

return SocketUnreliableRemoteConstructor
