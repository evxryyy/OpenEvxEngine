## Getting Started

This page is reserved for advanced stuff or for metamethods like `__len`, `__sub` and `__add` etc...

----

## Metamethods

----

### __add

```luau linenums="1"
local Collect = require(somewhere.Collect)

local Component = Collect.new()

-- Add a part to the cleanup list (e.g is the same as calling :Add(workspace.Baseplate) )
Component += workspace.Baseplate
```

----

### __sub

```luau linenums="1"
local Collect = require(somewhere.Collect)

local Component = Collect.new()

-- Removed a part to the cleanup list (e.g is the same as calling :Remove(workspace.Baseplate) )
Component -= workspace.Baseplate
```

----

### __tostring()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local Component = Collect.new()

Component += workspace.Baseplate

print(Component) --> output : CollectComponent(1) -- 1 is the number of items in the cleanup list
```

----

### __len()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local Component = Collect.new()

Component += workspace.Baseplate

print(#Component) --> 1 Prints the number of clean-up items in the component
```

