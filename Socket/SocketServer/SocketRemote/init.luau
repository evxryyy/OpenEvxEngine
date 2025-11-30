-- SocketRemote Module (Server) - Server-side RemoteEvent wrapper with buffer networking
-- Creates and manages RemoteEvents with type-safe buffer serialization

local RunService = game:GetService("RunService")
local Buffer = require('../Buffer')
local Utilities = require("../Utilities")

-- Parent folder where RemoteEvents are created and stored
local Remotes = script
-- Cache for created SocketRemote components
local RemotesList = {}

-- Creates a new RemoteEvent or returns existing one
-- @param SocketName: Name for the RemoteEvent
-- @return: RemoteEvent instance
local function CreateRemote(SocketName : string)
	-- Return existing RemoteEvent if already created
	if(Remotes:FindFirstChild(SocketName)) then return Remotes:FindFirstChild(SocketName) end
	-- Create new RemoteEvent
	local RemoteEvent = Instance.new("RemoteEvent",Remotes)
	RemoteEvent.Name = SocketName
	return RemoteEvent
end

-- Constructor for creating server-side SocketRemotes
local SocketRemoteConstructor = {}
SocketRemoteConstructor.__index = SocketRemoteConstructor

-- Component methods for server-side RemoteEvent operations
local SocketRemote = {}
SocketRemote.__index = SocketRemote

-- Type definition for server-side SocketRemote component
export type SocketRemoteComponent<T...> = typeof(setmetatable({} :: {
	_Remote : RemoteEvent;                -- The created RemoteEvent instance
	_Schema : Buffer.BufferSchema;        -- Schema for validating client data
	_Connections : {RBXScriptConnection}; -- Array of active connections for cleanup
},SocketRemote))

-- Callback type for handling client events
-- @param Player: Player who fired the event
-- @param ValueSchema: Deserialized data from client
type Callback = (Player : Player,values : Buffer.BufferSchemaValue) -> ()

--[[
 	Creates a new RemoteEvent and wraps it in a SocketRemote component

 	<strong>@param SocketName</strong> : Unique name for the RemoteEvent
 	<strong>@param Schema</strong> : Buffer schema for data validation/serialization

 	@return: New SocketRemote component
]]
function SocketRemoteConstructor.Create<T...>(SocketName : string,Schema : Buffer.BufferSchema) : SocketRemoteComponent<T...>
	-- Validate input parameters
	assert(
		typeof(SocketName) == "string" and
			typeof(Schema) == "table"
		,"SocketName and Schema argument must be \"string\" , \"table\"")
	assert(RunService:IsServer(),("%s is only for Server-Side"):format("SocketServer.SocketRemote"))
	-- Return existing component if already created
	if(RemotesList[SocketName]) then
		return RemotesList[SocketName] :: SocketRemoteComponent<T...>
	end
	-- Create new component with RemoteEvent
	local self = setmetatable({
		_Remote = CreateRemote(SocketName);
		_Schema = Schema;
		_Connections = {}
	},SocketRemote)
	-- Cache the component
	RemotesList[SocketName] = self
	return self
end

--[[
 	Fires data to a specific client through the RemoteEvent

 	<strong>@param Player</strong> : Target player to send data to
 	<strong>@param ValueSchema</strong> : Data to send (must match Schema structure)
]]
function SocketRemote.FireClient<T...>(self : SocketRemoteComponent<T...>,Player : Player,values : Buffer.BufferSchemaValue)
	-- Validate player is still connected
	if(not Player) then
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
	-- Send buffer to specific client
	self._Remote:FireClient(Player,SerializedBuffer.buffer)
	-- Clean up buffer to free memory
	SerializedBuffer:Destroy()
	SerializedBuffer = nil	
end

--[[
 	Fires data to all clients through the RemoteEvent
 	
 	<strong>@param ValueSchema</strong> : Data to send to all clients (must match Schema structure)
]]
function SocketRemote.FireAll<T...>(self : SocketRemoteComponent<T...>,values : Buffer.BufferSchemaValue)
	-- Default to empty table if no data provided
	if(type(values) ~= "table") then values = {} end
	--If 0 zero data is intended then we fire nil instead of the serialized buffer
	if(Utilities.GetTableCount(values) == 0 and Utilities.GetTableCount(self._Schema) == 0) then
		self._Remote:FireAllClients()
		return
	end 
	-- Serialize data into buffer format
	local SerializedBuffer = Buffer.Serialize(self._Schema,values)
	-- Send buffer to all client
	self._Remote:FireAllClients(SerializedBuffer.buffer)
	-- Clean up buffer to free memory
	SerializedBuffer:Destroy()
	SerializedBuffer = nil	
end


--[[
 	Connects a callback to handle events from clients

 	<strong>@param callback</strong> : Function to process client events
]]
function SocketRemote.Connect<T...>(self : SocketRemoteComponent<T...>,callback : Callback)
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
function SocketRemote.ClearConnections<T...>(self : SocketRemoteComponent<T...>)
	-- Disconnect each stored connection
	for _,connection in self._Connections do
		connection:Disconnect()
		connection = nil
	end
	-- Clear the connections array
	table.clear(self._Connections)
end

-- Destroys the component and its RemoteEvent
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
	-- Destroy the RemoteEvent
	self._Remote:Destroy()
	self._Remote = nil :: any
	-- Clean up component
	table.clear(self :: any)
	setmetatable(self :: any,nil)
	self = nil :: any
end

-- Aliases for different naming preferences
SocketRemoteConstructor.create = SocketRemoteConstructor.Create
SocketRemoteConstructor.new = SocketRemoteConstructor.Create
SocketRemoteConstructor.New = SocketRemoteConstructor.Create

SocketRemote.fireClient = SocketRemote.FireClient
SocketRemote.fireAll = SocketRemote.FireAll
SocketRemote.connect = SocketRemote.Connect
SocketRemote.Disconnects = SocketRemote.ClearConnections
SocketRemote.disconnects = SocketRemote.ClearConnections
SocketRemote.destroy = SocketRemote.Destroy
SocketRemote.Clean = SocketRemote.Destroy
SocketRemote.clean = SocketRemote.Destroy

return SocketRemoteConstructor
