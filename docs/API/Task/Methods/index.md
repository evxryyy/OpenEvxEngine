## Getting Started

All functions for the Task module will be here.

----

## Methods

----

### Task.IsTask()

```luau linenums="1"
local Task = require(somewhere.Task)

local garbage = Task.new()

print(garbage:IsTask())  --> true
print(Task.IsTask(garbage))  --> true
```

Validates if an object is a Task instance

- @param self - The object to check
- @return boolean - True if it's a valid Task

----

### Task.new()

```luau linenums="1"
local Task = require(somewhere.Task)

local garbage = Task.new()
```

Constructor: Creates a new Task instance

- return Task - A new Task object with unique ID and empty task list

----

### Task.AddPromise()

!!! warning "Promise V4"
    Only compatible with the [promise](https://eryn.io/roblox-luau-promise/) library, version 4.

```luau linenums="1"
local Task = require(somewhere.Task)

local garbage = Task.new()

garbage:Add(your_promise)
```

Adds a Promise to the task list and automatically removes it when resolved

- @param self - The Task instance
- @param _promise - The Promise to add

----

### Task.Add()

```luau linenums="1"
local Task = require(somewhere.Task)

local garbage = Task.new()

garbage:Add(workspace.Baseplate)
```

Adds any supported task type to be managed

- @param self - The Task instance
- @param _task - The task to add (connection, instance, function, etc.)

----

### Task.GetTaskAtIndex()

```luau linenums="1"
local Task = require(somewhere.Task)

local garbage = Task.new()

garbage:Add(workspace.Baseplate)

--later in your code

local baseplate : Instance = garbage:GetTaskAtIndex(1)
```

Retrieves a task at a specific index (1-based, clamped to valid range)

- @param self - The Task instance
- @param index - The index to retrieve
- @return any - The task at the given index

----

### Task.Execute()

```luau linenums="1"
local Task = require(somewhere.Task)

local garbage = Task.new()

garbage:Add(function()
	print("saved")
end)

--later in your code

local fn : () -> () = garbage:GetTaskAtIndex(1)

fn() --> print "saved"
```

Executes a function and returns its result
Utility method for running code within the Task context

- @param self - The Task instance
- @param callback - The function to execute
- @return any - The function's return value

----

### Task.Destroy()

```luau linenums="1"
local Task = require(somewhere.Task)

local garbage = Task.new()

garbage:Add(function()
	print("saved")
end)

--later in your code

garbage:Destroy() --> will print "saved" cause is a clean up function
```

Main cleanup method - destroys all managed tasks and the Task instance itself

- @param self - The Task instance to destroy

----

## Alias

```luau linenums="1"
-- Alias methods for flexibility and compatibility with different naming conventions
_task_.clean = _task_.Destroy
_task_.Clean = _task_.Destroy
_task_.Disconnect = _task_.Destroy
_task_.destroy = _task_.Destroy
_task_.execute = _task_.Execute
_task_.add = _task_.Add
_task_.addPromise = _task_.AddPromise
_task_.getTaskAtIndex =  _task_.GetTaskAtIndex
_task_.isTask = _task_.IsTask
```