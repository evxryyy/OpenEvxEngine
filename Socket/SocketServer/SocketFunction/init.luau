-- SocketFunction Module (Server) - Server-side RemoteFunction wrapper with buffer networking
-- Creates and manages RemoteFunctions with type-safe buffer serialization

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Buffer = require('../Buffer')
local Utilities = require("../Utilities")

-- Parent folder where RemoteFunctions are created and stored
local Functions = script
-- Cache for created SocketFunction components
local FunctionsList = {}

-- Creates a new RemoteFunction instance
-- @param SocketName: Name for the RemoteFunction
-- @return: New RemoteFunction instance
local function CreateFunction(SocketName : string)
	if(Functions:FindFirstChild(SocketName)) then return Functions:FindFirstChild(SocketName) end
	local RemoteFunction = Instance.new("RemoteFunction",Functions)
	RemoteFunction.Name = SocketName
	return RemoteFunction
end

-- Constructor for creating server-side SocketFunctions
local SocketFunctionConstructor = {}
SocketFunctionConstructor.__index = SocketFunctionConstructor

-- Component methods for server-side RemoteFunction operations
local SocketFunction = {}
SocketFunction.__index = SocketFunction

-- Type definition for server-side SocketFunction component
export type SocketFunctionComponent<T...> = typeof(setmetatable({} :: {
	_remote : RemoteFunction,             -- The created RemoteFunction instance
	_Schema : Buffer.BufferSchema,  -- Schema for validating client data
	_timeout : number,                    -- Timeout for InvokeClient operations
},SocketFunction))

-- Callback type for handling client invokes
-- @param Player: Player who invoked the function
-- @param InvokeValueSchema: Deserialized data from client
-- @return: Response schema and value to send back to client
export type Callback = (Player : Player,values : Buffer.BufferSchemaValue)
						-> (Buffer.BufferSchema,Buffer.BufferSchemaValue)

--[[
 	Creates a new RemoteFunction and wraps it in a SocketFunction component
 	
 	<strong>@param SocketName</strong> : Unique name for the RemoteFunction
 	<strong>@param InvokeSchema</strong> : Buffer schema for validating/deserializing client data
 	
 	<strong>@return</strong> : New SocketFunction component
]]
function SocketFunctionConstructor.Create<T...>(SocketName : string,Schema : Buffer.BufferSchema) : SocketFunctionComponent<T...>
	assert(
		typeof(SocketName) == "string" and
			typeof(Schema) == "table"
		,"SocketName and Schema argument must be \"string\" , \"table\"")
	assert(RunService:IsServer(),("%s is only for Server-Side"):format("SocketServer.SocketFunction"))
	-- Return existing component if already created
	if(FunctionsList[SocketName]) then
		return FunctionsList[SocketName] :: SocketFunctionComponent<T...>
	end
	-- Create new component with RemoteFunction
	local self = setmetatable({
		_remote = CreateFunction(SocketName);
		_Schema = Schema;
		_timeout = 10;  -- Default 10 second timeout
	},SocketFunction)
	-- Cache the component
	FunctionsList[SocketName] = self
	return self
end

--[[
 	Sets up handler for client invokes (OnServerInvoke)
 	
 	<strong>@param callback</strong> : Function to process client requests
]]
function SocketFunction.InsertHandle<T...>(self : SocketFunctionComponent<T...>,callback : Callback)
	-- Validate callback is a function
	assert(type(callback) == "function","A function is required.")
	self._remote.OnServerInvoke = function(player : Player,stack_buffer : buffer)
		-- Check if the buffer is nil and if schema is empty then fire callback with nil values
		if(not stack_buffer and Utilities.GetTableCount(self._Schema) == 0) then
			local schema,value = callback(player)
			return nil,nil -- both nil values
		end
		-- Check is the buffer is nil
		if(not stack_buffer) then return nil end
		-- Deserialize client's buffer data using schema
		local bufferComponent = Buffer.from(stack_buffer)
		local values = Buffer.Deserialize(self._Schema,bufferComponent)
		-- Call user's handler with deserialized data
		local schema,value = callback(player,values)
		-- Return nil if handler doesn't provide response
		if(schema == nil or value == nil) then return nil end
		-- Serialize and return response to client
		return Buffer.Serialize(schema,value).buffer
	end
end

-- Removes the current handler (sets OnServerInvoke to nil)
function SocketFunction.RemoveHandler<T...>(self : SocketFunctionComponent<T...>)
	self._remote.OnServerInvoke = nil :: any
end

