--!strict

--[[
    ConnectionStore.luau
    
    author : evxry_ll
    
    -------------------
    A utility module to manage RBXScriptConnections (or cleanup callbacks)
    in both "local" and "global" registries.

    Purpose:
    - Prevent memory leaks by disconnecting old connections before overwriting.
    - Provide an API to register, unregister, query, and retrieve connections.
    - Differentiate between "Local" (per-instance/module scope) and "Global" (shared scope).
]]

type Executable<T...> = RBXScriptConnection | (T...) -> T... | thread

-- Global registry (shared across all ConnectionStore users)
local ConnectionStoreRegistery = {} :: {[string] : Executable<...any>}

-- ConnectionStore object definition
local ConnectionStore = {}
ConnectionStore.__index = ConnectionStore

-- Local registry (isolated to this ConnectionStore object)
ConnectionStore.LocalRegistery = {} :: {[string] : Executable<...any>}

--[[
    Registers a connection & thread in the local registry.
    - If a connection & thread with the same name already exists, it is disconnected first.
    - This ensures only one active connection per name is stored.
]]
function ConnectionStore.RegisterLocal<T...>(name : string, connection : Executable<T...>)
	if (ConnectionStore.LocalRegistery[name]) then
		if (typeof(ConnectionStore.LocalRegistery[name]) == "RBXScriptConnection") then
			local connection = ConnectionStore.LocalRegistery[name] :: RBXScriptConnection
			connection:Disconnect()
			connection = nil :: any
		elseif(typeof(ConnectionStore.LocalRegistery[name]) == "thread") then
			if(coroutine.status(ConnectionStore.LocalRegistery[name] :: thread) == "dead") then
				local success,err = pcall(coroutine.close,ConnectionStore.LocalRegistery[name] :: thread)
				if(err) then warn(err) end
			end
		end
	end
	if(typeof(connection) == "thread") then
		if(coroutine.status(connection :: thread) == "dead") then
			warn(name,"Terminated threads must not be inserted into the table.")
			return
		end
	end
	ConnectionStore.LocalRegistery[name] = connection
end

--[[
    Registers a connection & thread in the global registry.
    - Works the same as RegisterLocal, but in the shared/global scope.
]]
function ConnectionStore.RegisterGlobal<T...>(name : string, connection : Executable<T...>)
	if (ConnectionStoreRegistery[name]) then
		if (typeof(ConnectionStoreRegistery[name]) == "RBXScriptConnection") then
			local connection = ConnectionStoreRegistery[name] :: RBXScriptConnection
			connection:Disconnect()
			connection = nil :: any
		elseif(typeof(ConnectionStoreRegistery[name]) == "thread") then
			if(coroutine.status(ConnectionStoreRegistery[name] :: thread) == "dead") then
				local success,err = pcall(coroutine.close,ConnectionStoreRegistery[name] :: thread)
				if(err) then warn(err) end
			end
		end
	end
	if(typeof(connection) == "thread") then
		if(coroutine.status(connection :: thread) == "dead") then
			warn(name,"Terminated threads must not be inserted into the table.")
			return	
		end
	end
	ConnectionStoreRegistery[name] = connection
end

--[[
    Unregisters (removes) a connection & thread from the local registry.
    - If the connection is an RBXScriptConnection & thread, it is disconnected before removal.
]]
function ConnectionStore.UnregisterLocal(name : string)
	if (ConnectionStore.LocalRegistery[name]) then
		if (typeof(ConnectionStore.LocalRegistery[name]) == "RBXScriptConnection") then
			local connection = ConnectionStore.LocalRegistery[name] :: RBXScriptConnection
			connection:Disconnect()
			connection = nil :: any
		elseif(typeof(ConnectionStore.LocalRegistery[name]) == "thread") then
			if(coroutine.status(ConnectionStore.LocalRegistery[name] :: thread) == "dead") then
				local success,err = pcall(coroutine.close,ConnectionStore.LocalRegistery[name] :: thread)
				if(err) then warn(err) end
			end
		end
		ConnectionStore.LocalRegistery[name] = nil
	end
end

