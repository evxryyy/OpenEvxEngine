## Getting Started

In this page, you will learn everything about the methods for global registers.

----

## Methods

----

### RegisterGlobal

Registers a connection & thread in the global registry.

If a connection & thread with the same name already exists, it is disconnected first.
This ensures only one active connection per name is stored.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

Connection.RegisterGlobal("ConnectionName",workspace.Baseplate.Changed:Connect(function(property)
    print(property)
end)))
```

----

### UnregisterGlobal

Unregisters (removes) a connection & thread from the global registry.

If the connection is an RBXScriptConnection & thread, it is disconnected before removal.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

Connection.UnregisterGlobal("ConnectionName")
```

----

### GetGlobalConnections

Returns the entire global registry table.

Useful for iterating over all stored global connections.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

local connections = Connection.GetGlobalConnections()
```

----

### GetGlobal

Retrieves a single connection by name from the global registry.

Returns nil if the connection does not exist.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

local conn = Connection.GetGlobal("ConnectionName")

print(conn) --> will print the actual RBXScriptConnection
```

----

### HasGlobal

Checks whether a connection with the given name exists in the global registry.

Returns true if found, false otherwise.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

local result = Connection.HasGlobal("ConnectionName")

print(result) --> will print true
```

----

### UnregisterGlobals

Disconnects and removes all connections from the global registry.

Disconnects any RBXScriptConnection & thread before clearing it from the table.

Use this when you want to completely clear all local connections.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

Connection.UnregisterGlobals()
```

----