--[[
 	<strong>Yieldable</strong> Invokes a specific client with buffer-serialized data
 	
 	<strong>@param Player</strong> : Target player to invoke
 	<strong>@param InvokeValueSchema</strong> : Data to send (must match InvokeSchema)
 	<strong>@param ReturnSchema</strong> : Schema for deserializing client's response
 	
 	<strong>@return</strong> : Deserialized response from client, or nil on timeout/error/empty schema
]]
function SocketFunction.Invoke<T...>(self : SocketFunctionComponent<T...>,Player : Player,values : Buffer.BufferSchemaValue,
	ReturnSchema : Buffer.BufferSchema) : Buffer.BufferSchemaValue?
	-- Serialize data into buffer
	if(not Player) then
		warn("Player parameter is nil. Invoke operation will not be sent.")
		return
	end
	local SerializedBuffer = (Utilities.GetTableCount(self._Schema) > 0) 
		and Buffer.Serialize(self._Schema,values) or nil
	local result = nil
	local success,finished = false,false
	local currentTime = time()
	-- Invoke client asynchronously to enable timeout
	task.spawn(function()
		success, result = pcall(function()
			return self._remote:InvokeClient(Player,(SerializedBuffer ~= nil) and SerializedBuffer.buffer or nil) :: buffer
		end)
		finished = true
	end)
	-- Wait for client response with timeout
	local start = tick()
	while not finished and (tick() - start) < self._timeout do
		task.wait()
	end
	-- Handle timeout case
	if(not finished) then
		warn("SocketFunction '" .. self._remote.Name .. "' invoke operation timed out after " .. self._timeout .. " seconds. No response received from .OnServerInvoke.")
		return nil
	end
	-- No result from client
	if(not result) then return nil end
	-- Handle error or empty response case
	if(Utilities.GetTableCount(ReturnSchema) == 0) then return nil end
	-- Deserialize client's buffer response
	return Buffer.Deserialize(ReturnSchema,Buffer.from(result))
end

--[[
 	<strong>Yield</strong> Invokes all clients with buffer-serialized data
 	
 	<strong>@param</strong> InvokeValueSchema : Data to send to all clients
 	<strong>@param</strong> ReturnSchema : Schema for deserializing client responses
 	
 	<strong>@return</strong>: Table of deserialized responses from clients, or nil on timeout
]]
function SocketFunction.InvokeAll<T...>(self : SocketFunctionComponent<T...>,values : Buffer.BufferSchemaValue,
	ReturnSchema : Buffer.BufferSchema) : {Buffer.BufferSchemaValue?}
	local responses = {}
	for _, player in pairs(Players:GetPlayers()) do
		local res = self:Invoke(player,values,ReturnSchema)
		if res then table.insert(responses,res) end
	end
	return responses
end

--[[
 	Sets timeout duration for InvokeClient operations
 	
 	<strong>@param value</strong> : Timeout in seconds (converted to positive)
]]
function SocketFunction.SetTimeout<T...>(self : SocketFunctionComponent<T...>,value : number)
	assert(type(value) == "number","A number is required")
	self._timeout = math.abs(value)
end

-- Destroys the component and its RemoteFunction
function SocketFunction.Destroy<T...>(self : SocketFunctionComponent<T...>)
	self:RemoveHandler()
	-- Remove from cache
	for name, component in pairs(FunctionsList) do
		if component == self then
			FunctionsList[name] = nil
			break
		end
	end
	-- Destroy the RemoteFunction
	self._remote:Destroy()
	self._remote = nil :: any
	-- Clean up component
	table.clear(self :: any)
	setmetatable(self :: any,nil)
	self = nil :: any
end

-- Aliases for different naming preferences
SocketFunctionConstructor.create = SocketFunctionConstructor.Create
SocketFunctionConstructor.new = SocketFunctionConstructor.Create
SocketFunctionConstructor.New = SocketFunctionConstructor.Create

SocketFunction.fireClient = SocketFunction.Invoke
SocketFunction.InvokeClient = SocketFunction.Invoke
SocketFunction.invokeClient = SocketFunction.Invoke
SocketFunction.invokeAll = SocketFunction.InvokeAll
SocketFunction.insert = SocketFunction.InsertHandle
SocketFunction.Insert = SocketFunction.InsertHandle
SocketFunction.setTimeout = SocketFunction.SetTimeout
SocketFunction.Clean = SocketFunction.Destroy
SocketFunction.clean = SocketFunction.Destroy
SocketFunction.destroy = SocketFunction.Destroy
SocketFunction.removeHandler = SocketFunction.RemoveHandler

return SocketFunctionConstructor
