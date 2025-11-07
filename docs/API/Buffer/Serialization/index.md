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

### SerializeCompress

```luau linenums="1"
local Schema : Buffer.BufferSchema = {
	Id = "String64",
	Name = {
		Type = "String",
		Length = 15,
	},
	Position = "Vector3",
	Health = "U54",
	SkinColor = "ColorSequence",
}

local Values = {
	Id = HttpService:GenerateGUID(false):sub(1,64),
	Name = "Name:"..(HttpService:GenerateGUID(false):sub(1,10)),
	Position = Vector3.new(15,250.95,150),
	Health = 1500,
	SkinColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
	})
}

local compressed_buffer = Buffer.SerializeCompress(Schema,Values)
print(compressed_buffer) --> buffer IS NOT A BufferComponent
```

Serializes a set of values according to the provided schema
and then compresses the resulting buffer.

Parameters:

- Schema `BufferSchema`
- Values `table<string, T>`

Returns: buffer

- A compressed buffer produced by first serializing the input
- values and then applying Zstd compression.

!!! warning
    - The returned buffer is not directly readable. Use
        `DeserializeCompressed(...)`
    - Do not use this for buffers smaller than 30 bytes or in the 30–50 bytes range.

----

### DeserializeCompress

```luau linenums="1"
local Schema : Buffer.BufferSchema = {
	Id = "String64",
	Name = {
		Type = "String",
		Length = 15,
	},
	Position = "Vector3",
	Health = "U54",
	SkinColor = "ColorSequence",
}

local Values = {
	Id = HttpService:GenerateGUID(false):sub(1,64),
	Name = "Name:"..(HttpService:GenerateGUID(false):sub(1,10)),
	Position = Vector3.new(15,250.95,150),
	Health = 1500,
	SkinColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
	})
}

local compressed_buffer = Buffer.SerializeCompress(Schema,Values)
local decompressed_buffer = Buffer.DeserializeCompress(Schema,compressed_buffer)
print(decompressed_buffer) --> correspond values
```

Decompresses a previously compressed buffer and then deserializes its content
according to the provided schema.

Parameters:

- Schema `BufferSchema`

The schema describing how data was originally structured and stored.

- compressedBuffer `buffer`

A buffer that was produced using SerializeCompressed(...)
and compressed using Zstd.

Returns: `table<string, T>`

A table of deserialized values mapped by field name.

!!! warning
    - The buffer must have been created with the same schema used here.
    - If the schema does not match the original one, deserialization will fail
        or produce invalid data.
    - You must use a compressed buffer using `:Compress` with the same Compression Algorithm.

----

### SerializeAllCompressed

```luau linenums="1"
local compressed_buffers = Buffer.SerializeAllCompressed({schema_a,schema_b},{value_a,value_b})
print(compressed_buffers) -> {buffer}
```

Serializes and compresses multiple value sets using corresponding schemas.

Parameters:

- Schemas `{BufferSchema}`

An array of schemas. Each schema describes how its corresponding
value set should be serialized.

- Values `{ table<string, T> }`

An array where each entry is a table of named values to be serialized.
The index of each value set must match the index of its schema.

Returns: `{ buffer }`

An array of compressed buffers, one for each (Schema, Values) pair.

!!! info
    - For each index i:
        - Serialize(Schemas[i], Values[i]) → `Buffer`
        - Compress(Buffer) → `CompressedBuffer`
    - The resulting compressed buffer is appended to the output array.

!!! note
    - Schemas and Values must have the same length and aligned ordering.
    - If any schema or value set is invalid, the function throws an error.
    - This is the bulk equivalent of `SerializeCompressed(...).`

----

### DeserializeAllCompressed

```luau linenums="1"
local compressed_buffers = Buffer.SerializeAllCompressed({schema_a,schema_b},{value_a,value_b})
local decompressed_buffers = Buffer.DeserializeAllCompressed({schema_a,schema_b},compressed_buffers)

print(compressed_buffers) -> {buffer}
print(decompressed_buffers) -> {value_a,value_b}
```

Decompresses and deserializes multiple compressed buffers using
their corresponding schemas.

Parameters:

- Schemas `({BufferSchema})`

An array of schemas. Each schema defines how its corresponding
decompressed buffer should be interpreted and reconstructed.

- Buffers `({buffer})`

An array of compressed buffers produced by SerializeAllCompressed(...)
or SerializeCompressed(...). The index of each buffer must match
the index of its schema.

Returns: `{ { [string] : T } }`

An array of deserialized value tables. Each entry corresponds to
the decompressed and deserialized result of the matching schema
and buffer pair.

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
