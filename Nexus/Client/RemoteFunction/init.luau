local RunService = game:GetService("RunService")

-- RemoteFunction registry and configuration
local RemoteFunctions = {}
local REMOTE_INSTANCE_TIMEOUT = 10

--[[
    Locates a RemoteFunction instance by name with timeout protection
    @param name: The name of the RemoteFunction to find
    @return: Found RemoteFunction instance
    @error: Throws if RemoteFunction is not found within timeout
]]
local function findRemoteFunction(name: string): RemoteFunction
	local remote = script.Parent.Parent.Server.RemoteFunction:WaitForChild(name, REMOTE_INSTANCE_TIMEOUT)
	if not remote then
		error(("%s doesn't exist (Child not found)"):format(name))
	end
	return remote
end

-- Constructor table for creating RemoteFunction instances
local Constructor = {}
Constructor.__index = Constructor

-- Component table containing RemoteFunction methods
local Component = {}
Component.__index = Component

-- Type definition for RemoteFunction component
export type RemoteFunctionComponent<T...> = typeof(setmetatable({} :: {
	_remoteFunction: RemoteFunction,  -- Underlying Roblox RemoteFunction
	_timeout: number,                 -- Invocation timeout in seconds
}, Component))

--[[
    Creates a new RemoteFunction wrapper instance
    @param Name: The name of the RemoteFunction to wrap
    @return: New RemoteFunctionComponent instance
    @error: Throws if called from server or if RemoteFunction not found
]]
function Constructor.new<T...>(Name: string): RemoteFunctionComponent<T...>
	-- Ensure this is only used on the client
	assert(RunService:IsClient(), "@Nexus/Client/RemoteFunction must be required from the client.")
	-- Return existing instance if already created
	if RemoteFunctions[Name] then
		return RemoteFunctions[Name]
	end
	-- Create new component instance
	local self = setmetatable({
		_remoteFunction = findRemoteFunction(Name),
		_timeout = 10,  -- Default 10 second timeout
	}, Component)
	RemoteFunctions[Name] = self
	return self
end

--[[
    Sets the callback function to handle server invocations
    @param callback: Function to execute when invoked by server
    @return: Self for method chaining
]]
function Component.Handle<T...>(self: RemoteFunctionComponent<T...>, callback: (T...) -> T...)
	if not callback then
		error("Callback is not a function")
	end
	self._remoteFunction.OnClientInvoke = callback
	return self
end

--[[
    Invokes the RemoteFunction on the server with timeout protection
    @param ...: Variable arguments to send to server
    @return: Response from server or nil if timeout
]]
function Component.Invoke<T...>(self: RemoteFunctionComponent<T...>, ...: T...): any
	local args = ... :: any
	local result = nil
	local success, finished = false, false
	local currentTime = time()
	task.spawn(function()
		success, result = pcall(function()
			return self._remoteFunction:InvokeServer(args)
		end)
		finished = true
	end)
	-- Wait for response with timeout
	local start = tick()
	while not finished and (tick() - start) < self._timeout do
		task.wait()
	end
	-- Handle timeout case
	if not finished then
		warn("RemoteFunctionComponent '" .. self._remoteFunction.Name .. "' invoke operation timed out after " .. self._timeout .. " seconds. No response received from .OnServerInvoke.")
		return nil
	end
	if not result then return nil end
	return args
end

--[[
    Removes the current handler function
    @return: Self for method chaining
]]
function Component.RemoveHandler<T...>(self: RemoteFunctionComponent<T...>)
	self._remoteFunction.OnClientInvoke = nil :: any
	return self
end

--[[
    Sets the invocation timeout duration
    @param n: Timeout duration in seconds
    @return: Self for method chaining
]]
function Component.SetTimeout<T...>(self: RemoteFunctionComponent<T...>, n: number)
	assert(type(n) == "number", "A number is required")
	self._timeout = math.abs(n)
	return self
end

--[[
    Destroys the RemoteFunction wrapper and cleans up all resources
]]
function Component.Destroy<T...>(self: RemoteFunctionComponent<T...>)
	self:RemoveHandler()
	setmetatable(self :: any, nil)
	self = nil :: any
end

-- Constructor method aliases
Constructor.find = Constructor.new
Constructor.get = Constructor.new
Constructor.Get = Constructor.new
Constructor.Find = Constructor.new
Constructor.New = Constructor.new

-- Component method aliases (camelCase convention)
Component.invoke = Component.Invoke
Component.handle = Component.Handle
Component.destroy = Component.Destroy
Component.removeHandler = Component.RemoveHandler
Component.setTimeout = Component.SetTimeout

return Constructor