--[[
    Unregisters (removes) a connection & thread from the global registry.
    - Same logic as UnregisterLocal, but applied to the global scope.
]]
function ConnectionStore.UnregisterGlobal(name : string)
	if (ConnectionStoreRegistery[name]) then
		if (typeof(ConnectionStoreRegistery[name]) == "RBXScriptConnection") then
			local connection = ConnectionStoreRegistery[name] :: RBXScriptConnection
			connection:Disconnect()
			connection = nil :: any
		elseif(typeof(ConnectionStoreRegistery[name]) == "thread") then
			if(coroutine.status(ConnectionStoreRegistery[name] :: thread) == "dead") then
				local success,err = pcall(coroutine.close,ConnectionStoreRegistery[name] :: thread)
				if(err) then warn(err) end
			end
		end
		ConnectionStoreRegistery[name] = nil
	end
end

--[[
    Returns the entire local registry table.
    - Useful for iterating over all stored local connections.
]]
function ConnectionStore.GetLocalConnections()
	return ConnectionStore.LocalRegistery
end

--[[
    Returns the entire global registry table.
    - Useful for iterating over all stored global connections.
]]
function ConnectionStore.GetGlobalConnections()
	return ConnectionStoreRegistery
end

--[[
    Retrieves a single connection by name from the local registry.
    - Returns nil if the connection does not exist.
]]
function ConnectionStore.GetLocal<T...>(name : string) : Executable<T...>?
	return ConnectionStore.LocalRegistery[name]
end

--[[
    Retrieves a single connection by name from the global registry.
    - Returns nil if the connection does not exist.
]]
function ConnectionStore.GetGlobal<T...>(name : string) : Executable<T...>?
	return ConnectionStoreRegistery[name]
end

--[[
    Checks whether a connection with the given name exists in the local registry.
    - Returns true if found, false otherwise.
]]
function ConnectionStore.HasLocal(name : string) : boolean
	return ConnectionStore.LocalRegistery[name] ~= nil
end

--[[
    Checks whether a connection with the given name exists in the global registry.
    - Returns true if found, false otherwise.
]]
function ConnectionStore.HasGlobal(name : string) : boolean
	return ConnectionStoreRegistery[name] ~= nil
end

--[[
    Disconnects and removes all connections from the local registry.
    - Iterates through all entries.
    - Disconnects any RBXScriptConnection & thread before clearing it from the table.
    - Use this when you want to completely clear all local connections.
]]
function ConnectionStore.UnregisterLocals()
	for name, connection in ConnectionStore.LocalRegistery do
		if (typeof(ConnectionStore.LocalRegistery[name]) == "RBXScriptConnection") then
			local connection = ConnectionStore.LocalRegistery[name] :: RBXScriptConnection
			connection:Disconnect()
			connection = nil :: any
		elseif(typeof(ConnectionStore.LocalRegistery[name]) == "thread") then
			if(coroutine.status(ConnectionStore.LocalRegistery[name] :: thread) == "dead") then
				local success,err = pcall(coroutine.close,ConnectionStore.LocalRegistery[name] :: thread)
				if(err) then warn(err) end
			end
		end
		ConnectionStore.LocalRegistery[name] = nil
	end
end

--[[
    Disconnects and removes all connections from the global registry.
    - Iterates through all entries in the global registry.
    - Disconnects any RBXScriptConnection & thread before clearing it.
    - Use this when you want to completely clear all global connections.
]]
function ConnectionStore.UnregisterGlobals()
	for name, connection in ConnectionStoreRegistery do
		if (typeof(ConnectionStoreRegistery[name]) == "RBXScriptConnection") then
			local connection = ConnectionStoreRegistery[name] :: RBXScriptConnection
			connection:Disconnect()
			connection = nil :: any
		elseif(typeof(ConnectionStoreRegistery[name]) == "thread") then
			if(coroutine.status(ConnectionStoreRegistery[name] :: thread) == "dead") then
				local success,err = pcall(coroutine.close,ConnectionStoreRegistery[name] :: thread)
				if(err) then warn(err) end
			end
		end
		ConnectionStoreRegistery[name] = nil
	end
end

-- Export the ConnectionStore API
return ConnectionStore
