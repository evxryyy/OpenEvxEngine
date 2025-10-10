local RunService = game:GetService("RunService")

-- RemoteFunction registry for server-side instances
local RemoteFunctions = {}

--[[
    Creates or retrieves a RemoteFunction instance by name
    @param name: The name of the RemoteFunction to create or find
    @return: RemoteFunction instance
]]
local function createRemoteFunction(name: string): RemoteFunction
	local remote = script:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteFunction", script)
		remote.Name = name
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
    Creates a new RemoteFunction wrapper instance for server-side usage
    @param Name: The name of the RemoteFunction to wrap
    @return: New RemoteFunctionComponent instance
    @error: Throws if called from client
]]
function Constructor.new<T...>(Name: string): RemoteFunctionComponent<T...>
	-- Ensure this is only used on the server
	assert(RunService:IsServer(), "@Nexus/Server/RemoteFunction must be required from the server.")
	-- Return existing instance if already created
	if RemoteFunctions[Name] then
		return RemoteFunctions[Name]
	end
	-- Create new component instance
	local self = setmetatable({
		_remoteFunction = createRemoteFunction(Name),
		_timeout = 10,  -- Default 10 second timeout
	}, Component)
	return self
end

--[[
    Sets the callback function to handle client invocations
    @param callback: Function to execute when invoked by client (includes Player parameter)
    @return: Self for method chaining
]]
function Component.Handle<T...>(self: RemoteFunctionComponent<T...>, callback: (Player, T...) -> T...)
	if not callback then
		error("Callback is not a function")
	end
	self._remoteFunction.OnServerInvoke = callback
	return self
end

--[[
    Invokes the RemoteFunction on a specific client with timeout protection
    @param Player: Target player to invoke the function on
    @param ...: Variable arguments to send to client
    @return: Response from client or nil if timeout
]]
function Component.Invoke<T...>(self: RemoteFunctionComponent<T...>, Player: Player, ...: T...): any
	local args = ... :: any
	local result = nil
	local success, finished = false, false
	local currentTime = time()
	task.spawn(function()
		success, result = pcall(function()
			return self._remoteFunction:InvokeClient(Player, args)
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
		warn("RemoteFunctionComponent '" .. self._remoteFunction.Name .. "' invoke operation timed out after " .. self._timeout .. " seconds. No response received from .OnClientInvoke.")
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
	self._remoteFunction.OnServerInvoke = nil :: any
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
	self._remoteFunction:Destroy()
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
