--[[
	Author : evxry_ll

	-- Collect: A garbage collection/cleanup utility module
	-- Manages and cleans up various types of resources (connections, instances, threads, etc.)
]]

-- Type definitions for items that can be cleaned up
export type ExecutableList = {
	Item : Executable,
	CleanupMethod : string?,  -- Optional cleanup method name for objects
}

-- Union type of all cleanable resource types
type Executable = CallbackLike 
| ConnectionLike 
| PromiseLike 
| MetatableLike 
| Instance
| thread

-- Simple callback function type
type CallbackLike = () -> ()

-- Connection type (like RBXScriptConnection)
type ConnectionLike = {
	Disconnect : () -> (),
	Connected : boolean,
}

-- Promise-like object type (for future implementation)
type PromiseLike = {
	getStatus : (self: PromiseLike) -> "Started" | "Resolved" | "Rejected" | "Cancelled",
	finally : (self: PromiseLike, callback: (...any) -> ...any) -> PromiseLike,
	cancel : (self : PromiseLike) -> (),
}

-- Type for objects with metatables (custom classes)
type MetatableLike = typeof(setmetatable({} :: {
	__index : MetatableLike,
},{} :: {any}))

-- Generic Cleanup Methods - common method names used for cleanup
local GCM = table.freeze(
	{"Destroy","Clean","DoCleaning","Cleaning","DisconnectAll","Disconnect"}
)

-- Detects which cleanup method an object has
-- @param t: Object to check
-- @return: Name of cleanup method or "Not-Found"
local function GCM_Detection(t : MetatableLike) : "Destroy" | "Clean" | "DoCleaning" | "Cleaning" | "Not-Found"
	for _,callbackName in pairs(GCM) do
		if(t[callbackName]) then
			return callbackName
		end
	end
	return "Not-Found"
end

-- Constructor table for creating new CollectComponent instances
local Constructor = {}
Constructor.__index = Constructor

-- Component prototype with all methods
local Component = {}
Component.__index = Component

-- Type definition for CollectComponent instances
export type CollectComponent<T...> = typeof(setmetatable({} :: {
	_task : {ExecutableList},  -- Array of tracked items
	_cleaning : boolean,        -- Flag to prevent operations during cleanup
},Component))

-- Creates a new CollectComponent instance
-- @return: New CollectComponent for managing cleanup tasks
function Constructor.new<T...>() : CollectComponent<T...>
	local self = setmetatable({
		_task = {},
		_cleaning = false,
	},Component)
	return self
end

-- Operator overload: Allows using + to add items
-- Example: component + connection
function Component.__add<T...>(self : CollectComponent<T...>,object : Executable)
	self:Add(object)
	return self
end

-- Operator overload: Allows using - to remove items
-- Example: component - connection
function Component.__sub<T...>(self : CollectComponent<T...>,object : Executable)
	self:Remove(object,true)
	return self
end

-- String representation of the component
-- Returns: "CollectComponent(n)" where n is the number of tracked items
function Component.__tostring<T...>(self : CollectComponent<T...>)
	return "CollectComponent("..#self._task..")"
end

-- Length operator overload
-- Returns: Number of tracked items
function Component.__len<T...>(self : CollectComponent<T...>)
	return #self._task
end

-- Adds an item to be tracked and cleaned up later
-- @param object: Item to track (function, connection, instance, thread, or table with cleanup method)
function Component.Add<T...>(self : CollectComponent<T...>,object : Executable)
	if(self._cleaning) then return end  -- Prevent adding during cleanup
	-- Validate input type
	assert(
		typeof(object) == "function" or
			typeof(object) == "RBXScriptConnection" or
			typeof(object) == "table" or
			typeof(object) == "Instance" or
			typeof(object) == "thread"
		,"\"object\" argument is not a \"Executable\"")

	local pointer : ExecutableList = {Item = nil}
	-- For tables and instances, detect cleanup method
	if(typeof(object) == "table" or typeof(object) == "Instance") then
		local gcMethod = GCM_Detection(object :: any)
		if(gcMethod == "Not-Found") then
			error("Current object does not have any cleanup method.")
		end
		pointer = {
			Item = object,
			CleanupMethod = gcMethod,
		}
	else
		pointer = {Item = object,}
	end
	table.insert(self._task,pointer)
end

-- Removes a specific item from tracking
-- @param object: Item to remove
-- @param clean: If true, calls cleanup on the item
function Component.Remove<T...>(self : CollectComponent<T...>,object : Executable,clean : boolean?)
	if(self._cleaning) then return end
	local tasks = self._task
	-- Find and remove the item
	for index,value : ExecutableList in pairs(tasks) do
		if(value.Item == object) then
			table.remove(tasks,index)
			-- Clean up if requested
			if(clean or type(clean) == "nil") then
				if(value.CleanupMethod) then
					-- Call the object's cleanup method
					(value.Item :: any)[value.CleanupMethod](value.Item)
				else
					-- Handle threads and functions
					if(typeof(value.Item) == "thread") then
						task.cancel((value.Item :: thread))
					elseif(typeof(value.Item) == "RBXScriptConnection") then
						(value.Item :: RBXScriptConnection):Disconnect()
					else
						(value.Item :: any)()
					end
				end
			end
			break
		end
	end
