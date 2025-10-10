local RunService = game:GetService("RunService")

-- UnreliableRemoteEvent registry and configuration
local UnreliableRemotes = {}
local REMOTE_INSTANCE_TIMEOUT = 10

--[[
    Locates an UnreliableRemoteEvent instance by name with timeout protection
    @param name: The name of the UnreliableRemoteEvent to find
    @return: Found UnreliableRemoteEvent instance
    @error: Throws if UnreliableRemoteEvent is not found within timeout
]]
local function findUnreliableRemoteEvent(name: string): UnreliableRemoteEvent
	local remote = script.Parent.Parent.Server.UnreliableRemoteEvent:WaitForChild(name, REMOTE_INSTANCE_TIMEOUT)
	if not remote then
		error(("%s doesn't exist (Child not found)"):format(name))
	end
	return remote
end

-- Constructor table for creating UnreliableRemoteEvent instances
local Constructor = {}
Constructor.__index = Constructor

-- Component table containing UnreliableRemoteEvent methods
local Component = {}
Component.__index = Component

-- Type definition for UnreliableRemoteEvent component
export type UnreliableRemoteEventComponent<T...> = typeof(setmetatable({} :: {
	_connections: {RBXScriptConnection},        -- Active event connections
	_unreliableRemote: UnreliableRemoteEvent,   -- Underlying Roblox UnreliableRemoteEvent
	_connected: boolean,                        -- Connection state flag
}, Component))

--[[
    Creates a new UnreliableRemoteEvent wrapper instance
    @param Name: The name of the UnreliableRemoteEvent to wrap
    @return: New UnreliableRemoteEventComponent instance
    @error: Throws if called from server or if UnreliableRemoteEvent not found
]]
function Constructor.new<T...>(Name: string): UnreliableRemoteEventComponent<T...>
	-- Ensure this is only used on the client
	assert(RunService:IsClient(), "@Nexus/Client/UnreliableRemote must be required from the client.")
	-- Return existing instance if already created
	if UnreliableRemotes[Name] then return UnreliableRemotes[Name] end
	-- Create new component instance
	local self = setmetatable({
		_connections = {},
		_unreliableRemote = findUnreliableRemoteEvent(Name),
		_connected = false,
	}, Component)
	-- Register instance in cache
	UnreliableRemotes[Name] = self
	return self
end

--[[
    Creates a persistent connection to the UnreliableRemoteEvent
    @param callback: Function to execute when event is received from server
    @return: Disconnect function to remove the connection
]]
function Component.Connect<T...>(self: UnreliableRemoteEventComponent<T...>, callback: (T...) -> ()): () -> ()
	if not callback then
		error("Callback is not a function")
	end
	local index = #self._connections + 1
	table.insert(self._connections, self._unreliableRemote.OnClientEvent:Connect(callback))
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
    Fires the UnreliableRemoteEvent to the server (UDP-style, no delivery guarantee)
    @param ...: Variable arguments to send to server
]]
function Component.Fire<T...>(self: UnreliableRemoteEventComponent<T...>, ...: T...)
	self._unreliableRemote:FireServer(...)	
end

--[[
    Creates a one-time connection that auto-disconnects after first trigger
    @param callback: Function to execute once when event is received
]]
function Component.Once<T...>(self: UnreliableRemoteEventComponent<T...>, callback: (T...) -> ())
	if not callback then
		error("Callback is not a function")
	end
	local index = #self._connections + 1
	table.insert(self._connections, self._unreliableRemote.OnClientEvent:Once(function(...: T...)
		callback(...)
		table.remove(self._connections, index)
	end))
end

--[[
    Disconnects all active connections for this UnreliableRemoteEvent
]]
function Component.DisconnectAll<T...>(self: UnreliableRemoteEventComponent<T...>)
	for _, connection in self._connections do
		connection:Disconnect()
		connection = nil
	end
	self._connected = false
	self._connections = {}
end

--[[
    Destroys the UnreliableRemoteEvent wrapper and cleans up all resources
]]
function Component.Destroy<T...>(self: UnreliableRemoteEventComponent<T...>)
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
