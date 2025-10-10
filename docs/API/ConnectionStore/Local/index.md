## Getting Started

In this page, you will learn everything about the methods for local registers.

----

## Methods

----

### RegisterLocal

Registers a connection & thread in the local registry.

If a connection & thread with the same name already exists, it is disconnected first.
This ensures only one active connection per name is stored.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

Connection.RegisterLocal("ConnectionName",workspace.Baseplate.Changed:Connect(function(property)
    print(property)
end)))
```

----

### UnregisterLocal

Unregisters (removes) a connection & thread from the local registry.

If the connection is an RBXScriptConnection & thread, it is disconnected before removal.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

Connection.UnregisterLocal("ConnectionName")
```

----

### GetLocalConnections

Returns the entire local registry table.

Useful for iterating over all stored local connections.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

local connections = Connection.GetLocalConnections()
```

----

### GetLocal

Retrieves a single connection by name from the local registry.

Returns nil if the connection does not exist.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

local conn = Connection.GetLocal("ConnectionName")

print(conn) --> will print the actual RBXScriptConnection
```

----

### HasLocal

Checks whether a connection with the given name exists in the local registry.

Returns true if found, false otherwise.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

local result = Connection.HasLocal("ConnectionName")

print(result) --> will print true
```

----

### UnregisterLocals

Disconnects and removes all connections from the local registry.

Disconnects any RBXScriptConnection & thread before clearing it from the table.

Use this when you want to completely clear all local connections.

```luau linenums="1"
local ConnectionStore = require(somewhere.ConnectionStore)

Connection.UnregisterLocals()
```

----

