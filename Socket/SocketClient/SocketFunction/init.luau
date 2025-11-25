-- SocketFunction Module - Client-side wrapper for RemoteFunction with buffer networking
-- Provides type-safe communication with server using buffer serialization

local RunService = game:GetService("RunService")

local Buffer = require('../Buffer')
local Utilities = require("../Utilities")

-- Parent folder where RemoteFunctions are stored by the server
local Functions = script.Parent.Parent:WaitForChild("SocketServer"):WaitForChild("SocketFunction")

-- Cache for created SocketFunction components
local FunctionsList = {}

-- Waits for a RemoteFunction created by the server
-- @param SocketName: Name of the RemoteFunction to find
-- @return: RemoteFunction instance created by server
local function SearchRemote(SocketName : string) : RemoteFunction?
	local RemoteFunction = Functions:WaitForChild(SocketName,10)
	return RemoteFunction
end

-- Constructor for finding and wrapping existing RemoteFunctions
local SocketFunctionConstructor = {}
SocketFunctionConstructor.__index = SocketFunctionConstructor

-- Component methods for interacting with RemoteFunctions
local SocketFunction = {}
SocketFunction.__index = SocketFunction

-- Type definition for SocketFunction component
export type SocketFunctionComponent<T...> = typeof(setmetatable({} :: {
	_remote : RemoteFunction;             -- Reference to server-created RemoteFunction
	_InvokeSchema : Buffer.BufferSchema;  -- Schema for data sent to server
	_timeout : number;                    -- Timeout for server invokes (default: 10s)
},SocketFunction))

-- Callback type for handling server-to-client invokes
-- @param Player: Player parameter (passed by RemoteFunction)
-- @param InvokeValueSchema: Deserialized data from server
-- @return: Response schema and value to send back to server
export type Callback = (values : Buffer.BufferSchemaValue) -> (Buffer.BufferSchema,Buffer.BufferSchemaValue)

--[[
 	Finds an existing RemoteFunction created by the server and wraps it

 	<strong>@param SocketName</strong>: Name of the RemoteFunction to find
 	<strong>@param InvokeSchema</strong>: Buffer schema for data validation/serialization

 	<strong>@return</strong>: SocketFunction component wrapping the RemoteFunction
]]
function SocketFunctionConstructor.Find<T...>(SocketName : string,Schema : Buffer.BufferSchema) : SocketFunctionComponent<T...>
	assert(
		typeof(SocketName) == "string" and
			typeof(Schema) == "table"
		,"SocketName and Schema argument must be \"string\" , \"table\"")
	assert(RunService:IsClient(),("%s is only for Client-Side"):format("SocketClient.SocketFunction"))
	-- Return cached component if already created
	if(FunctionsList[SocketName]) then
		return FunctionsList[SocketName] :: SocketFunctionComponent<T...>
	end
	-- Create new component wrapping the server's RemoteFunction
	local self = setmetatable({
		_remote = SearchRemote(SocketName);
		_InvokeSchema = Schema;
		_timeout = 10;  -- Default timeout
	},SocketFunction)
	-- Error if RemoteFunction doesn't exist (server didn't create it)
	if(self._remote == nil) then
		error("RemoteFunction not found: "..SocketName,2)
	end
	-- Cache the component
	FunctionsList[SocketName] = self
	return self
end

