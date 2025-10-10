local RunService = game:GetService("RunService")

-- Remote event registry and configuration
local Remotes = {}
local REMOTE_INSTANCE_TIMEOUT = 10

--[[
    Locates a RemoteEvent instance by name with timeout protection
    @param name: The name of the RemoteEvent to find
    @return: Found RemoteEvent instance
    @error: Throws if RemoteEvent is not found within timeout
]]
local function findRemoteEvent(name: string): RemoteEvent
	local remote = script.Parent.Parent.Server.RemoteEvent:WaitForChild(name, REMOTE_INSTANCE_TIMEOUT)
	if not remote then
		error(("%s doesn't exist (Child not found)"):format(name))
	end
	return remote
end

-- Constructor table for creating RemoteEvent instances
local Constructor = {}
Constructor.__index = Constructor

-- Component table containing RemoteEvent methods
local Component = {}
Component.__index = Component

-- Type definition for RemoteEvent component
export type RemoteEventComponent<T...> = typeof(setmetatable({} :: {
	_connections: {RBXScriptConnection},  -- Active event connections
	_remote: RemoteEvent,                 -- Underlying Roblox RemoteEvent
	_connected: boolean,                  -- Connection state flag
}, Component))

--[[
    Creates a new RemoteEvent wrapper instance
    @param Name: The name of the RemoteEvent to wrap
    @return: New RemoteEventComponent instance
    @error: Throws if called from server or if RemoteEvent not found
]]
function Constructor.new<T...>(Name: string): RemoteEventComponent<T...>
	-- Ensure this is only used on the client
	assert(RunService:IsClient(), "@Nexus/Client/RemoteEvent must be required from the client.")
	-- Return existing instance if already created
	if Remotes[Name] then return Remotes[Name] end
	-- Create new component instance
	local self = setmetatable({
		_connections = {},
		_remote = findRemoteEvent(Name),
		_connected = false,
	}, Component)
	-- Register instance in cache
	Remotes[Name] = self
	return self
end

--[[
    Creates a persistent connection to the RemoteEvent
    @param callback: Function to execute when event is received from server
    @return: Disconnect function to remove the connection
]]
function Component.Connect<T...>(self: RemoteEventComponent<T...>, callback: (T...) -> ()): () -> ()
	if not callback then
		error("Callback is not a function")
	end

	local index = #self._connections + 1
	table.insert(self._connections, self._remote.OnClientEvent:Connect(callback))
	self._connected = true
	-- Return disconnect function
	return function()
		local connection = self._connections[index]
		if connection then
			connection:Disconnect()
		end
		table.remove(self._connections, index)
		if #self._connections <= 0 then
			self._connected = false
		end	
	end
end

--[[
    Fires the RemoteEvent to the server
    @param ...: Variable arguments to send to server
]]
function Component.Fire<T...>(self: RemoteEventComponent<T...>, ...: T...)
	self._remote:FireServer(...)	
end

--[[
    Creates a one-time connection that auto-disconnects after first trigger
    @param callback: Function to execute once when event is received
]]
function Component.Once<T...>(self: RemoteEventComponent<T...>, callback: (T...) -> ())
	if not callback then
		error("Callback is not a function")
	end
	local index = #self._connections + 1
	table.insert(self._connections, self._remote.OnClientEvent:Once(function(...: T...)
		callback(...)
		table.remove(self._connections, index)
	end))
end

--[[
    Disconnects all active connections for this RemoteEvent
]]
function Component.DisconnectAll<T...>(self: RemoteEventComponent<T...>)
	for _, connection in self._connections do
		connection:Disconnect()
		connection = nil
	end
	self._connected = false
	self._connections = {}
end

--[[
    Destroys the RemoteEvent wrapper and cleans up all resources
]]
function Component.Destroy<T...>(self: RemoteEventComponent<T...>)
	for _, connection in self._connections do
		connection:Disconnect()
	end
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
Component.connect = Component.Connect
Component.fire = Component.Fire
Component.destroy = Component.Destroy
Component.once = Component.Once
Component.disconnectAll = Component.DisconnectAll

return Constructor
