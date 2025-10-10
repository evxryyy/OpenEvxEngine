local RunService = game:GetService("RunService")

-- RemoteEvent registry for server-side instances
local Remotes = {}

--[[
    Creates or retrieves a RemoteEvent instance by name
    @param name: The name of the RemoteEvent to create or find
    @return: RemoteEvent instance
]]
local function createRemoteEvent(name: string): RemoteEvent
	local remote = script:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent", script)
		remote.Name = name
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
    Creates a new RemoteEvent wrapper instance for server-side usage
    @param Name: The name of the RemoteEvent to wrap
    @return: New RemoteEventComponent instance
    @error: Throws if called from client
]]
function Constructor.new<T...>(Name: string): RemoteEventComponent<T...>
	-- Ensure this is only used on the server
	assert(RunService:IsServer(), "@Nexus/Server/RemoteEvent must be required from the server.")
	-- Return existing instance if already created
	if Remotes[Name] then return Remotes[Name] end
	-- Create new component instance
	local self = setmetatable({
		_connections = {},
		_remote = createRemoteEvent(Name),
		_connected = false,
	}, Component)
	-- Register instance in cache
	Remotes[Name] = self
	return self
end

--[[
    Creates a persistent connection to handle client events
    @param callback: Function to execute when event is received from client (includes Player parameter)
    @return: Disconnect function to remove the connection
]]
function Component.Connect<T...>(self: RemoteEventComponent<T...>, callback: (Player, T...) -> ()): () -> ()
	if not callback then
		error("Callback is not a function")
	end
	local index = #self._connections + 1
	table.insert(self._connections, self._remote.OnServerEvent:Connect(callback))
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
    Fires the RemoteEvent to a specific client
    @param Player: Target player to send the event to
    @param ...: Variable arguments to send to client
]]
function Component.Fire<T...>(self: RemoteEventComponent<T...>, Player: Player, ...: T...)
	self._remote:FireClient(Player, ...)	
end

--[[
    Creates a one-time connection that auto-disconnects after first trigger
    @param callback: Function to execute once when event is received from client
]]
function Component.Once<T...>(self: RemoteEventComponent<T...>, callback: (Player, T...) -> ())
	if not callback then
		error("Callback is not a function")
	end

	local index = #self._connections + 1
	table.insert(self._connections, self._remote.OnServerEvent:Once(function(Player, ...: T...)
		callback(Player, ...)
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
	self._remote:Destroy()
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
