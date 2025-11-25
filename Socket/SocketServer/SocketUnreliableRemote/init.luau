-- SocketUnreliableRemote Module (Server) - Server-side UnreliableRemoteEvent wrapper with buffer networking
-- Creates and manages UnreliableRemoteEvents with type-safe buffer serialization
-- Note: UnreliableRemoteEvents trade reliability for performance - packets may be dropped

local RunService = game:GetService("RunService")

local Buffer = require('../Buffer')
local Utilities = require("../Utilities")

-- Parent folder where UnreliableRemoteEvents are created and stored
local UnreliableRemotes = script
-- Cache for created SocketUnreliableRemote components
local UnreliableRemotesList = {}

-- Creates a new UnreliableRemoteEvent or returns existing one
-- @param SocketName: Name for the UnreliableRemoteEvent
-- @return: UnreliableRemoteEvent instance
local function CreateRemote(SocketName : string)
	-- Return existing UnreliableRemoteEvent if already created
	if(UnreliableRemotes:FindFirstChild(SocketName)) then return UnreliableRemotes:FindFirstChild(SocketName) end
	-- Create new UnreliableRemoteEvent
	local UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent",UnreliableRemotes)
	UnreliableRemoteEvent.Name = SocketName
	return UnreliableRemoteEvent
end

-- Constructor for creating server-side SocketUnreliableRemotes
local SocketUnreliableRemoteConstructor = {}
SocketUnreliableRemoteConstructor.__index = SocketUnreliableRemoteConstructor

-- Component methods for server-side UnreliableRemoteEvent operations
local SocketUnreliableRemote = {}
SocketUnreliableRemote.__index = SocketUnreliableRemote

-- Type definition for server-side SocketUnreliableRemote component
export type SocketUnreliableRemoteComponent<T...> = typeof(setmetatable({} :: {
	_Remote : UnreliableRemoteEvent;      -- The created UnreliableRemoteEvent instance
	_Schema : Buffer.BufferSchema;        -- Schema for validating client data
	_Connections : {RBXScriptConnection}; -- Array of active connections for cleanup
},SocketUnreliableRemote))

-- Callback type for handling client events
-- @param Player: Player who fired the event
-- @param ValueSchema: Deserialized data from client
type Callback = (Player : Player,values : Buffer.BufferSchemaValue) -> ()

--[[
 	Creates a new UnreliableRemoteEvent and wraps it in a SocketUnreliableRemote component
 	
 	<strong>@param SocketName</strong> : Unique name for the UnreliableRemoteEvent
 	<strong>@param Schema</strong> : Buffer schema for data validation/serialization
 	
 	<strong>@return</strong> : New SocketUnreliableRemote component
]]
function SocketUnreliableRemoteConstructor.Create<T...>(SocketName : string,Schema : Buffer.BufferSchema) : SocketUnreliableRemoteComponent<T...>
	-- Validate input parameters
	assert(
		typeof(SocketName) == "string" and
			typeof(Schema) == "table"
		,"SocketName and Schema argument must be \"string\" , \"table\"")
	assert(RunService:IsServer(),("%s is only for Server-Side"):format("SocketServer.SocketUnreliableRemote"))
	-- Return existing component if already created
	if(UnreliableRemotesList[SocketName]) then
		return UnreliableRemotesList[SocketName] :: SocketUnreliableRemoteComponent<T...>
	end
	-- Create new component with UnreliableRemoteEvent
	local self = setmetatable({
		_Remote = CreateRemote(SocketName);
		_Schema = Schema;
		_Connections = {}
	},SocketUnreliableRemote)
	-- Cache the component
	UnreliableRemotesList[SocketName] = self
	return self
end

