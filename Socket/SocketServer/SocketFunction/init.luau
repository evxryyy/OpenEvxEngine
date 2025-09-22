-- SocketFunction Module (Server) - Server-side RemoteFunction wrapper with buffer networking
-- Creates and manages RemoteFunctions with type-safe buffer serialization

local RunService = game:GetService("RunService")
local Buffer = require('../Buffer')

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
	_InvokeSchema : Buffer.BufferSchema,  -- Schema for validating client data
	_timeout : number,                    -- Timeout for InvokeClient operations
},SocketFunction))

-- Callback type for handling client invokes
-- @param Player: Player who invoked the function
-- @param InvokeValueSchema: Deserialized data from client
-- @return: Response schema and value to send back to client
export type Callback = (Player : Player,InvokeValueSchema : Buffer.BufferSchemaValue) -> (Buffer.BufferSchema,Buffer.BufferSchemaValue)

-- Creates a new RemoteFunction and wraps it in a SocketFunction component
-- @param SocketName: Unique name for the RemoteFunction
-- @param InvokeSchema: Buffer schema for validating/deserializing client data
-- @return: New SocketFunction component
function SocketFunctionConstructor.Create<T...>(SocketName : string,InvokeSchema : Buffer.BufferSchema) : SocketFunctionComponent<T...>
	assert(
		typeof(SocketName) == "string" and
			typeof(InvokeSchema) == "table"
		,"SocketName and Schema argument must be \"string\" , \"table\"")
	assert(RunService:IsServer(),("%s is only for Server-Side"):format("SocketServer.SocketFunction"))
	-- Return existing component if already created
	if(FunctionsList[SocketName]) then
		return FunctionsList[SocketName] :: SocketFunctionComponent<T...>
	end
	-- Create new component with RemoteFunction
	local self = setmetatable({
		_remote = CreateFunction(SocketName);
		_InvokeSchema = InvokeSchema;
		_timeout = 10;  -- Default 10 second timeout
	},SocketFunction)
	-- Cache the component
	FunctionsList[SocketName] = self
	return self
end

-- Sets up handler for client invokes (OnServerInvoke)
-- @param callback: Function to process client requests
function SocketFunction.InsertHandle<T...>(self : SocketFunctionComponent<T...>,callback : Callback)
	-- Validate callback is a function
	assert(type(callback) == "function","A function is required.")
	self._remote.OnServerInvoke = function(player : Player,stack_buffer : buffer)
		-- Deserialize client's buffer data using schema
		local bufferComponent = Buffer.from(stack_buffer)
		local values = Buffer.Deserialize(self._InvokeSchema,bufferComponent)
		-- Call user's handler with deserialized data
		local schema,value = callback(player,values)
		-- Return nil if handler doesn't provide response
		if(not schema or not value) then return nil end
		-- Serialize and return response to client
		return Buffer.Serialize(schema,value).buffer
	end
end

function SocketFunction.RemoveHandler<T...>(self : SocketFunctionComponent<T...>)
	self._remote.OnServerInvoke = nil :: any
end

-- Invokes a specific client with buffer-serialized data
-- @param Player: Target player to invoke
-- @param InvokeValueSchema: Data to send (must match InvokeSchema)
-- @param ReturnSchema: Schema for deserializing client's response
-- @return: Deserialized response from client, or nil on timeout/error
function SocketFunction.FireClient<T...>(self : SocketFunctionComponent<T...>,Player : Player,InvokeValueSchema : Buffer.BufferSchemaValue,ReturnSchema : Buffer.BufferSchema) : Buffer.BufferSchemaValue?
	-- Serialize data into buffer
	if(not Player) then
		warn("Player parameter is nil. Invoke operation will not be sent.")
		return
	end
	local SerializedBuffer = Buffer.Serialize(self._InvokeSchema,InvokeValueSchema)
	local result = nil
	local success,finished = false,false
	local currentTime = time()
	-- Invoke client asynchronously to enable timeout
	task.spawn(function()
		success, result = pcall(function()
			return self._remote:InvokeClient(Player,SerializedBuffer.buffer) :: buffer
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
	-- Deserialize client's buffer response
	return Buffer.Deserialize(ReturnSchema,Buffer.from(result))
end

-- Sets timeout duration for InvokeClient operations
-- @param value: Timeout in seconds (converted to positive)
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

SocketFunction.fireClient = SocketFunction.FireClient
SocketFunction.InvokeClient = SocketFunction.FireClient
SocketFunction.invokeClient = SocketFunction.FireClient
SocketFunction.insert = SocketFunction.InsertHandle
SocketFunction.Insert = SocketFunction.InsertHandle
SocketFunction.setTimeout = SocketFunction.SetTimeout
SocketFunction.Clean = SocketFunction.Destroy
SocketFunction.clean = SocketFunction.Destroy
SocketFunction.destroy = SocketFunction.Destroy
SocketFunction.removeHandler = SocketFunction.RemoveHandler

return SocketFunctionConstructor
