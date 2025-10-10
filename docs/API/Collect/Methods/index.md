## Getting Started

All information for each function will be explained here.

----

## Methods

----

### Collect.new() (Constructor)

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()
```

Creates a new CollectComponent instance

@return: New CollectComponent for managing cleanup tasks

----

### Collect:Add()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(workspace.Baseplate)
```

Adds an item to be tracked and cleaned up later

@param object: Item to track (function, connection, instance, thread, or table with cleanup method)

----

### Collect:Remove()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Remove(workspace.Baseplate)
```

Removes a specific item from tracking

- @param object: Item to remove
- @param clean (optional default true) : If true, calls cleanup on the item

----

### Collect:Find()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(workspace.Baseplate)

local myBaseplate = garbage:Find(workspace.Baseplate) --> this will return the object
```

Finds an item in the tracked list

- @param object: Item to find
- @return: The item if found, nil otherwise

----

### Collect:FindAllFunc()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(function()
	print("cleaning")
end)

print(garbage:FindAllFunc()) -> {function}
```

Returns all tracked functions

- @return: Array of function items

----

### Collect:FindAllSignal()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(workspace.Baseplate.Changed:Connect(callback))

print(garbage:FindAllSignal()) -> {RBXScriptConnection}
```

Returns all tracked connections (RBXScriptConnections)

- @return: Array of connection items

----

### Collect:FindAllConstructor()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

local class = {
	Destroy = function()
		print("cleaning...")
	end
}

garbage:Add(class) --> for constructor with the .new method use :Construct(your_constructor)

print(garbage:FindAllConstructor()) -> {ClassLike}
```

Returns all tracked objects with cleanup methods (custom classes)

- @return: Array of objects with cleanup methods

----

### Collect:FindAllInstance()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(workspace.Part)

print(garbage:FindAllInstance()) -> {Instance}
```

Returns all tracked Roblox instances

- @return: Array of Instance objects

----

### Collect:FindAllThread()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(task.spawn(function() --> you can use coroutine but it must return a thread.
	print("my thread")
end))

print(garbage:FindAllThread()) -> {Thread}
```

Returns all tracked threads

- @return: Array of thread objects

----

### Collect:RemoveAll()

```luau linenums="1"

local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(workspace.Baseplate)
garbage:Add(workspace.Baseplate.Changed:Connect(yourCallback))

garbage:Add(function()
	print("cleaning")
end)

garbage:RemoveAll()
```

Removes all tracked items

- @param clean (optional default true) : If true, calls cleanup on all items
- @param ...: Additional arguments passed to cleanup methods

----

### Collect:RemoveAllSignal()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(workspace.Baseplate.Change:Connect(callback))

garbage:RemoveAllSignal()
```

Removes all connections from tracking

- @param clean (optional default true) : If true, disconnects all connections

----

### Collect:RemoveAllFunc()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(function(...)
	print(...)
end)

garbage:RemoveAllFunc()
```

Removes all functions from tracking

- @param clean: If true, calls all function
- @param ...: Arguments passed to functions

----

### Collect:RemoveAllConstructor()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

local class = {
	Destroy = function()
		print("cleaning")
	end
}

garbage:Add(class)

garbage:RemoveAllConstructor(true,...) --> if true it will call .Destroy
```

Removes all objects with cleanup methods from tracking

- @param clean (optional default true) : If true, calls cleanup methods
- @param ...: Arguments passed to cleanup methods

----

### Collect:RemoveAllInstance()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(workspace.Part)

garbage:RemoveAllInstance()
```

Removes all Roblox instances from tracking

- @param clean (optional default true) : If true, destroys all instances

----

### Collect:RemoveAllThread()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Add(your_thread)

garbage:RemoveAllThread()
```

Removes all threads from tracking

- @param clean (optional default true) : If true, cancels all threads

----

### Collect:Construct()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local constructor = {
	new = function()
		return {
			Destroy = function()
				print("cleaning")
			end
		}
	end
}

local garbage = Collect.new()

garbage:Construct(constructor)
```

Creates a new object and adds it to tracking

- @param class: Class constructor (table with .new or function)
- @param ...: Arguments for constructor
- @return: The created object

----

### Collect:Extend()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

local extended_garbage = garbage:Extend()

garbage:Clean() --> will clean "extended_garbage" too
```

Creates a new CollectComponent as a child of this one

- @return: New CollectComponent that will be cleaned with parent

----

### Collect:Merge()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()
local other_garbage = Collect.new()

other_garbage:Add(workspace.Baseplat)

garbage:Merge(other_garbage) --> merge all current tasks in "other_garbage" in this one
```

Merges another CollectComponent into this one, taking ownership of all its tracked items

The source component is destroyed after merging

- @param self: Target CollectComponent that will receive the items
- @param CollectComponent: Source CollectComponent to merge from (will be destroyed)

----

### Collect:Clean()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

garbage:Clean() --> clean everything and the component itself
```

Cleans up all tracked items and destroys the component

This is the main cleanup method - call when done with the component

----

### Collect:WrapClean()

```luau linenums="1"
local Collect = require(somewhere.Collect)

local garbage = Collect.new()

local clean = garbage:WrapClean() 

clean() --> clean everything and the component itself
```

Returns a function that cleans this component when called

Useful for passing cleanup to other systems

- @return: Function that calls Clean()

----

## Alias

```luau linenums="1"
-- Create alias for Constructor methods
Constructor.New = Constructor.new

-- Create alias for Component methods
Component.add = Component.Add
Component.remove = Component.Remove
Component.removeAll = Component.RemoveAll
Component.removeAllFunc = Component.RemoveAllFunc
Component.removeAllSignal = Component.RemoveAllSignal
Component.removeAllThread = Component.RemoveAllThread
Component.removeAllInstance = Component.RemoveAllInstance
Component.removeAllConstructor = Component.RemoveAllConstructor
Component.find = Component.Find
Component.findAllFunc = Component.FindAllFunc
Component.findAllSignal = Component.FindAllSignal
Component.findAllThread = Component.FindAllThread
Component.findAllInstance = Component.FindAllInstance
Component.findAllConstructor = Component.FindAllConstructor
Component.construct = Component.Construct
Component.extend = Component.Extend
Component.merge = Component.Merge
Component.clean = Component.Clean
Component.destroy = Component.Clean
Component.Destroy = Component.Clean
Component.wrapClean = Component.WrapClean
```