end

-- Finds an item in the tracked list
-- @param object: Item to find
-- @return: The item if found, nil otherwise
function Component.Find<T...>(self : CollectComponent<T...>,object : Executable) : Executable?
	local tasks = self._task
	for index,value in pairs(tasks) do
		if(value.Item == object) then
			return value.Item
		end
	end
	return nil
end

-- Removes all tracked items
-- @param clean: If true, calls cleanup on all items
-- @param ...: Additional arguments passed to cleanup methods
function Component.RemoveAll<R,T...>(self : CollectComponent<T...>,clean : boolean?,... : R)
	if(self._cleaning) then return end
	local tasks = self._task
	if #tasks == 0 then return end
	-- Clean up each item if requested
	for i = 1, #tasks do
		local value = tasks[i]
		if(clean or type(clean) == "nil") then
			if value.CleanupMethod then
				-- Call object's cleanup method with additional args
				(value.Item :: any)[value.CleanupMethod](value.Item, ...)
			else
				-- Handle threads and functions
				if typeof(value.Item) == "thread" then
					task.cancel((value.Item :: thread))
				elseif(typeof(value.Item) == "RBXScriptConnection") then
					(value.Item :: any):Disconnect()
				else
					(value.Item :: any)(...)
				end
			end
		end
	end
	table.clear(tasks)
end

-- Returns all tracked functions
-- @return: Array of function items
function Component.FindAllFunc<T...>(self : CollectComponent<T...>) : {() -> ()}
	local tasks = self._task
	local result = {}
	for index,value in pairs(tasks) do
		if(typeof(value.Item) == "function") then
			table.insert(result,value.Item)
		end
	end
	return result
end

-- Returns all tracked connections (RBXScriptConnections)
-- @return: Array of connection items
function Component.FindAllSignal<T...>(self : CollectComponent<T...>) : {ConnectionLike}
	local tasks = self._task
	local result = {}
	for index,value in pairs(tasks) do
		if(typeof(value.Item) == "RBXScriptConnection") then
			table.insert(result,value.Item :: any)
		end
	end
	return result
end

-- Returns all tracked objects with cleanup methods (custom classes)
-- @return: Array of objects with cleanup methods
function Component.FindAllConstructor<T...>(self : CollectComponent<T...>) : {MetatableLike}
	local tasks = self._task
	local result = {}
	for index,value in pairs(tasks) do
		if(typeof(value.Item) == "table" and value.CleanupMethod) then
			table.insert(result,value.Item)
		end
	end
	return result
end

-- Returns all tracked Roblox instances
-- @return: Array of Instance objects
function Component.FindAllInstance<T...>(self : CollectComponent<T...>) : {Instance}
	local tasks = self._task
	local result = {}
	for index,value in pairs(tasks) do
		if(typeof(value.Item) == "Instance") then
			table.insert(result,value.Item)
		end
	end
	return result
end

-- Returns all tracked threads
-- @return: Array of thread objects
function Component.FindAllThread<T...>(self : CollectComponent<T...>) : {thread}
	local tasks = self._task
	local result = {}
	for index,value in pairs(tasks) do
		if(typeof(value.Item) == "thread") then
			table.insert(result,value.Item)
		end
	end
	return result
end

-- Removes all connections from tracking
-- @param clean: If true, disconnects all connections
function Component.RemoveAllSignal<T...>(self : CollectComponent<T...>,clean : boolean?)
	if(self._cleaning) then return end
	local tasks = self._task
	if #tasks == 0 then return end
	-- Collect indices to remove
	local removeIndices = {}
	for i = 1, #tasks do
		local value = tasks[i]
		if typeof(value.Item) == "RBXScriptConnection" then
			if clean then value.Item:Disconnect() end
			table.insert(removeIndices, i)
		end
	end
	-- Remove in reverse order to maintain indices
	for i = #removeIndices, 1, -1 do
		table.remove(tasks, removeIndices[i])
	end
end

-- Removes all functions from tracking
-- @param clean: If true, calls all functions
-- @param ...: Arguments passed to functions
function Component.RemoveAllFunc<R,T...>(self : CollectComponent<T...>,clean : boolean?,... : R)
	if(self._cleaning) then return end
	local tasks = self._task
	if #tasks == 0 then return end
	local removeIndices = {}
	for i = 1, #tasks do
		local value = tasks[i]
		if typeof(value.Item) == "function" then
			if clean or type(clean) == "nil" then value.Item(...) end
			table.insert(removeIndices, i)
		end
	end
	for i = #removeIndices, 1, -1 do
		table.remove(tasks, removeIndices[i])
	end
