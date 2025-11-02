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

----

### SerializeJSON

Same as Serialize, but accepts a JSON string.

```luau linenums="1"
local json = Buffer.SerializeJSON(Schema,HttpService:JSONEncode(Values))

print(json)
print(Buffer.DeserializeJSON(Schema,json)) --> json string
```

----

### DeserializeJSON

Same as Deserialize, but returns a JSON string instead of a table.

----

### SerializeAll

Same as Serialize but accepts a table of values and a table of schemas.

Each schema will be serialized with its corresponding value.

!!! Note
    This return a numeric table with BufferComponentClass as values in order.

```luau linenums="1"
local SchemaA : Buffer.BufferSchema = {
	Name = {
		Type = "String",
		Length = 14,
	}
}

local SchemaB : Buffer.BufferSchema = {
	Name = {
		Type = "String",
		Length = 20,
	}
}

local A = {
	Name = "Hello World !!",
}

local B = {
	Name = "Goodbye World !!",
}

--The order is important !
local buff = Buffer.SerializeAll({SchemaA,SchemaB},{A,B})
```

----

### DeserializeAll

Same as Serialize but accepts a table of values and a table of schemas.

Each schema will be serialized with its corresponding value.

!!! Note
	This return a numeric table with BufferComponentClass as values in order.

```luau linenums="1"
local SchemaA : Buffer.BufferSchema = {
	Name = {
		Type = "String",
		Length = 14,
	}
}

local SchemaB : Buffer.BufferSchema = {
	Name = {
		Type = "String",
		Length = 20,
	}
}

local A = {
	Name = "Hello World !!",
}

local B = {
	Name = "Goodbye World !!",
}

--The order is important for both methods !!!!!
local buff = Buffer.SerializeAll({SchemaA,SchemaB},{A,B})

print(Buffer.DeserializeAll({SchemaA,SchemaB},buff))
```

----

## Serializable Types

|       Type       | Bytes                                                      |
|:----------------:|------------------------------------------------------------|
|        I1        | 1                                                          | 
|        I8        | 1                                                          | 
|       I16        | 2                                                          | 
|       I24        | 3                                                          |
|       I32        | 4                                                          | 
|       I40        | 5                                                          | 
|       I48        | 6                                                          | 
|       I54        | 7                                                          | 
|        U1        | 1                                                          | 
|        U8        | 1                                                          | 
|       U16        | 2                                                          | 
|       U24        | 3                                                          |
|       U32        | 4                                                          | 
|       U40        | 5                                                          | 
|       U48        | 6                                                          | 
|       U54        | 7                                                          | 
|       F16        | 2                                                          | 
|       F32        | 4                                                          | 
|       F64        | 8                                                          | 
|      Bool1       | 1                                                          |
|      Bool8       | 1                                                          | 
|     String8      | 8 (8-character max)                                        | 
|     String16     | 16 (16-character max)                                      | 
|     String32     | 32 (32-character max)                                      | 
|     String64     | 64 (64-character max)                                      | 
|      String      | desired len (must use `{Type = "String",Length = number}`) | 
|     String16     | 16 (16-character max)                                      | 
|      Color3      | 12                                                         | 
|     Vector2      | 16                                                         | 
|   Vector2int16   | 4                                                          | 
|     Vector3      | 24                                                         |
|   Vector3int16   | 6                                                          |
|      CFrame      | 96                                                         | 
|   LossyCFrame    | 48                                                         | 
|       Rect       | 32                                                         | 
|     Region3      | 120                                                        |
|   Region3int16   | 12                                                         |
|       UDim       | 8                                                          | 
|      UDim2       | 16                                                         | 
|      vector      | 24                                                         | 
|       Enum       | 4                                                          | 
|   NumberRange    | 8                                                          | 
|  FloatCurveKey   | 16 or 24 `(if you use KeyInterpolationMode.Cubic)`         | 
| RotationCurveKey | 104 or 112 `(if you use KeyInterpoliationMode.Cubic)`      | 
|  ColorSequence   | 1 + 16 * number of `ColorSequenceKeypoint`                 | 
|  NumberSequence  | 1 + 12 * number of `NumberSequenceKeypoint`                | 