--[[
 	Fires data to a specific client through the UnreliableRemoteEvent
 	
 	<strong>Note</strong> : Delivery is not guaranteed - use for non-critical updates
 
 	<strong>@param Player</strong> : Target player to send data to
 	<strong>@param values</strong> : Data to send (must match Schema structure)
]]
function SocketUnreliableRemote.FireClient<T...>(self : SocketUnreliableRemoteComponent<T...>,Player : Player,values : Buffer.BufferSchemaValue)
	-- Validate player is still connected
	if(not Player or not Player.Parent) then
		warn("Player parameter is nil. Fire operation will not be sent.")
		return
	end
	-- Default to empty table if no data provided
	if(type(values) ~= "table") then values = {} end
	--If 0 zero data is intended then we fire nil instead of the serialized buffer
	if(Utilities.GetTableCount(values) == 0 and Utilities.GetTableCount(self._Schema) == 0) then
		self._Remote:FireClient(Player)
		return
	end 
	-- Serialize data into buffer format
	local SerializedBuffer = Buffer.Serialize(self._Schema,values)
	-- Send buffer to specific client (unreliable - may not arrive)
	self._Remote:FireClient(Player,SerializedBuffer.buffer)
	-- Clean up buffer to free memory
	SerializedBuffer:Destroy()
	SerializedBuffer = nil	
end

--[[
 	Fires data to all clients through the UnreliableRemoteEvent
 	
 	<strong>Note</strong> : Delivery is not guaranteed - use for non-critical updates
 	
 	<strong>@param ValueSchema</strong> : Data to send to all clients (must match Schema structure)
]]
function SocketUnreliableRemote.FireAll<T...>(self : SocketUnreliableRemoteComponent<T...>,values : Buffer.BufferSchemaValue)
	-- Default to empty table if no data provided
	if(type(values) ~= "table") then values = {} end
	--If 0 zero data is intended then we fire nil instead of the serialized buffer
	if(Utilities.GetTableCount(values) == 0 and Utilities.GetTableCount(self._Schema) == 0) then
		self._Remote:FireAllClients()
		return
	end 
	-- Serialize data into buffer format
	local SerializedBuffer = Buffer.Serialize(self._Schema,values)
	-- Send buffer to all client (unreliable - may not arrive)
	self._Remote:FireAllClients(SerializedBuffer.buffer)
	-- Clean up buffer to free memory
	SerializedBuffer:Destroy()
	SerializedBuffer = nil	
end

--[[
 	Connects a callback to handle events from clients
 	
 	<strong>Note</strong> : Some client events may be dropped due to unreliable nature
 	
 	<strong>@param callback</strong> : Function to process client events
]]
function SocketUnreliableRemote.Connect<T...>(self : SocketUnreliableRemoteComponent<T...>,callback : Callback)
	-- Validate callback is a function
	assert(type(callback) == "function","A function is required.")
	-- Connect to OnServerEvent and store connection for cleanup
	table.insert(self._Connections,	self._Remote.OnServerEvent:Connect(function(player : Player,stack_buffer : buffer)
		-- Check if the buffer is nil and if schema is empty then fire callback with nil values
		if(not stack_buffer and Utilities.GetTableCount(self._Schema) == 0) then
			local thread = coroutine.create(callback)
			local success,err = coroutine.resume(thread,player)
			if(not success and err) then error(err,2) end
			return
		end
		-- Deserialize client's buffer data
		local bufferComponent = Buffer.from(stack_buffer)
		local values = Buffer.Deserialize(self._Schema,bufferComponent)
		-- Execute callback in protected coroutine
		local thread = coroutine.create(callback)
		local success,err = coroutine.resume(thread,player,values)
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

-- Destroys the component and its UnreliableRemoteEvent
function SocketUnreliableRemote.Destroy<T...>(self : SocketUnreliableRemoteComponent<T...>)
	-- Clear all connections first
	self:ClearConnections()
	-- Remove from cache
	for name, component in pairs(UnreliableRemotesList) do
		if component == self then
			UnreliableRemotesList[name] = nil  -- Fixed: was SocketUnreliableRemote[name]
			break
		end
	end
	-- Destroy the UnreliableRemoteEvent
	self._Remote:Destroy()
	self._Remote = nil :: any
	-- Clean up component
	table.clear(self :: any)
	setmetatable(self :: any,nil)
	self = nil :: any
end

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

return SocketUnreliableRemoteConstructor