end

-- Removes all objects with cleanup methods from tracking
-- @param clean: If true, calls cleanup methods
-- @param ...: Arguments passed to cleanup methods
function Component.RemoveAllConstructor<R,T...>(self : CollectComponent<T...>,clean : boolean?,... : R)
	if(self._cleaning) then return end
	local tasks = self._task
	if #tasks == 0 then return end
	local removeIndices = {}
	for i = 1, #tasks do
		local value = tasks[i]
		if typeof(value.Item) == "table" and value.CleanupMethod then
			if clean or type(clean) == "nil" then (value.Item :: any)[value.CleanupMethod](value.Item, ...) end
			table.insert(removeIndices, i)
		end
	end
	for i = #removeIndices, 1, -1 do
		table.remove(tasks, removeIndices[i])
	end
end

-- Removes all Roblox instances from tracking
-- @param clean: If true, destroys all instances
function Component.RemoveAllInstance<T...>(self : CollectComponent<T...>,clean : boolean?)
	if(self._cleaning) then return end
	local tasks = self._task
	local removeIndices = {}
	for i = 1, #tasks do
		local value = tasks[i]
		if typeof(value.Item) == "Instance" then
			if clean or type(clean) == "nil" then value.Item:Destroy() end
			table.insert(removeIndices, i)
		end
	end
	for i = #removeIndices, 1, -1 do
		table.remove(tasks, removeIndices[i])
	end
end

-- Removes all threads from tracking
-- @param clean: If true, cancels all threads
function Component.RemoveAllThread<T...>(self : CollectComponent<T...>,clean : boolean?)
	if(self._cleaning) then return end
	local tasks = self._task
	if #tasks == 0 then return end
	local removeIndices = {}
	for i = 1, #tasks do
		local value = tasks[i]
		if typeof(value.Item) == "thread" then
			if clean or type(clean) == "nil" then task.cancel((value.Item :: thread)) end
			table.insert(removeIndices, i)
		end
	end
	for i = #removeIndices, 1, -1 do
		table.remove(tasks, removeIndices[i])
	end
end

-- Creates a new object and adds it to tracking
-- @param class: Class constructor (table with .new or function)
-- @param ...: Arguments for constructor
-- @return: The created object
function Component.Construct<R,T...>(self : CollectComponent<T...>,class : MetatableLike & {new : (...any) -> ...any}, ... : any) : R?
	if(self._cleaning) then return end
	local object = nil
	local t = type(class)
	-- Call constructor based on type
	if t == "table" then
		object = (class :: any).new(...)
	elseif t == "function" then
		object = (class :: any)(...)
	end
	self:Add(object)
	return self:Find(object)
end

-- Creates a new CollectComponent as a child of this one
-- @return: New CollectComponent that will be cleaned with parent
function Component.Extend<T...>(self : CollectComponent<T...>) : CollectComponent<T...>?
	if(self._cleaning) then return end
	return self:Construct(Constructor)
end

-- Merges another CollectComponent into this one, taking ownership of all its tracked items
-- The source component is destroyed after merging
-- @param self: Target CollectComponent that will receive the items
-- @param CollectComponent: Source CollectComponent to merge from (will be destroyed)
function Component.Merge<T...,K...>(self : CollectComponent<T...>, CollectComponent : CollectComponent<K...>)
	-- Prevent merging if this component is being cleaned up
	if(self._cleaning) then return end
	-- Get all tasks from the source component
	local tasks = CollectComponent._task
	-- Transfer all tasks to this component
	if(#tasks > 0) then
		for i = 1,#tasks do
			table.insert(self._task,tasks[i])
		end
		-- Clear the source component's tasks without cleaning them
		-- (ownership has been transferred to this component)
		CollectComponent:RemoveAll()
	end
	-- Destroy the source component completely
	table.clear(CollectComponent :: any)
	setmetatable(CollectComponent :: any,nil)
end

-- Cleans up all tracked items and destroys the component
-- This is the main cleanup method - call when done with the component
function Component.Clean<T...>(self : CollectComponent<T...>)
	if(self._cleaning) then return end  -- Prevent double cleanup
	self:RemoveAll(true)  -- Clean all tracked items
	self._cleaning = true  -- Mark as cleaning
	table.clear(self :: any)  -- Clear all data
	setmetatable(self :: any,nil)  -- Remove metatable
	self = nil :: any  -- Clear reference
end

-- Returns a function that cleans this component when called
-- Useful for passing cleanup to other systems
-- @return: Function that calls Clean()
function Component.WrapClean<T...>(self : CollectComponent<T...>) : () -> ()
	return function()
		self:Clean()
	end
end

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

return Constructor