--[[
 	<strong>Yield</strong> Invokes the server's OnServerInvoke handler with buffer-serialized data
 	
 	<strong>@param InvokeValueSchema</strong> : Data to send (must match InvokeSchema structure)
 	<strong>@param ReturnSchema</strong> : Schema for deserializing server's response
 	
 	<strong>@return</strong> : Deserialized response from server, or nil on timeout/error
]]
function SocketFunction.Fire<T...>(self : SocketFunctionComponent<T...>,values : Buffer.BufferSchemaValue,ReturnSchema : Buffer.BufferSchema) : Buffer.BufferSchemaValue?
	if(type(values) ~= "table") then values = {} end
	if(type(ReturnSchema) ~= "table") then ReturnSchema = {} end
	-- Serialize data into buffer format
	local SerializedBuffer = (Utilities.GetTableCount(self._InvokeSchema) > 0) 
		and Buffer.Serialize(self._InvokeSchema,values) or nil
	local result = nil
	local success,finished = false,false
	local currentTime = time()
	-- Invoke server asynchronously to enable timeout
	task.spawn(function()
		success, result = pcall(function()
			return self._remote:InvokeServer((SerializedBuffer ~= nil) and SerializedBuffer.buffer or nil) :: buffer
		end)
		finished = true
	end)
	-- Wait for response with timeout
	local start = tick()
	while not finished and (tick() - start) < self._timeout do
		task.wait()
	end
	-- Handle timeout case
	if(not finished) then
		warn("SocketFunction '" .. self._remote.Name .. "' invoke operation timed out after " .. self._timeout .. " seconds. No response received from .OnServerInvoke.")
		return nil
	end
	-- No result received
	if(not result) then return nil end
	--Check if return schema is intended to be empty
	if(Utilities.GetTableCount(ReturnSchema) == 0) then return nil end
	-- Deserialize server's buffer response
	return Buffer.Deserialize(ReturnSchema,Buffer.from(result))
end

--[[
 	Sets up handler for when server invokes this client
 	Only used if server calls InvokeClient on this RemoteFunction
 	
 	<strong>@param callback</strong>: Function to handle server invokes
]]
function SocketFunction.InsertHandle<T...>(self : SocketFunctionComponent<T...>,callback : Callback)
	assert(type(callback) == "function","A function is required.")
	self._remote.OnClientInvoke = function(stack_buffer : buffer)
		-- Check if the buffer is nil and if schema is empty then fire callback with nil values
		if(not stack_buffer and Utilities.GetTableCount(self._InvokeSchema) == 0) then
			local schema,value = callback()
			return nil,nil -- both nil values
		end
		-- Deserialize server's buffer data
		local bufferComponent = Buffer.from(stack_buffer)
		local values = Buffer.Deserialize(self._InvokeSchema,bufferComponent)
		-- Call user's handler
		local schema,value = callback(values)
		-- No response if handler returns nil
		if(schema == nil or value == nil) then return nil end
		-- Serialize response back to server
		return Buffer.Serialize(schema,value).buffer
	end
end

--[[
 	Removes handler for when server invokes this client
]]
function SocketFunction.RemoveHandler<T...>(self : SocketFunctionComponent<T...>)
	self._remote.OnClientInvoke = nil :: any
end

--[[
 	Configures timeout for InvokeServer operations
 	
 	<strong>@param value</strong>: Timeout duration in seconds (converted to positive)
]]
function SocketFunction.SetTimeout<T...>(self : SocketFunctionComponent<T...>,value : number)
	assert(type(value) == "number","A number is required")
	self._timeout = math.abs(value)
end

-- Cleans up the component (does not destroy the RemoteFunction)
function SocketFunction.Destroy<T...>(self : SocketFunctionComponent<T...>)
	self:RemoveHandler()
	-- Remove from cache
	for name, component in pairs(FunctionsList) do
		if component == self then
			FunctionsList[name] = nil
			break
		end
	end
	-- Clean up component
	table.clear(self :: any)
	setmetatable(self :: any,nil)
	self = nil :: any
end

-- Aliases for different naming preferences
SocketFunctionConstructor.find = SocketFunctionConstructor.Find
SocketFunctionConstructor.get = SocketFunctionConstructor.Find
SocketFunctionConstructor.Get = SocketFunctionConstructor.Find

SocketFunction.fire = SocketFunction.Fire
SocketFunction.Invoke = SocketFunction.Fire
SocketFunction.invoke = SocketFunction.Fire
SocketFunction.insert = SocketFunction.InsertHandle
SocketFunction.Insert = SocketFunction.InsertHandle
SocketFunction.setTimeout = SocketFunction.SetTimeout
SocketFunction.Clean = SocketFunction.Destroy
SocketFunction.clean = SocketFunction.Destroy
SocketFunction.destroy = SocketFunction.Destroy
SocketFunction.removeHandler = SocketFunction.RemoveHandler

return SocketFunctionConstructor
