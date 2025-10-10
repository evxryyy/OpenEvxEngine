## Getting Started

To serialize a BufferComponent, you simply need to assign a Schema and the table containing the values.

!!! note
    Each index must exactly match the name in the Schema.
    e.g: Schema = {Hello = "String8"}, Values = {Hello = "World"}
    Otherwise the value will be skipped and may cause errors.

!!! warning
    You can serialize/deserialize an Instance, but it will use a table not a buffer.

    Find more here : [Advanced](../Advanced/index.md#getting-started) , [Writing](../Writing/index.md#writing-instance) or [Reading](../Reading/index.md#reading-instance)  


----

## Methods

----

### Serialize

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

--[[
	Here we define a schema for buffer serialization/deserialization
	The schema specifies the structure and data types of the buffer
]]
local Schema : Buffer.BufferSchema = {
	Hello = "String16"
}

--FOR NON DEFINED STRING LENGTH
--[[
	local Schema : Buffer.BufferSchema = {
		Hello = {
			Type = "String",
			Length = 13
		}
	}
	this only work for strings.
	For other types you have to use the normal way of defining the schema.
]]

local Value = {
	Hello = "Hello World !" --> 13 chars so 3 padding character will be added
}

local serialized = Buffer.Serialize(Schema,Value)
print(serialized) --> will print BufferComponent(Size:16)

--[[
	Note:
	You will be able to use any method inside the BufferComponent but this is at your own risk i recommend to let
	the serialized buffer like that and only use it when you really know what you are doing
]]
```

Serializes the given Values according to the Schema into a BufferComponentClass

----

### Deserialize

```luau
local Buffer = require(somewhere.Buffer)

local Schema : Buffer.BufferSchema = {
	Hello = "String16"
}

local Value = {
	Hello = "Hello World !" 
}

local serialized = Buffer.Serialize(Schema,Value)

--Deserializing the buffer

--the schema need to be same as the one used to serialize

local deserialized = Buffer.Deserialize(Schema,serialized)
print(deserialized) -- will print { Hello = "Hello World !" }
```

Deserializes a BufferComponentClass into a table of values according to Schema