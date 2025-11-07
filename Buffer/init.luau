--!nonstrict

--[[
    Author: evxry_ll

    Buffer: A powerful library to write data with the "buffer" type.
    
	Documentation : https://evxryyy.github.io/OpenEvxEngine/API/Buffer
	ChangeLogs : https://github.com/evxryyy/OpenEvxEngine/blob/main/Buffer/README.md

    Supported Data Types:
    
    ================ INTEGER TYPES ================
    Signed Integers:
    - I1  (1-bit)   : -1 to 1
    - I8  (8-bit)   : -128 to 127
    - I16 (16-bit)  : -32,768 to 32,767
    - I24 (24-bit)  : -8,388,608 to 8,388,607
    - I32 (32-bit)  : -2,147,483,648 to 2,147,483,647
    - I40 (40-bit)  : -549,755,813,888 to 549,755,813,887
    - I48 (48-bit)  : -140,737,488,355,328 to 140,737,488,355,327
    - I54 (54-bit)  : -9,007,199,254,740,992 to 9,007,199,254,740,991
    
    Unsigned Integers:
    - U1  (1-bit)   : 0 to 1
    - U8  (8-bit)   : 0 to 255
    - U16 (16-bit)  : 0 to 65,535
    - U24 (24-bit)  : 0 to 16,777,215
    - U32 (32-bit)  : 0 to 4,294,967,295
    - U40 (40-bit)  : 0 to 1,099,511,627,775
    - U48 (48-bit)  : 0 to 281,474,976,710,655
    - U54 (54-bit)  : 0 to 18,014,398,509,481,980
    
    ================ FLOATING POINT TYPES ================
    - F16 (16-bit) : Half-precision float
    - F32 (32-bit) : Single-precision float
    - F64 (64-bit) : Double-precision float
    
    ================ OTHER DATA TYPES ================
    - Boolean (1-bit and 8-bit packed)
    - Strings (with various length limits: 8, 16, 32, 64 chars or unlimited)
    - Color3
    - Vector2, Vector3,vector (luau library)
    - Vector2int16, Vector3int16
    - CFrame (both regular and lossy compressed versions)
    - UDim, UDim2
    - Rect
    - Region3, Region3int16
    - Instances (stored in a separate instance buffer)
    - Enum
    - FloatCurveKey
    - RotationCurveKey
    - ColorSequence
    - NumberSequence
    - NumberRange

    You are free to edit this as you want, but if you want to publish it PLEASE READ THE LICENSE.

    For finer control over number and float precision, check Constants in this module or read the documentation.

    Note:
    The buffer can be encrypted for security purposes.

    Endianness:
    Multi-byte integers in this module are written in big-endian order (highest-order byte first).
--]]

-- Roblox Services: 
local HttpService = game:GetService("HttpService")
local EncodingService = game:GetService("EncodingService")

-- Constants: centralizes numeric limits and precision settings (e.g., MIN/MAX for each type)
local Constants = require("@self/Constants")

-- Debug: string templates and helpers for warnings/errors (e.g., "not enough space")
local Debug = require("@self/Debug")

-- Enum : custom enumeration system for defining data types
local BufferEnum = require("@self/BufferType")

-- Util: utility functions for bit manipulation, encoding, etc.
local Utils = require("@self/Utils")
local Zignal = require("@self/_index/Zignal/Zignal")

-- EnumsMap
local EnumsIds,IdsEnums = Utils.GenerateEnumMapping()

--Valid complex type
local ValidComplexType = Utils.ValidComplexType

-- Constructor table: creates BufferComponent instances or wraps an existing buffer
local BufferConstructor = {}
BufferConstructor.__index = BufferConstructor

BufferConstructor.Enum = BufferEnum
BufferConstructor.Constants = Constants
BufferConstructor.Utils = Utils

-- BufferComponent: instance methods for writing data and managing offsets
local BufferComponent = {}
BufferComponent.__index = BufferComponent

--[[
    Type definition for a BufferComponent instance.
    - offset: current write offset (in bytes) into `buffer`
    - instance_offset: current write offset for instance references (if used)
    - buffer: the underlying Roblox buffer
    - instance_buffer: a side-channel storage for Instances (if used elsewhere)
]]
export type BufferComponentClass = typeof(setmetatable({} :: {
	offset : number,
	instance_offset : number,
	buffer : buffer,
	instance_buffer : { Instance },
	CapacityChanged : Zignal.Signal<number,number>,
	OffsetChanged : Zignal.Signal<number,number>,
	InstanceOffsetChanged : Zignal.Signal<number,number>,
},BufferComponent))

--[[
	Type definition for the ReadBool8 function
]]
type Readbool8ReturnType = {
	value : {boolean},
	majority : () -> boolean,
}

type ValueType = BufferEnum.BufferTypeName

--[[
	Type definition for the Buffer Schema (serialize,deserialize)
]]
export type BufferSchema = {
	[string] : BufferEnum.BufferTypeName | {Type : BufferEnum.BufferTypeName, Length : number?}
}

export type BufferSchemaValue = {
	[string] : any
}

--[[
    Create a new BufferComponent with a given initial size (in bytes).
    If size is nil or <= 0, defaults to 1 byte.

    Note: `offset` starts at 0 (first write will go at index 0).
]]
function BufferConstructor.create(size : number) : BufferComponentClass
	if(not size or (size) < 0) then size = 1 end
	local self = setmetatable({
		offset = 0,
		instance_offset = 1,
		buffer = buffer.create(size),
		instance_buffer = {},
		CapacityChanged = Zignal.new(),
		OffsetChanged = Zignal.new(),
		InstanceOffsetChanged = Zignal.new(),
	},BufferComponent)
	return self
end

--[[
    Wrap an existing buffer into a BufferComponent instance so you can continue writing
    and later read from it with :Read[DataTypeName] methods (not shown here).

    Note:
    - This sets `offset` to the current buffer length, so subsequent writes append.
    - `instance_buffer` starts empty; adapt if you rely on instance serialization.
    
    @since v1.0
]]
function BufferConstructor.from(b : buffer) : BufferComponentClass
	if(not b or type(b) ~= "buffer") then
		error(Debug["not a valid type"]:format(type(b),"buffer"))
	end
	local self = setmetatable({
		offset = buffer.len(b),
		instance_offset = 0,
		instance_buffer = {},
		buffer = b,
		CapacityChanged = Zignal.new(),
		OffsetChanged = Zignal.new(),
		InstanceOffsetChanged = Zignal.new(),
	},BufferComponent)
	return self
end

--[[
    Convert the current BufferComponent.buffer to a string.
    Intended as a constructor utility rather than an instance method.
    
    @since v1.1
]]
function BufferConstructor.tostring(BufferComponent : BufferComponentClass)
	return buffer.tostring(BufferComponent.buffer)
end

--[[
    Create a BufferComponent from a string payload.
    Internally converts string -> buffer via buffer.fromstring.
    
    @since v1.1
]]
function BufferConstructor.fromString(str : string) : BufferComponentClass
	if(not str or type(str) ~= "string") then
		error(Debug["not a valid type"]:format(type(str),type("str")))
	end
	return BufferConstructor.from(buffer.fromstring(str))
end

--[[ 
	Serializes the given Values according to the Schema into a BufferComponentClass

	@since v2.0
]]
function BufferConstructor.Serialize<T>(Schema : BufferSchema,Values :  {[string] : T}) : BufferComponentClass
	-- Defensive clones to avoid mutating the caller's tables
	local copiedSchema = table.clone(Schema)
	local copiedValues = table.clone(Values)
	-- Compute exact required capacity and create the buffer
	local size = Utils.GetRequiredBytes(copiedSchema,copiedValues)
	local component = BufferConstructor.new(size)
	for field, fieldType in copiedSchema do
		-- Skip absent values (keeps buffer deterministic and avoids writing garbage)
		if(copiedValues[field] == nil) then continue end
		-- Complex descriptor branch: { Type = "String", Length = N }
		if(typeof(fieldType) == "table" and ValidComplexType[fieldType.Type]) then
			local value = copiedValues[field]
			-- Right-pad with char(31) to reach exact fixed length
			if(#value < fieldType.Length) then
				value = value .. string.rep(string.char(31),fieldType.Length - #copiedValues[field])
			end
			-- Dispatch to the correct writer via __call (e.g., "String")
			component(fieldType.Type,value)
			continue
		end
		-- If a complex-only type is given as a plain string (e.g., "String" without Length), error out
		if(ValidComplexType[fieldType]) then
			local failed = Debug["not valid type for complex schema"]
			failed = failed .. ("%s"):format(debug.info(1,"n"))
			error(failed,2)
		end
		-- Parametrized fixed-size string: "StringN" (e.g., "String32")
		if(string.find(fieldType,"String")) then
			local stringBits = fieldType:match("^String(%d+)$")
			local value = copiedValues[field]
			-- Only pad if N is present (fixed-size variant)
			if(stringBits) then
				if(#value < tonumber(stringBits)) then
					value = value .. string.rep(string.char(31),(tonumber(stringBits) :: number) - #value)
				end
			end
			-- Write using the normal way (e.g., "String32" -> WriteString32)
			component(fieldType,value,#value)
		else
			-- Generic fallback for all non-string types: "U8", "I32", "F32", "CFrame", "vector", etc.
			component(fieldType,copiedValues[field])
		end
	end
	return component
end

--[[
	Deserializes a BufferComponentClass into a table of values according to Schema

	@since v2.0
]]
function BufferConstructor.Deserialize<T>(Schema : BufferSchema,SerializedBuffer : BufferComponentClass) : {[string] : T}
	-- Make a defensive copy of the schema to avoid any side effects during iteration
	local copiedSchema = table.clone(Schema)
	-- Output dictionary of decoded values
	local values = {}
	-- Byte cursor into the main data buffer (does not modify SerializedBuffer's own offset)
	local offset = 0
	-- Separate index for instance reads (instances are stored/read via a dedicated structure)
	local instance_offset = 1
	for field,fieldType in copiedSchema do
		-- Complex descriptor path: a table like { Type = "String", Length = N }
		-- ValidComplexType[...] determines which types must use this shape.
		if(typeof(fieldType) == "table" and ValidComplexType[fieldType.Type]) then
			-- Read using the typed reader. For fixed-length strings we pass Length and offset.
			local value = SerializedBuffer["Read"..fieldType.Type](SerializedBuffer,fieldType.Length,offset)
			-- Strip padding (char 31) used to fill fixed-size strings.
			value = string.gsub(value, string.char(31), "")
			values[field] = value
			-- Advance main byte cursor by the declared fixed length
			offset += fieldType.Length
			continue
		end
		-- If the schema specified a "complex-only" type as a simple string (e.g., "String" without Length),
		-- throw a clear error explaining the correct shape.
		if(ValidComplexType[fieldType]) then
			local failed = Debug["not valid type for complex schema"]
			failed = failed .. ("%s"):format(debug.info(1,"n"))
			error(failed, 2)
		end
		-- Pattern-based parametrized types:
		-- BooleanN (e.g., "Boolean1", "Boolean8"), FloatN (e.g., "Float32"), StringN (e.g., "String64")
		local boolBits = fieldType:match("^Boolean(%d+)$")
		local floatBits = fieldType:match("^Float(%d+)$")
		local stringBits = fieldType:match("^String(%d+)$")
		if(boolBits) then
			-- Read a packed boolean variant; we assume it consumes exactly 1 byte here.
			-- If in your implementation BooleanN consumes a different size, adjust the offset increment.
			local value = SerializedBuffer["ReadBool"..boolBits](SerializedBuffer,offset)
			values[field] = value
			offset += 1
		elseif(floatBits) then
			-- Read F16/F32/F64 based on the captured bit-size and advance by the configured byte count
			local value = SerializedBuffer["ReadF"..floatBits](SerializedBuffer,offset)
			values[field] = value
			offset += Constants.REQUIRED_BYTES["F"..floatBits]
			
		elseif(stringBits) then
			-- Fixed-length string variant like "String32" -> length = 32
			local value = SerializedBuffer:ReadString(stringBits,offset)
			-- Remove padding char(31) added during write for fixed-size strings
			value = string.gsub(value, string.char(31), "")
			values[field] = value
			offset += Constants.REQUIRED_BYTES[fieldType]
		elseif(fieldType == "vector") then
			-- Alias for a Vector read (e.g., Vector3) with a known fixed byte size
			local value = SerializedBuffer:ReadVector(offset)
			values[field] = value
			offset += Constants.REQUIRED_BYTES[fieldType]
		elseif(fieldType == "Instance") then
			-- Instances are stored in a separate structure and addressed by index.
			-- We do not advance the main byte cursor for Instances.
			values[field] = SerializedBuffer:ReadInstance(instance_offset)
			instance_offset += 1
		else
			-- Generic fallback: call a matching Read..Type at the current offset.
			-- Examples: "U32" -> ReadU32, "CFrame" -> ReadCFrame, "Color3" -> ReadColor3, etc.
			local value = SerializedBuffer["Read"..fieldType](SerializedBuffer,offset)
			values[field] = value
			-- Advance by a fixed size or compute the size dynamically from the decoded value.
			if(typeof(Constants.REQUIRED_BYTES[fieldType]) == "function") then
				offset += Constants.REQUIRED_BYTES[fieldType](value)
			else
				offset += Constants.REQUIRED_BYTES[fieldType]
			end
		end
	end
	return values
end

--[[
	Same as Serialize but accepts a table of values and a table of schemas.
	Each schema will be serialized with its corresponding value.

	Note:
	This return a numeric table with BufferComponentClass as values in order.

	@since v2.2
]]
function BufferConstructor.SerializeAll(Schemas : {BufferSchema},Values : {BufferSchemaValue}) : {BufferComponentClass}
	if(#Schemas <= 0 or #Values <= 0) then 
		error(Debug["need atleast have 1 Schema or 1 Value"])
	end
	local serializedBuffers = {}
	local schemaCount = #Schemas
	for i = 1,schemaCount,1 do
		local schema = Schemas[i]
		local values = Values[i]
		if(typeof(schema) ~= "table" or typeof(values) ~= "table") then
			error(Debug["must provide a valid Schema and Value"])
		end
		local serializeBuffer = BufferConstructor.Serialize(schema,values)
		table.insert(serializedBuffers,serializeBuffer)		
	end
	return serializedBuffers
end

--[[
	Same as Deserialize but accepts a table of serialized buffers and a table of schemas.
	Each schema will be deserialized with its corresponding serialized buffer.
	
	Note:
	This return a numeric table with each BufferSchemaValue as values from the correspond BufferComponent, in order.
	
	@since v2.2
]]
function BufferConstructor.DeserializeAll(Schemas : {BufferSchema},SerializedBuffers : {BufferComponentClass}) : {BufferSchemaValue}
	if(#Schemas <= 0) then 
		error(Debug["need atleast 1 Schema"])
	end
	local deserializedBuffers = {}
	local schemaCount = #Schemas
	for i = 1,schemaCount,1 do
		local schema = Schemas[i]
		local serializedBuffer = SerializedBuffers[i]
		if(typeof(schema) ~= "table" or typeof(serializedBuffer) ~= "table") then
			error(Debug["must provide a valid Schema and BufferComponent"])
		end
		local deserializedBuffer = BufferConstructor.Deserialize(schema,serializedBuffer)
		table.insert(deserializedBuffers,deserializedBuffer)
	end
	return deserializedBuffers
end

--[[
	Return the decompressed buffer as an BufferComponentClass with the target Compression Algorithm
	The buffer must be already compressed with the target Compression Algorithm
	
	Note:
	- This function use <code>EncodingService:DecompressBuffer()</code>. Please see the Roblox API for more infos

	@since v2.6
]]
function BufferConstructor.Decompress(b : buffer,algorithm : Enum.CompressionAlgorithm) : BufferComponentClass
	return BufferConstructor.from(EncodingService:DecompressBuffer(b,algorithm))
end

--[[
    Serializes a set of values according to the provided schema
    and then compresses the resulting buffer.

    Parameters:
        Schema (BufferSchema)
        Values (table<string, T>)
        
    Returns: buffer
            A compressed buffer produced by first serializing the input
            values and then applying Zstd compression.

    Notes:
        - This function is effectively a convenience wrapper for:
              Serialize(...) → Compress(...)
        - The returned buffer is not directly readable. Use
              DeserializeCompressed(...)
          to restore the original values.
          
    @since v2.6
]]
function BufferConstructor.SerializeCompressed<T>(Schema : BufferSchema,Values : {[string] : T}) : buffer
	local serializedBuffer = BufferConstructor.Serialize(Schema,Values)
	local compressed = serializedBuffer:Compress(Enum.CompressionAlgorithm.Zstd)
	return compressed
end

--[[
    Decompresses a previously compressed buffer and then deserializes its content
    according to the provided schema.

    Parameters:
        Schema (BufferSchema)
            The schema describing how data was originally structured and stored.

        compressedBuffer (buffer)
            A buffer that was produced using SerializeCompressed(...)
            and compressed using Zstd.

    Returns: table<string, T>
            A table of deserialized values mapped by field name.

    Notes:
        - This function performs the reverse operation of SerializeCompressed(...):
              Decompress(...) → Deserialize(...)
        - The buffer must have been created with the same schema used here.
        - If the schema does not match the original one, deserialization will fail
          or produce invalid data.
    
    @since v2.6
]]
function BufferConstructor.DeserializeCompressed<T>(Schema : BufferSchema,compressedBuffer : buffer) : {[string] : T}
	local component = BufferConstructor.From(EncodingService:DecompressBuffer(compressedBuffer,Enum.CompressionAlgorithm.Zstd))
	local deserialized = BufferConstructor.Deserialize(Schema,component)
	return deserialized
end

--[[
   Serializes and compresses multiple value sets using corresponding schemas.

    Parameters:
        Schemas ({BufferSchema})
            An array of schemas. Each schema describes how its corresponding
            value set should be serialized.

        Values ({ table<string, T> })
            An array where each entry is a table of named values to be serialized.
            The index of each value set must match the index of its schema.

    Returns: { buffer }
            An array of compressed buffers, one for each (Schema, Values) pair.

    Behavior:
        For each index i:
            Serialize(Schemas[i], Values[i]) → Buffer
            Compress(Buffer) → CompressedBuffer
        The resulting compressed buffer is appended to the output array.

    Notes:
        - Schemas and Values must have the same length and aligned ordering.
        - If any schema or value set is invalid, the function throws an error.
        - This is the bulk equivalent of SerializeCompressed(...).
        
    @since v2.6
]]
function BufferConstructor.SerializeAllCompressed<T>(Schemas : {BufferSchema},Values : {{[string] : T}}) : {buffer}
	local compressed = {}
	local schemaCount = #Schemas
	for i = 1,schemaCount,1 do
		local schema = Schemas[i]
		local values = Values[i]
		if(typeof(schema) ~= "table" or typeof(values) ~= "table") then
			error(Debug["must provide a valid Schema and Value"])
		end
		local serializeBuffer = BufferConstructor.SerializeCompressed(schema,values)
		table.insert(compressed,serializeBuffer)		
	end
	return compressed
end

--[[
    Decompresses and deserializes multiple compressed buffers using
    their corresponding schemas.

    Parameters:
        Schemas ({BufferSchema})
            An array of schemas. Each schema defines how its corresponding
            decompressed buffer should be interpreted and reconstructed.

        Buffers ({buffer})
            An array of compressed buffers produced by SerializeAllCompressed(...)
            or SerializeCompressed(...). The index of each buffer must match
            the index of its schema.

    Returns: { { [string] : T } }
            An array of deserialized value tables. Each entry corresponds to
            the decompressed and deserialized result of the matching schema
            and buffer pair.

    Behavior:
        For each index i:
            Decompress(Buffers[i]) → Buffer
            Deserialize(Schemas[i], Buffer) → Values
        The resulting values table is appended to the output array.

    Notes:
        - Schemas and Buffers must be the same length and aligned by index.
        - This is the bulk equivalent of DeserializeCompressed(...).
        - If any schema or buffer is invalid, an assertion error is thrown.
        
    @since v2.6
]]
function BufferConstructor.DeserializeAllCompressed<T>(Schemas : {BufferSchema},Buffers : {buffer}) : {{[string] : T}}
	local decompressed = {}
	local schemaCount = #Schemas
	for i = 1,schemaCount,1 do
		local schema = Schemas[i]
		local compressedBuffer = Buffers[i]
		assert(type(schema) == "table" and type(compressedBuffer) == "buffer","Schema or CompressedBuffer is not valid.")
		local deserializedBuffer = BufferConstructor.DeserializeCompressed(schema,compressedBuffer)
		table.insert(decompressed,deserializedBuffer)
	end
	return decompressed
end

--[[
    __tostring metamethod for debug/logging: shows current buffer size in bytes.
    
    @since v1.1
]]
function BufferComponent.__tostring(self : BufferComponentClass)
	return `BufferComponent(Size:{buffer.len(self.buffer)})`
end

--[[
    __len metamethod for buffer length.
    - Returns the length of the buffer in bytes.
    
    @since v1.6.4
]]
function BufferComponent.__len(self : BufferComponentClass)
	return buffer.len(self.buffer)
end

--[[
    __add metamethod for buffer resizing.
    - Resizes the buffer by the specified number of bytes.
    - Returns the updated BufferComponent instance.
    
    @since v1.6.4
]]
function BufferComponent.__add(self : BufferComponentClass,value : number)
	if(not value or type(value) ~= "number") then
		error(Debug["not a valid type"]:format(type(value),type(10)))
	end
	self:allocate(value)
	return self
end

--[[
	Expands the underlying buffer by a numeric factor using the * operator.

	- Allocates a new buffer of size modf(oldSize * value), float are not allowed.
	- Copies the old contents into the new buffer (starting at offset 0).
	- Keeps the same write offset.
	- Returns the updated BufferComponent instance.
	- Throws an error if the value is less than or equal to 1.

	@since v1.9 
]]
function BufferComponent.__mul(self : BufferComponentClass,value : number)
	if(not value or type(value) ~= "number") then
		error(Debug["not a valid type"]:format(type(value),type(10)))
	end
	value = math.modf(value)
	if(value <= 1) then error("You can't reduce the buffer size") end
	local oldSize = buffer.len(self.buffer)
	local newSize = (buffer.len(self.buffer) * value)
	local newBuffer = buffer.create(newSize)
	buffer.copy(newBuffer,0,self.buffer,0,buffer.len(self.buffer))
	self.buffer = newBuffer
	self.CapacityChanged:Fire(oldSize,newSize)
	return self
end

--[[
	Dynamic writer dispatch via __call.
	Examples:
	  buffer("U32", 10)
	  buffer("String", "hello")
	  buffer("Boolean1", true)
	  buffer("Float32", 1.5)
	  buffer("FloatCurveKey", key)
	  buffer("RotationCurveKey", rKey)
	  buffer("ColorSequence", cseq)
	  buffer("NumberSequence", nseq)
	  buffer("vector", v)
	  
	@since v1.9
]]
function BufferComponent.__call<T>(self : BufferComponentClass,valueType : ValueType,value : T,__optionalParam : any?)
	local boolBits = valueType:match("^Boolean(%d+)$")
	local floatBits = valueType:match("^Float(%d+)$")
	local stringBits = valueType:match("^String(%d+)$")
	if(boolBits) then
		valueType = "WriteBool" .. boolBits
		self[valueType](self,value)
	elseif(floatBits) then
		valueType = "WriteF" .. floatBits
		self[valueType](self,value)
	elseif(valueType == "vector") then
		self:WriteVector(value)
	elseif(stringBits) then
		self["Write"..valueType](self,value,__optionalParam)
	else
		self["Write"..valueType](self,value)
	end
end

--[[
    Allocate additional space by creating a new buffer with increased capacity,
    copying the existing content, and swapping references.
    
	@since v1.0
]]
function BufferComponent.allocate(self : BufferComponentClass,size : number) : ()
	local oldSize = buffer.len(self.buffer)
	local newSize = buffer.len(self.buffer)+size
	local new_buffer = buffer.create(newSize)
	buffer.copy(new_buffer,0,self.buffer,0,buffer.len(self.buffer))
	self.buffer = new_buffer
	self.CapacityChanged:Fire(oldSize,newSize)
end

--[[
    Write a signed 1-bit integer (-1 to 1).
    - The value is clamped to the allowed range and truncated to an integer.
    - Stored using buffer.writei8 (occupies 1 byte).
    - Endianness is irrelevant for single-byte writes.
    
    @since v1.3
]]
function BufferComponent.WriteI1(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT1,Constants.MAX_INT1)
	local bytes = 1
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	-- Using pcall to catch out-of-bounds; `outOfBounds` holds the error message if any.
	local success,outOfBounds = pcall(buffer.writei8,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 1
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a signed 8-bit integer (-128 to 127).
    - Clamped and truncated to integer.
    - 1 byte, big-endian N/A.
    
    @since v1.0
]]
function BufferComponent.WriteI8(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT8,Constants.MAX_INT8)
	local bytes = 1
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writei8,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 1
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a signed 16-bit integer (-32768 to 32767).
    - Clamped and truncated.
    - 2 bytes, big-endian via buffer.writei16.
    
    @since v1.0
]]
function BufferComponent.WriteI16(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT16,Constants.MAX_INT16)
	local bytes = 2
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writei16,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 2
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a signed 24-bit integer (-8,388,608 to 8,388,607).
    - Clamped and truncated.
    - 3 bytes, big-endian manual packing using bit32.extract.
    
    @since v1.0
]]
function BufferComponent.WriteI24(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.max(Constants.MIN_INT24,math.min(Constants.MAX_INT24,number))
	number = math.modf(number)
	local bytes = 3
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian: high byte first
		buffer.writeu8(self.buffer,self.offset + 0,bit32.extract(number,16,8))
		buffer.writeu8(self.buffer,self.offset + 1,bit32.extract(number,8,8))
		buffer.writeu8(self.buffer,self.offset + 2,bit32.extract(number,0,8))
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 3
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a signed 32-bit integer (-2,147,483,648 to 2,147,483,647).
    - Clamped and truncated.
    - 4 bytes, big-endian via buffer.writei32.
    
    @since v1.0
]]
function BufferComponent.WriteI32(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT32,Constants.MAX_INT32)
	local bytes = 4
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writei32,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 4
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a signed 40-bit integer (-549,755,813,888 to 549,755,813,887).
    - Clamped and truncated.
    - If negative, add 2^40 to represent as unsigned (two's complement style) before writing.
    - 5 bytes, big-endian manual packing.
    
    @since v1.0
]]
function BufferComponent.WriteI40(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT40,Constants.MAX_INT40)
	if(number < 0) then
		-- Convert negative to unsigned representation over 40 bits (two's complement range)
		number += 0x10000000000
	end
	local bytes = 5
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local succes,outOfBounds = pcall(function()
		-- Big-endian packing: 5 bytes from MSB to LSB
		buffer.writeu8(self.buffer,self.offset,math.floor(number / 0x100000000) % 0x100)
		buffer.writeu8(self.buffer,self.offset + 1,bit32.extract(number % 0x100000000, 24, 8))
		buffer.writeu8(self.buffer,self.offset + 2,bit32.extract(number % 0x100000000, 16, 8))
		buffer.writeu8(self.buffer,self.offset + 3,bit32.extract(number % 0x100000000, 8, 8))
		buffer.writeu8(self.buffer,self.offset + 4,bit32.extract(number % 0x100000000, 0, 8))
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 5
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a signed 48-bit integer (-140,737,488,355,328 to 140,737,488,355,327).
    - Clamped and truncated.
    - If negative, add 2^48 to represent as unsigned before writing.
    - 6 bytes, big-endian manual packing.
    
    @since v1.0
]]
function BufferComponent.WriteI48(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT48,Constants.MAX_INT48)
	if(number < 0) then
		-- Represent as 48-bit unsigned for storage
		number += 0x1000000000000 -- 2^48
	end
	local bytes = 6
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing: 6 bytes MSB -> LSB
		local byte6 = math.floor(number / 0x10000000000) % 0x100  -- Bits 40-47
		local byte5 = math.floor(number / 0x100000000) % 0x100    -- Bits 32-39
		local byte4 = bit32.extract(number % 0x100000000, 24, 8)  -- Bits 24-31
		local byte3 = bit32.extract(number % 0x100000000, 16, 8)  -- Bits 16-23
		local byte2 = bit32.extract(number % 0x100000000, 8, 8)   -- Bits 8-15
		local byte1 = bit32.extract(number % 0x100000000, 0, 8)   -- Bits 0-7
		buffer.writeu8(self.buffer,self.offset,byte6)
		buffer.writeu8(self.buffer,self.offset + 1,byte5)
		buffer.writeu8(self.buffer,self.offset + 2,byte4)
		buffer.writeu8(self.buffer,self.offset + 3,byte3)
		buffer.writeu8(self.buffer,self.offset + 4,byte2)
		buffer.writeu8(self.buffer,self.offset + 5,byte1)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 6
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a signed 54-bit integer (-9,007,199,254,740,992 to 9,007,199,254,740,991).
    - Clamped and truncated.
    - If negative, add 2^54 to represent as unsigned before writing.
    - 7 bytes, big-endian manual packing.
    
    @since v1.0
]]
function BufferComponent.WriteI54(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT54,Constants.MAX_INT54)
	if(number < 0) then
		-- Represent as 54-bit unsigned for storage
		number += Constants.MAX_UINT54
	end
	local bytes = 7
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing: 7 bytes MSB -> LSB
		local byte7 = math.floor(number / 0x1000000000000) % 0x100 -- Bits 48-53
		local byte6 = math.floor(number / 0x10000000000) % 0x100   -- Bits 40-47
		local byte5 = math.floor(number / 0x100000000) % 0x100     -- Bits 32-39
		local byte4 = bit32.extract(number % 0x100000000, 24, 8)   -- Bits 24-31
		local byte3 = bit32.extract(number % 0x100000000, 16, 8)   -- Bits 16-23
		local byte2 = bit32.extract(number % 0x100000000, 8, 8)    -- Bits 8-15
		local byte1 = bit32.extract(number % 0x100000000, 0, 8)    -- Bits 0-7
		buffer.writeu8(self.buffer, self.offset, byte7)
		buffer.writeu8(self.buffer, self.offset + 1, byte6)
		buffer.writeu8(self.buffer, self.offset + 2, byte5)
		buffer.writeu8(self.buffer, self.offset + 3, byte4)
		buffer.writeu8(self.buffer, self.offset + 4, byte3)
		buffer.writeu8(self.buffer, self.offset + 5, byte2)
		buffer.writeu8(self.buffer, self.offset + 6, byte1)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 7
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write an unsigned 8-bit integer (0 to 255).
    - Clamped and truncated.
    - 1 byte.
    
    @since v1.0
]]
function BufferComponent.WriteU8(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT8)
	local bytes = 1
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writeu8,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 1
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write an unsigned 16-bit integer (0 to 65,535).
    - Clamped and truncated.
    - 2 bytes, big-endian via buffer.writeu16.
    
    @since v1.0
]]
function BufferComponent.WriteU16(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT16)
	local bytes = 2
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writeu16,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 2
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write an unsigned 24-bit integer (0 to 16,777,215).
    - Clamped and truncated.
    - 3 bytes, big-endian manual packing.
    
    @since v1.0
]]
function BufferComponent.WriteU24(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.max(Constants.MIN_UINT,math.min(Constants.MAX_UINT24,number))
	number = math.modf(number)
	local bytes = 3
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian manual packing
		buffer.writeu8(self.buffer,self.offset + 0,bit32.extract(number,16,8))
		buffer.writeu8(self.buffer,self.offset + 1,bit32.extract(number,8,8))
		buffer.writeu8(self.buffer,self.offset + 2,bit32.extract(number,0,8))
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 3
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write an unsigned 32-bit integer (0 to 4,294,967,295).
    - Clamped and truncated.
    - 4 bytes, big-endian via buffer.writeu32.
    
    @since v1.0
]]
function BufferComponent.WriteU32(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT32)
	local bytes = 4
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writeu32,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 4
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write an unsigned 40-bit integer (0 to 1,099,511,627,775).
    - Clamped.
    - 5 bytes, big-endian manual packing.
    
    @since v1.0
]]
function BufferComponent.WriteU40(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(number,Constants.MIN_UINT,Constants.MAX_UINT40)
	-- Precompute high part (top 8 bits) and low 32-bit remainder
	local byte5 = math.floor(number / 0x100000000) % 0x100 
	local remainder = number % 0x100000000
	local bytes = 5
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing
		buffer.writeu8(self.buffer, self.offset, byte5)
		buffer.writeu8(self.buffer, self.offset + 1, bit32.extract(remainder, 24, 8))
		buffer.writeu8(self.buffer, self.offset + 2, bit32.extract(remainder, 16, 8))
		buffer.writeu8(self.buffer, self.offset + 3, bit32.extract(remainder, 8, 8))
		buffer.writeu8(self.buffer, self.offset + 4, bit32.extract(remainder, 0, 8))
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 5
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write an unsigned 48-bit integer (0 to 281,474,976,710,655).
    - Clamped and truncated.
    - 6 bytes, big-endian manual packing.
    
    @since v1.0
]]
function BufferComponent.WriteU48(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT48)
	local bytes = 6
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing: 6 bytes MSB -> LSB
		local byte6 = math.floor(number / 0x10000000000) % 0x100  -- Bits 40-47
		local byte5 = math.floor(number / 0x100000000) % 0x100    -- Bits 32-39
		local byte4 = bit32.extract(number % 0x100000000, 24, 8)  -- Bits 24-31
		local byte3 = bit32.extract(number % 0x100000000, 16, 8)  -- Bits 16-23
		local byte2 = bit32.extract(number % 0x100000000, 8, 8)   -- Bits 8-15
		local byte1 = bit32.extract(number % 0x100000000, 0, 8)   -- Bits 0-7
		buffer.writeu8(self.buffer,self.offset,byte6)
		buffer.writeu8(self.buffer,self.offset + 1,byte5)
		buffer.writeu8(self.buffer,self.offset + 2,byte4)
		buffer.writeu8(self.buffer,self.offset + 3,byte3)
		buffer.writeu8(self.buffer,self.offset + 4,byte2)
		buffer.writeu8(self.buffer,self.offset + 5,byte1)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 6
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write an unsigned 54-bit integer (0 to 18,014,398,509,481,980).
    - Clamped and truncated.
    - 7 bytes, big-endian manual packing.
    
    @since v1.0
]]
function BufferComponent.WriteU54(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT54)
	local bytes = 7
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing: 7 bytes MSB -> LSB
		local byte7 = math.floor(number / 0x1000000000000) % 0x100 -- Bits 48-53
		local byte6 = math.floor(number / 0x10000000000) % 0x100   -- Bits 40-47
		local byte5 = math.floor(number / 0x100000000) % 0x100     -- Bits 32-39
		local byte4 = bit32.extract(number % 0x100000000, 24, 8)   -- Bits 24-31
		local byte3 = bit32.extract(number % 0x100000000, 16, 8)   -- Bits 16-23
		local byte2 = bit32.extract(number % 0x100000000, 8, 8)    -- Bits 8-15
		local byte1 = bit32.extract(number % 0x100000000, 0, 8)    -- Bits 0-7
		buffer.writeu8(self.buffer, self.offset, byte7)
		buffer.writeu8(self.buffer, self.offset + 1, byte6)
		buffer.writeu8(self.buffer, self.offset + 2, byte5)
		buffer.writeu8(self.buffer, self.offset + 3, byte4)
		buffer.writeu8(self.buffer, self.offset + 4, byte3)
		buffer.writeu8(self.buffer, self.offset + 5, byte2)
		buffer.writeu8(self.buffer, self.offset + 6, byte1)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 7
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a string clamped to max 8 characters.
    - `len` is the intended fixed length to write.
    - The input string is truncated to `len` (clamped to [MIN_STRING, MAX_STRING8]).
    - Important: this function writes a fixed number of bytes (len). The reader must know `len`.
    
    @since v1.0
]]
function BufferComponent.WriteString8(self : BufferComponentClass,value : string,len : number)
	assert(type(value) == "string" and type(len) == "number",`{type(value)} and {type(len)} is not valid please include a string and a number`)
	value = string.sub(value,1,math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING8))
	len = math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING8);
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= len and len <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(len,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,len)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += len
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a string clamped to max 16 characters.
    See notes in WriteString8 regarding fixed-length writes and capacity check.
    
    @since v1.0
]]
function BufferComponent.WriteString16(self : BufferComponentClass,value : string,len : number)
	assert(type(value) == "string" and type(len) == "number",`{type(value)} and {type(len)} is not valid please include a string and a number`)
	value = string.sub(value,1,math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING16))
	len = math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING16);
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= len and len <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(len,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,len)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += len
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a string clamped to max 32 characters.
    See notes in WriteString8 regarding fixed-length writes and capacity check.
    
    @since v1.0
]]
function BufferComponent.WriteString32(self : BufferComponentClass,value : string,len : number)
	assert(type(value) == "string" and type(len) == "number",`{type(value)} and {type(len)} is not valid please include a string and a number`)
	value = string.sub(value,1,math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING32))
	len = math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING32);
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= len and len <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(len,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,len)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += len
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a string clamped to max 64 characters.
    See notes in WriteString8 regarding fixed-length writes and capacity check.
    
    @since v1.0
]]
function BufferComponent.WriteString64(self : BufferComponentClass,value : string,len : number)
	assert(type(value) == "string" and type(len) == "number",`{type(value)} and {type(len)} is not valid please include a string and a number`)
	value = string.sub(value,1,math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING64))
	len = math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING64);
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= len and len <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(len,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,len)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += len
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a string without caring about length limits.
    - Writes exactly #value bytes.
    - Reader must know or infer the length (no prefix is written).
    
    @since v1.0
]]
function BufferComponent.WriteString(self : BufferComponentClass,value : string)
	assert(type(value) == "string","please insert a string to write")
	local bytes = #value
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,#value)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += #value
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a single boolean using 1 bit.
    - nil/false -> 0, anything else -> 1
    
    @since v1.0
]]
function BufferComponent.WriteBool1(self : BufferComponentClass,value : any)
	local bytes = 1
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local bitsToWrite = 1
	local bitOffset =  (self.offset and (self.offset * 8)) or 0
	local success,outOfBounds = pcall(buffer.writebits,self.buffer,bitOffset,bitsToWrite,if(value) then 1 else 0)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 1
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write 8 booleans packed into 1 byte.
    - Accepts an array-like table of up to 8 values.
    - Each truthy value sets the corresponding bit to 1.
    
    @since v1.0
]]
function BufferComponent.WriteBool8(self : BufferComponentClass,value : {any})
	assert(type(value) == "table","please insert an array")
	local bytes = 1
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		for i = 1,8 do
			buffer.writebits(self.buffer,self.offset * 8 + i-1,1,if(value[i]) then 1 else 0)
		end
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 1
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a 16-bit float (half-precision) to the buffer.
    - Lower precision than F32/F64; expect rounding.
    - NaN/Inf are handled; finite values are encoded with sign/exponent/mantissa.
    
    @since v1.0
]]
function BufferComponent.WriteF16(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	local bytes = 2
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		local uint16
		if number == 0 then
			uint16 = 0
		elseif number ~= number then  -- NaN
			uint16 = 0x7E00
		elseif number == math.huge then -- +inf
			uint16 = 0x7C00
		elseif number == -math.huge then -- -inf
			uint16 = 0xFC00
		else
			-- Determine sign
			local sign = 0
			if number < 0 then
				sign = 1
				number = -number
			end
			-- Binary scientific notation
			local exponent = math.floor(math.log(number, 2))
			local mantissa = number / (2 ^ exponent) - 1
			-- Bias exponent
			exponent = exponent + 15
			if exponent <= 0 then
				-- Denormalized
				mantissa = number / (2 ^ -14)
				exponent = 0
			elseif exponent >= 31 then
				-- Overflow -> Inf
				uint16 = bit32.bor(bit32.lshift(sign, 15), 0x7C00)
				buffer.writeu16(self.buffer, self.offset, uint16)
				return
			end
			-- Assemble the 16-bit value: [sign(1) | exponent(5) | mantissa(10)]
			uint16 = bit32.bor(
				bit32.lshift(sign, 15),
				bit32.lshift(exponent, 10),
				bit32.band(math.floor(mantissa * 1024), 0x3FF)
			)
		end
		-- Write as big-endian uint16
		buffer.writeu16(self.buffer, self.offset, uint16)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 2
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a 32-bit float to the buffer.
    - 4 bytes, big-endian.
    
    @since v1.0
]]
function BufferComponent.WriteF32(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	local bytes = 4
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writef32,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 4
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a 64-bit float to the buffer.
    - 8 bytes, big-endian.
    
    @since v1.0
]]
function BufferComponent.WriteF64(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	local bytes = 8
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writef64,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += 8
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a single unsigned bit (0 or 1).
    - Reserves 1 byte (by design)
    
    @since v1.3
]]
function BufferComponent.WriteU1(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT1)
	local bytes = 1
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writebits,self.buffer,self.offset * 8,1,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Store an Instance in the side `instance_buffer`.
    - Does not write anything to the raw byte buffer.
    - `instance_offset` is incremented to track count/index.
    
    @since v1.0
]]
function BufferComponent.WriteInstance(self : BufferComponentClass,Instance : Instance)
	if(not Instance or not Instance:IsA("Instance")) then warn(`{Instance} is not a Instance.`) return end
	table.insert(self.instance_buffer,Instance)
	local oldOffset = self.instance_offset
	self.instance_offset += 1
	self.InstanceOffsetChanged:Fire(oldOffset,self.instance_offset)
end

--[[
    Write a Vector2 as two f64 (x, y).
    - 16 bytes total.
    
    @since v1.0
]]
function BufferComponent.WriteVector2(self : BufferComponentClass,vector2 : Vector2)
	assert(typeof(vector2) == "Vector2","vector2 must be a Vector2")
	local x = vector2.X
	local y = vector2.Y
	local bytes = 16
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef64(self.buffer,self.offset,x)
		buffer.writef64(self.buffer,self.offset + 8,y)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a Vector3 as three f64 (x, y, z).
    - 24 bytes total.
    
    @since v1.0
]]
function BufferComponent.WriteVector3(self : BufferComponentClass,vector3 : Vector3)
	assert(typeof(vector3) == "Vector3","vector3 must be a Vector3")
	local x = vector3.X
	local y = vector3.Y
	local z = vector3.Z
	local bytes = 24
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef64(self.buffer,self.offset,x)
		buffer.writef64(self.buffer,self.offset + 8,y)
		buffer.writef64(self.buffer,self.offset + 16,z)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a Vector2int16 as two i16 (x, y).
    - 4 bytes total.
    - Values clamped to int16 range.
    
    @since v1.0
]]
function BufferComponent.WriteVector2Int16(self : BufferComponentClass,vector2int16 : Vector2int16)
	assert(typeof(vector2int16) == "Vector2int16","vector2int16 must be a Vector2int16")
	local x = math.clamp(vector2int16.X,Constants.MIN_INT16,Constants.MAX_INT16)
	local y = math.clamp(vector2int16.Y,Constants.MIN_INT16,Constants.MAX_INT16)
	local bytes = 4
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writei16(self.buffer,self.offset,x)
		buffer.writei16(self.buffer,self.offset + 2,y)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a Vector3int16 as three i16 (x, y, z).
    - 6 bytes total.
    - Values clamped to int16 range.
    
    @since v1.0
]]
function BufferComponent.WriteVector3Int16(self : BufferComponentClass,vector3int16 : Vector3int16)
	assert(typeof(vector3int16) == "Vector3int16","vector3int16 must be a Vector3int16")
	local x = math.clamp(vector3int16.X,Constants.MIN_INT16,Constants.MAX_INT16)
	local y = math.clamp(vector3int16.Y,Constants.MIN_INT16,Constants.MAX_INT16)
	local z = math.clamp(vector3int16.Z,Constants.MIN_INT16,Constants.MAX_INT16)
	local bytes = 6
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writei16(self.buffer,self.offset,x)
		buffer.writei16(self.buffer,self.offset + 2,y)
		buffer.writei16(self.buffer,self.offset + 4,z)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a full-precision CFrame as 12 f64 components (position + rotation matrix).
    - 12 * 8 = 96 bytes total.

    Endianness: buffer.writef64 is big-endian.
    
    @since v1.0
]]
function BufferComponent.WriteCFrame(self : BufferComponentClass,CF : CFrame)
	assert(typeof(CF) == "CFrame","CF must be a CFrame")
	local bytes = 96 
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		local components = {CF:GetComponents()}
		for i = 0, 11 do
			buffer.writef64(self.buffer, self.offset + (i * 8), components[i + 1])
		end
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a lossy (compressed) CFrame as 12 f32 components.
    - 12 * 4 = 48 bytes total.
    - Less precision than WriteCFrame but smaller.
    
    @since v1.0
]]
function BufferComponent.WriteLossyCFrame(self : BufferComponentClass,CF : CFrame)
	assert(typeof(CF) == "CFrame","CF must be a CFrame")
	local bytes = 48
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		local components = {CF:GetComponents()}
		for i = 0, 11 do
			buffer.writef32(self.buffer, self.offset + (i * 4), components[i + 1])
		end
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a UDim as two f32 (Scale, Offset).
    - 8 bytes total.
    
    @since v1.0
]]
function BufferComponent.WriteUDim(self : BufferComponentClass,udim : UDim)
	assert(typeof(udim) == "UDim","Udim must be a Udim")
	local Scale = udim.Scale
	local Offset = udim.Offset
	local bytes = 8
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef32(self.buffer,self.offset,Scale)
		buffer.writei32(self.buffer,self.offset + 4,Offset)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a UDim2 as four f32 (X.Scale, Y.Scale, X.Offset, Y.Offset).
    - 16 bytes total.
    
    @since v1.0
]]
function BufferComponent.WriteUDim2(self : BufferComponentClass,udim2 : UDim2)
	assert(typeof(udim2) == "UDim2","Udim2 must be a Udim2")
	local ScaleX,ScaleY = udim2.X.Scale,udim2.Y.Scale
	local OffsetX,OffsetY = udim2.X.Offset,udim2.Y.Offset
	local bytes = 16
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef32(self.buffer,self.offset,ScaleX)
		buffer.writef32(self.buffer,self.offset + 4,ScaleY)
		buffer.writei32(self.buffer,self.offset + 8,OffsetX)
		buffer.writei32(self.buffer,self.offset + 12,OffsetY)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a Color3 as three f32 (r, g, b).
    - 12 bytes total.
    - Values clamped to float32 range [0,1] typically already valid.
    
    @since v1.0
]]
function BufferComponent.WriteColor3(self : BufferComponentClass,color : Color3)
	assert(typeof(color) == "Color3","color must be a Color3")
	local bytes = 12
	local r = color.R
	local g = color.G
	local b = color.B
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef32(self.buffer,self.offset,r)
		buffer.writef32(self.buffer,self.offset + 4,g)
		buffer.writef32(self.buffer,self.offset + 8,b)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	local oldOffset = self.offset
	self.offset += bytes
	self.OffsetChanged:Fire(oldOffset,self.offset)
end

--[[
    Write a Rect as two Vector2 (Min, Max) using f64.
    - 32 bytes total (2 * 16).
    - Relies on WriteVector2 to do the actual writing and offset increments.
    
    @since v1.0
]]
function BufferComponent.WriteRect(self : BufferComponentClass,rect : Rect)
	assert(typeof(rect) == "Rect","rect must be a Rect")
	local bytes = 32
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	self:WriteVector2(rect.Min)
	self:WriteVector2(rect.Max)
end

--[[
    Write a Region3 as CFrame + Size.
    - Intended: CFrame (12 f64 = 96 bytes) + Vector3 (3 f64 = 24 bytes) = 120 bytes.
    
    @since v1.0
]]
function BufferComponent.WriteRegion3(self : BufferComponentClass,region3 : Region3)
	assert(typeof(region3) == "Region3","region3 must be a Region3")
	local bytes = 120
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local cframe = region3.CFrame
	local size = region3.Size
	self:WriteCFrame(cframe)
	self:WriteVector3(size)
end

--[[
    Write a Region3int16 as two Vector3int16 (Max then Min).
    - 12 bytes total (2 * 6).
    
    @since v1.0
]]
function BufferComponent.WriteRegion3int16(self : BufferComponentClass,region3int16 : Region3int16)
	assert(typeof(region3int16) == "Region3int16","region3int16 must be a Region3int16")
	local bytes = 12
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local max = region3int16.Max
	local min = region3int16.Min
	self:WriteVector3Int16(max)
	self:WriteVector3Int16(min)
end

--[[
	Write a vector with the 'vector' luau library 
	- 24 bytes total.
	- Relies on WriteVector3 to do the actual writing and offset increments.
	
	@since v1.7
]]
function BufferComponent.WriteVector(self : BufferComponentClass,_vector : vector)
	assert(typeof(_vector) == "Vector3","vector must be a Vector3")
	local bytes = 24
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	self:WriteVector3(_vector)
end

--[[
	Writes an EnumItem to the buffer using a compact 4-byte format.
	
	The enum is stored as:
	- 2 bytes (U16): Enum type ID from the IdsEnums mapping table
	- 2 bytes (U16): Enum item value
	
	@param enumItem: EnumItem - The Roblox EnumItem to serialize
	
	@example:
	Buffer:WriteEnum(Enum.KeyCode.E) -- Stores KeyCode.E in 4 bytes
	Buffer:WriteEnum(Enum.Material.Grass) -- Stores Material.Grass in 4 bytes
	
	@since v1.7
]]
function BufferComponent.WriteEnum(self : BufferComponentClass,enumItem : EnumItem)
	assert(typeof(enumItem) == "EnumItem","enumItem must be an EnumItem")
	local enumType = enumItem.EnumType
	local typeId = IdsEnums[enumType] :: number
	local bytes = 4
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	self:WriteU16(typeId)
	self:WriteU16(enumItem.Value)
end

--[[
	Writes a RotationCurveKey to the buffer with variable size based on interpolation mode.
	
	RotationCurveKeys are used in animation curves to define rotation keyframes.
	The data is stored as:
	- 4 bytes (F32): Time value of the keyframe
	- 96 bytes: CFrame rotation value
	- 4 bytes: Interpolation mode (as Enum)
	- 8 bytes (conditional): Left and Right tangents for Cubic interpolation only
	
	Total size:
	- 104 bytes for Linear/Constant interpolation
	- 112 bytes for Cubic interpolation (includes tangent data)
	
	@param rotationCurveKey: RotationCurveKey - The rotation curve keyframe to serialize
	
	@note:
	- Cubic interpolation requires additional storage for smooth curve tangents
	- The tangent values control the curve's shape between keyframes
	
	@example:
	local key = RotationCurveKey.new(1.5, CFrame.new(), Enum.KeyInterpolationMode.Linear)
	Buffer:WriteRotationCurveKey(key) -- Writes 104 bytes
	
	local cubicKey = RotationCurveKey.new(2.0, CFrame.Angles(0, math.pi, 0), Enum.KeyInterpolationMode.Cubic)
	Buffer:WriteRotationCurveKey(cubicKey) -- Writes 112 bytes with tangents	
	
	@since v1.8
]]
function BufferComponent.WriteRotationCurveKey(self : BufferComponentClass,rotationCurveKey : RotationCurveKey)
	assert(typeof(rotationCurveKey) == "RotationCurveKey","rotationCurveKey must be a RotationCurveKey")
	local bytes = 104
	bytes += (rotationCurveKey.Interpolation == Enum.KeyInterpolationMode.Cubic) and 8 or 0
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	self:WriteF32(rotationCurveKey.Time)
	self:WriteCFrame(rotationCurveKey.Value)
	self:WriteEnum(rotationCurveKey.Interpolation)
	if(bytes >= 112) then
		self:WriteF32(rotationCurveKey.LeftTangent)
		self:WriteF32(rotationCurveKey.RightTangent)
	end
end

--[[
	Writes a FloatCurveKey to the buffer with variable size based on interpolation mode.
	
	FloatCurveKeys are used in animation curves to define floating-point value keyframes.
	The data is stored as:
	- 4 bytes (F32): Time value of the keyframe
	- 8 bytes (F64): Float value at this keyframe (double precision)
	- 4 bytes: Interpolation mode (as Enum)
	- 8 bytes (conditional): Left and Right tangents for Cubic interpolation only
	
	Total size:
	- 16 bytes for Linear/Constant interpolation
	- 24 bytes for Cubic interpolation (includes tangent data)
	
	@param floatCurveKey: FloatCurveKey - The float curve keyframe to serialize
	
	@note:
	- Value is stored as F64 for maximum precision in animation curves
	- Tangents control the curve's acceleration/deceleration for smooth transitions
	
	@example:
	local key = FloatCurveKey.new(0.5, 1.25, Enum.KeyInterpolationMode.Linear)
	Buffer:WriteFloatCurveKey(key) -- Writes 16 bytes
	
	local cubicKey = FloatCurveKey.new(1.0, 2.5, Enum.KeyInterpolationMode.Cubic)
	cubicKey.LeftTangent = 0.5
	cubicKey.RightTangent = 0.5
	Buffer:WriteFloatCurveKey(cubicKey) -- Writes 24 bytes with tangents
	
	@since v1.8
]]
function BufferComponent.WriteFloatCurveKey(self : BufferComponentClass,floatCurveKey : FloatCurveKey)
	assert(typeof(floatCurveKey) == "FloatCurveKey","floatCurveKey must be a FloatCurveKey")
	local bytes = (floatCurveKey.Interpolation == Enum.KeyInterpolationMode.Cubic) and 24 or 16
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	self:WriteF32(floatCurveKey.Time)
	self:WriteF64(floatCurveKey.Value)
	self:WriteEnum(floatCurveKey.Interpolation)
	if(bytes >= 24) then
		self:WriteF32(floatCurveKey.LeftTangent or 0)
		self:WriteF32(floatCurveKey.RightTangent or 0)
	end
end

--[[
	Writes a ColorSequence to the buffer with all its keypoints.
	
	ColorSequences define color gradients over time, commonly used for particles and UI.
	The data is stored as:
	- 1 byte (U8): Number of keypoints (max 255)
	- For each keypoint:
		- 4 bytes (F32): Time value (0.0 to 1.0)
		- 4 bytes (F32): Red channel (0-255 range)
		- 4 bytes (F32): Green channel (0-255 range)
		- 4 bytes (F32): Blue channel (0-255 range)
	
	Total size: 1 + (16 * keypoint_count) bytes
	
	@param colorSeq: ColorSequence - The color sequence to serialize
	
	@limitations:
	- Maximum of 255 keypoints due to U8 count storage
	- Color values are stored without alpha channel
	
	@note:
	- Color values are converted from Roblox's 0-1 range to 0-255 for storage
	- Keypoints are written in their original order
	
	@example:
	local gradient = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),    -- Red at start
		ColorSequenceKeypoint.new(0.5, Color3.new(0, 1, 0)),  -- Green at middle
		ColorSequenceKeypoint.new(1, Color3.new(0, 0, 1))     -- Blue at end
	})
	Buffer:WriteColorSequence(gradient) -- Writes 49 bytes (1 + 3*16)
	
	@since v1.8
]]
function BufferComponent.WriteColorSequence(self : BufferComponentClass,colorSeq : ColorSequence)
	assert(typeof(colorSeq) == "ColorSequence","colorSeq must be a ColorSequence")
	if(#colorSeq.Keypoints <= 0) then
		error("No keypoints in the current ColorSequence.")
	end
	local bytes = (16 * #colorSeq.Keypoints) + 1
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	self:WriteU8(#colorSeq.Keypoints)
	for i = 1,#colorSeq.Keypoints do
		local keypoint = colorSeq.Keypoints[i]
		self:WriteF32(keypoint.Time)
		self:WriteF32(keypoint.Value.R*255)
		self:WriteF32(keypoint.Value.G*255)
		self:WriteF32(keypoint.Value.B*255)
	end
end

--[[
	Writes a NumberRange to the buffer using a compact 8-byte layout.
	
	Binary layout:
	- 4 bytes (F32): Min
	- 4 bytes (F32): Max
	
	@param numberRange: NumberRange - The numeric range to serialize.
	
	@notes:
	- Values are written as provided; no clamping or reordering is performed
	- Uses F32 for both fields to keep the footprint small and consistent
	
	@example:
	Buffer:WriteNumberRange(NumberRange.new(0, 10))
	
	@since v1.8
]]
function BufferComponent.WriteNumberRange(self : BufferComponentClass,numberRange : NumberRange)
	assert(typeof(numberRange) == "NumberRange","numberRange must be a NumberRange")
	local bytes = 8
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	self:WriteF32(numberRange.Min)
	self:WriteF32(numberRange.Max)
end

--[[
	Writes a NumberSequence to the buffer with all its keypoints.
	
	Binary layout:
	- 1 byte (U8): Number of keypoints (N, max 255)
	- For each keypoint (repeated N times):
		- 4 bytes (F32): Time (0.0–1.0)
		- 4 bytes (F32): Value
		- 4 bytes (F32): Envelope
	
	Total size: 1 + (12 * keypoint_count) bytes
	
	@param numberSeq: NumberSequence - The number sequence to serialize.
	
	@limitations:
	- Maximum 255 keypoints due to U8 count storage
	- All fields are stored as 32-bit floats (F32)
	
	@notes:
	- Envelope is written for every keypoint (0 if not used)
	- Keypoints are written in their original order
	
	@example:
	local seq = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.0),
		NumberSequenceKeypoint.new(0.5, 1.0, 0.25),
		NumberSequenceKeypoint.new(1.0, 0.0),
	})
	Buffer:WriteNumberSequence(seq)
	
	@since v1.8
]]
function BufferComponent.WriteNumberSequence(self : BufferComponentClass,numberSeq : NumberSequence)
	assert(typeof(numberSeq) == "NumberSequence","numberSeq must be a NumberSequence")
	if(#numberSeq.Keypoints <= 0) then
		error("No keypoints in the current NumberSequence.")
	end
	local bytes = (12 * #numberSeq.Keypoints) + 1
	local remaining = buffer.len(self.buffer) - self.offset
	local hasValidSpace = remaining >= bytes and bytes <= buffer.len(self.buffer)
	if(not hasValidSpace) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	self:WriteU8(#numberSeq.Keypoints)
	for i = 1,#numberSeq.Keypoints do
		local keypoint = numberSeq.Keypoints[i]
		self:WriteF32(keypoint.Time)
		self:WriteF32(keypoint.Value)
		self:WriteF32(keypoint.Envelope)
	end
end

-->-----------------------READER-----------------------------<--

--[[
  Read a Signed 1-bit integer from the buffer.

  Range: -1 - 1
  
   Returns:
  - number on success
  - nil on failure (warns)
  
  @since v1.4
]]
function BufferComponent.ReadI1(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return buffer.readi8(self.buffer, offset)
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 8-bit integer from the buffer (byte-aligned).
  Returns number in [-128, 127] or nil on failure.
  
  @since v1.0
]]
function BufferComponent.ReadI8(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readi8, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 16-bit integer from the buffer (byte-aligned).
  Endianness is whatever buffer.readi16 uses in your environment.
  Returns number in [-32768, 32767] or nil on failure.
  
  @since v1.0
]]
function BufferComponent.ReadI16(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readi16, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 24-bit integer (big-endian) from the buffer.

  Returns:
  - number in [-2^23, 2^23-1] on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadI24(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local value = bit32.bor(
			bit32.lshift(b1, 16),
			bit32.lshift(b2, 8),
			b3
		)
		if b1 >= 0x80 then -- sign bit set (2^7 in the MSB)
			value = value - 0x1000000 -- subtract 2^24
		end
		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 32-bit integer from the buffer.
  Returns number in [-2^31, 2^31-1] or nil on failure.
  
  @since v1.0
]]
function BufferComponent.ReadI32(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readi32, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 40-bit integer (big-endian) from the buffer.

  Range:
  - -2^39 .. 2^39-1

  Returns:
  - number on success (exactly representable in double for 40-bit)
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadI40(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local b4 = buffer.readu8(self.buffer, offset + 3)
		local b5 = buffer.readu8(self.buffer, offset + 4)
		local value =
			b1 * 0x100000000 + -- 2^32
			b2 * 0x1000000   + -- 2^24
			b3 * 0x10000     + -- 2^16
			b4 * 0x100       + -- 2^8
			b5                -- 2^0
		if value >= 0x8000000000 then  -- 2^39
			value = value - 0x10000000000 -- 2^40
		end
		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end

--[[
  Read a Signed 48-bit integer (big-endian) from the buffer.

  Range:
    -2^47 .. 2^47-1  (i.e., -140737488355328 .. 140737488355327)

  Returns:
  - number on success (exactly representable in double for 48-bit)
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadI48(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local b4 = buffer.readu8(self.buffer, offset + 3)
		local b5 = buffer.readu8(self.buffer, offset + 4)
		local b6 = buffer.readu8(self.buffer, offset + 5)
		local value =
			b1 * 0x10000000000 + -- 2^40
			b2 * 0x100000000   + -- 2^32
			b3 * 0x1000000     + -- 2^24
			b4 * 0x10000       + -- 2^16
			b5 * 0x100         + -- 2^8
			b6                  -- 2^0
		-- Two's complement sign fix: if value >= 2^47, subtract 2^48
		if value >= 0x800000000000 then
			value = value - 0x1000000000000
		end
		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 54-bit integer (big-endian) from the buffer.

  Range:
  -2^53 .. 2^53-1

  Returns:
  - number on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadI54(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local byte7 = buffer.readu8(self.buffer, offset + 0)
		local byte6 = buffer.readu8(self.buffer, offset + 1)
		local byte5 = buffer.readu8(self.buffer, offset + 2)
		local byte4 = buffer.readu8(self.buffer, offset + 3)
		local byte3 = buffer.readu8(self.buffer, offset + 4)
		local byte2 = buffer.readu8(self.buffer, offset + 5)
		local byte1 = buffer.readu8(self.buffer, offset + 6)
		-- Mask to 54 bits: keep only lower 6 bits of the MSB
		local msb54 = bit32.band(byte7, 0x3F)
		local value =
			msb54 * 0x1000000000000 + -- 2^48 (with only 6 bits in msb54, total width = 54 bits)
			byte6 * 0x10000000000   + -- 2^40
			byte5 * 0x100000000     + -- 2^32
			byte4 * 0x1000000       + -- 2^24
			byte3 * 0x10000         + -- 2^16
			byte2 * 0x100           + -- 2^8
			byte1                    -- 2^0

		-- Two's complement sign fix for 54-bit:
		-- If value >= 2^53, subtract 2^54
		if value >= 0x20000000000000 then
			value = value - 0x40000000000000
		end

		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read 1 unsigned bit from the buffer.

  Returns:
  - 0 or 1 on success
  - nil on failure (warns)
  
  @since v1.3
]]
function BufferComponent.ReadU1(self : BufferComponentClass, offset : number) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local bitOffset = offset * 8
	local success, valueORoutOfBounds = pcall(buffer.readbits, self.buffer, bitOffset, 1)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 8-bit integer (byte) from the buffer.
  Returns number in [0, 255] or nil on failure.
  
  @since v1.0
]]
function BufferComponent.ReadU8(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readu8, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 16-bit integer (big-endian) from the buffer.
  Returns number in [0, 65535] or nil on failure.
  
  @since v1.0
]]
function BufferComponent.ReadU16(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readu16, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 24-bit integer (big-endian) from the buffer.

  Returns:
  - number on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadU24(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset

	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local value = bit32.bor(bit32.lshift(b1, 16), bit32.lshift(b2, 8), b3)
		return value
	end)

	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 32-bit integer from the buffer.
  Returns number in [0, 2^32-1] (may lose precision above 2^24 in double, but Roblox API provides u32).
  
  @since v1.0
]]
function BufferComponent.ReadU32(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readu32, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 40-bit integer (big-endian) from the buffer.

  Returns:
  - number on success (exact for 40-bit in double)
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadU40(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset

	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local b4 = buffer.readu8(self.buffer, offset + 3)
		local b5 = buffer.readu8(self.buffer, offset + 4)

		local value =
			b1 * 0x100000000 + -- 2^32
			b2 * 0x1000000   + -- 2^24
			b3 * 0x10000     + -- 2^16
			b4 * 0x100       + -- 2^8
			b5                -- 2^0
		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end

--[[
  Read an Unsigned 48-bit integer from the buffer (6 bytes, big-endian by default).

  Returns:
  - number in [0, 2^48 - 1] on success (exactly representable in double)
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadU48(self : BufferComponentClass,offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local b4 = buffer.readu8(self.buffer, offset + 3)
		local b5 = buffer.readu8(self.buffer, offset + 4)
		local b6 = buffer.readu8(self.buffer, offset + 5)
		-- 0x10000000000 = 2^40,
		-- 0x100000000 = 2^32,
		-- 0x100 = 2^8
		local value =
			b1 * 0x10000000000 + -- 2^40
			b2 * 0x100000000   + -- 2^32
			b3 * 0x1000000     + -- 2^24
			b4 * 0x10000       + -- 2^16
			b5 * 0x100         + -- 2^8
			b6                  -- 2^0
		return value
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 54-bit integer from the buffer.

  Returns:
  - number on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadU54(self : BufferComponentClass,offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local byte7 = buffer.readu8(self.buffer, offset + 0)
		local byte6 = buffer.readu8(self.buffer, offset + 1)
		local byte5 = buffer.readu8(self.buffer, offset + 2)
		local byte4 = buffer.readu8(self.buffer, offset + 3)
		local byte3 = buffer.readu8(self.buffer, offset + 4)
		local byte2 = buffer.readu8(self.buffer, offset + 5)
		local byte1 = buffer.readu8(self.buffer, offset + 6)
		-- 0x1000000000000 = 2^48, 0x10000000000 = 2^40, ..., 0x100 = 2^8
		local value =
			byte7 * 0x1000000000000 + -- 2^48
			byte6 * 0x10000000000   + -- 2^40
			byte5 * 0x100000000     + -- 2^32
			byte4 * 0x1000000       + -- 2^24
			byte3 * 0x10000         + -- 2^16
			byte2 * 0x100           + -- 2^8
			byte1                    -- 2^0
		return value
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a String from the buffer.

  Parameters:
  - len: number of bytes to read. If omitted, defaults to Constants.MIN_STRING.
  - offset (optional): byte offset to read from. If omitted/invalid, falls back to self.offset.

  Returns:
  - string on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadString(self : BufferComponentClass,len : number,offset : number?) : string | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	len = math.clamp(len,Constants.MIN_STRING,math.huge)
	local success, valueORoutOfBounds = pcall(buffer.readstring, self.buffer, offset, len)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a 1-bit boolean from the buffer at a given bit offset.

  Returns:
  - boolean on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadBool1(self : BufferComponentClass,offset : number?) : boolean | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local bitOffset = (offset * 8 >= 0) and offset * 8 or 0
	local success, valueORoutOfBounds = pcall(function()
		return (buffer.readbits(self.buffer, bitOffset, 1) == 1) and true or false
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read 8 booleans (1 bit each) starting at a given bit offset.

  Returns:
  - A table:
      {
        value = {bool, bool, ..., bool}, -- the 8 bits in order
        majority = function(): boolean   -- true if more trues than falses
      }
      
      
  @since v1.0
]]
function BufferComponent.ReadBool8(self : BufferComponentClass,offset : number?) : Readbool8ReturnType | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local booleans = {}
		for i = 0, 7 do
			-- Each read advances 1 bit from the starting bit offset.
			local boolean_bits : boolean = (buffer.readbits(self.buffer, offset * 8 + i, 1) == 1) and true or false
			table.insert(booleans, boolean_bits)
		end
		return {
			value = booleans,
			majority = function() : boolean
				local teamTrue = 0
				local teamFalse = 0
				for _, bool in next, booleans do
					if bool == true then
						teamTrue += 1
					else
						teamFalse += 1
					end
				end
				return (teamTrue > teamFalse) and true or false
			end,
		}
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a 16-bit half-precision float (IEEE 754 binary16) from the buffer.

  Encoding:
  - 1 sign bit, 5 exponent bits (bias 15), 10 mantissa bits.

  Returns:
  - number on success (double-precision representation of the half)
  - nil on failure (warns)

  Notes on special cases:
  - Exponent == 0 and mantissa == 0 => +/- 0
  - Exponent == 0 and mantissa != 0 => denormalized number
  - Exponent == 31 (all ones):
      * mantissa == 0 => +/- infinity
      * mantissa != 0 => NaN
      
      
  @since v1.0
]]
function BufferComponent.ReadF16(self : BufferComponentClass,offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		-- Read the 16-bit word
		local uint16 = buffer.readu16(self.buffer, offset)
		-- Extract sign (1 bit), exponent (5 bits), mantissa (10 bits)
		local sign = bit32.rshift(uint16, 15)
		local exponent = bit32.band(bit32.rshift(uint16, 10), 0x1F)
		local mantissa = bit32.band(uint16, 0x3FF)
		-- Special cases
		if exponent == 0 then
			if mantissa == 0 then
				-- +/- 0
				return sign == 0 and 0 or -0
			else
				-- Denormalized number
				local value = (mantissa / 1024) * (2 ^ -14)
				return sign == 0 and value or -value
			end
		elseif exponent == 31 then
			if mantissa == 0 then
				-- +/- infinity
				return sign == 0 and math.huge or -math.huge
			else
				-- NaN
				return 0/0
			end
		end
		-- Normalized number
		local value = (1 + mantissa / 1024) * (2 ^ (exponent - 15))
		return sign == 0 and value or -value
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end

--[[
  Read a Float32 from the buffer at the given offset (or self.offset if not provided/valid).

  Returns:
  - number on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadF32(self : BufferComponentClass,offset : number?) : number | nil
	-- Choose the effective offset. Uses the provided "offset" only if it's <= self.offset.
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	-- Wrap in pcall: buffer.readf32 will throw on out-of-bounds or invalid use.
	local success, valueORoutOfBounds = pcall(buffer.readf32, self.buffer, offset)
	if (not success and valueORoutOfBounds) then
		-- Try to show a human-friendly message if available in Debug
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		-- On success, the second return value is the f32 read
		return valueORoutOfBounds
	end
end


--[[
  Read a Float64 from the buffer at the given offset (or self.offset if not provided/valid).

  Returns:
  - number on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadF64(self : BufferComponentClass,offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readf64, self.buffer, offset)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Instance from self.instance_buffer at the given index (or self.instance_offset).

  Returns:
  - Instance or nil
  
  @since v1.0
]]
function BufferComponent.ReadInstance(self : BufferComponentClass,instance_offset : number?) : Instance | nil
	local instance_offset = (type(instance_offset) == "number" and instance_offset <= self.instance_offset) and instance_offset or self.instance_offset
	return self.instance_buffer[instance_offset]
end


--[[
  Read a Vector2 (double-precision) from the buffer:
  - X at [offset + 0], Y at [offset + 8], both f64.

  Returns:
  - Vector2 on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadVector2(self : BufferComponentClass,offset : number?) : Vector2 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return Vector2.new(
			buffer.readf64(self.buffer, offset),
			buffer.readf64(self.buffer, offset + 8)
		)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Vector2int16 from the buffer:
  - X at [offset + 0], Y at [offset + 2], both i16.

  Returns:
  - Vector2int16 on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadVector2int16(self : BufferComponentClass,offset : number?) : Vector2int16 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return Vector2int16.new(
			buffer.readi16(self.buffer, offset),
			buffer.readi16(self.buffer, offset + 2)
		)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Vector3 (double-precision) from the buffer:
  - X at [offset + 0], Y at [offset + 8], Z at [offset + 16], all f64.

  Returns:
  - Vector3 on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadVector3(self : BufferComponentClass,offset : number?) : Vector3 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return Vector3.new(
			buffer.readf64(self.buffer, offset),
			buffer.readf64(self.buffer, offset + 8),
			buffer.readf64(self.buffer, offset + 16)
		)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Vector3int16 from the buffer:
  - X at [offset + 0], Y at [offset + 2], Z at [offset + 4], all i16.

  Returns:
  - Vector3int16 on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadVector3int16(self : BufferComponentClass,offset : number?) : Vector3int16 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return Vector3int16.new(
			buffer.readi16(self.buffer, offset),
			buffer.readi16(self.buffer, offset + 2),
			buffer.readi16(self.buffer, offset + 4)
		)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a CFrame (double-precision) from the buffer:
  - Reads 12 f64s at [offset + i*8], i ∈ [0..11].
  - Constructs CFrame.new(...) from these 12 components.

  Returns:
  - CFrame on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadCFrame(self : BufferComponentClass,offset : number?) : CFrame | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local components = {}
		for i = 0, 11 do
			components[i + 1] = buffer.readf64(self.buffer, offset + (i * 8))
		end
		return CFrame.new(table.unpack(components))
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a "Lossy" CFrame (single-precision) from the buffer:
  - Reads 12 f32s at [offset + i*4], i ∈ [0..11].
  - Lower precision than ReadCFrame; saves space.

  Returns:
  - CFrame on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadLossyCFrame(self : BufferComponentClass,offset : number?) : CFrame | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local components = {}
		for i = 0, 11 do
			components[i + 1] = buffer.readf32(self.buffer, offset + (i * 4))
		end
		return CFrame.new(table.unpack(components))
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a UDim from the buffer:
  - scale (f32) then offset (f32 here) => UDim.new(scale, offset)

  Returns:
  - UDim on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadUDim(self : BufferComponentClass,offset : number?) : UDim | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local scale = buffer.readf32(self.buffer,offset)
		local Udim_offset = buffer.readi32(self.buffer,offset + 4)
		return UDim.new(scale, Udim_offset)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a UDim2 from the buffer:
  - scaleX (f32), scaleY (f32), offsetX (i32), offsetY (i32) in that order.
  - Returns UDim2.new(scaleX, offsetX, scaleY, offsetY)

  Returns:
  - UDim2 on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadUDim2(self : BufferComponentClass,offset : number?) : UDim2 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local scaleX, scaleY = buffer.readf32(self.buffer, offset), buffer.readf32(self.buffer, offset + 4)
		local offsetX, offsetY = buffer.readi32(self.buffer, offset + 8), buffer.readi32(self.buffer, offset + 12)
		return UDim2.new(scaleX, offsetX, scaleY, offsetY)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Color3 from the buffer:
  - r, g, b as f32s in [0, 1] (assumed), then scaled to [0, 255] for Color3.fromRGB.

  Returns:
  - Color3 on success
  - nil on failure (warns)
  
  @since v1.0
]]
function BufferComponent.ReadColor3(self : BufferComponentClass,offset : number?) : Color3 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local r = buffer.readf32(self.buffer, offset) * 255
		local g = buffer.readf32(self.buffer, offset + 4) * 255
		local b = buffer.readf32(self.buffer, offset + 8) * 255
		return Color3.fromRGB(r, g, b)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Rect from the buffer:
  - Two Vector2 (double-precision) values back-to-back: typically min then max (or vice versa).
  - This implementation reads:
      max = ReadVector2(offset)
      min = ReadVector2(offset + 16)
    and returns Rect.new(min, max).

  Returns:
  - Rect on success
  - nil on failure (if nested reads fail)
  
  @since v1.0
]]
function BufferComponent.ReadRect(self : BufferComponentClass,offset : number?) : Rect | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local max = self:ReadVector2(offset)
	local min = self:ReadVector2(offset + 16)
	return Rect.new(min, max)
end


--[[
  Read a Region3 from the buffer:
  - Interprets data as: CFrame (f64 x12, 96 bytes) followed by a Vector3 size (f64 x3, 24 bytes).
  - Constructs an AABB-aligned Region3 centered at cframe.Position with extents 'size'.

  Returns:
  - Region3 on success
  - nil on failure (if nested reads fail)
  
  @since v1.0
]]
function BufferComponent.ReadRegion3(self : BufferComponentClass,offset : number?) : Region3 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local cframe = self:ReadCFrame(offset)
	local size = self:ReadVector3(offset + 96)
	local halfSize = size * 0.5
	local min = cframe.Position - halfSize
	local max = cframe.Position + halfSize
	return Region3.new(min, max)
end


--[[
  Read a Region3int16 from the buffer:
  - Two Vector3int16 in sequence: min then max (or vice versa).
  - This implementation reads:
      max = ReadVector3int16(offset)
      min = ReadVector3int16(offset + 6)
    and returns Region3int16.new(min, max).

  Returns:
  - Region3int16 on success
  - nil on failure (if nested reads fail)
  
  @since v1.0
]]
function BufferComponent.ReadRegion3int16(self : BufferComponentClass,offset : number?) : Region3int16 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local max = self:ReadVector3int16(offset)
	local min = self:ReadVector3int16(offset + 6)
	return Region3int16.new(min, max)
end

--[[
	Read a 'vector' from <strong>the luau library</strong> at the given offset
	
	Returns:
	- vector on success
	- nil on failure (if nested reads fail)
	
	@since v1.7
]]
function BufferComponent.ReadVector(self : BufferComponentClass,offset : number?) : vector | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return vector.create(
			buffer.readf64(self.buffer, offset),
			buffer.readf64(self.buffer, offset + 8),
			buffer.readf64(self.buffer, offset + 16)
		)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end

--[[
	Reads an EnumItem from the buffer that was previously written with WriteEnum.
	
	Reconstructs the EnumItem from its compact 4-byte representation:
	- 2 bytes (U16): Enum type ID
	- 2 bytes (U16): Enum item value
	
	@param offset: number? - Optional byte offset to read from. If not provided or invalid, 
	                         uses the current buffer offset
	
	@returns: EnumItem | nil - The deserialized EnumItem, or nil if read fails
	
	@example:
	local keyCode = Buffer:ReadEnum() -- Read from current position
	local material = Buffer:ReadEnum(16) -- Read from specific offset
	
	@since v1.7
]]
function BufferComponent.ReadEnum(self : BufferComponentClass,offset : number?) : EnumItem | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success,valueORoutOfBounds = pcall(function()
		local typeId = self:ReadU16(offset)
		local value = self:ReadU16(offset + 2)
		local enum = EnumsIds[typeId] :: Enum
		return enum:FromValue(value)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end

--[[
	Reads a RotationCurveKey from the buffer that was previously written with WriteRotationCurveKey.
	
	Reconstructs the RotationCurveKey from its serialized format:
	- 4 bytes (F32): Time value of the keyframe
	- 96 bytes: CFrame rotation value  
	- 4 bytes: Interpolation mode (as Enum)
	- 8 bytes (conditional): Left and Right tangents if Cubic interpolation
	
	@param offset: number? - Optional byte offset to read from. If not provided or invalid,
	                         uses the current buffer offset
	
	@returns: RotationCurveKey | nil - The deserialized RotationCurveKey, or nil if read fails
	
	@note:
	- Automatically handles variable size based on interpolation mode
	- Cubic keys will have their tangent properties set after creation
	
	@example:
	local key = Buffer:ReadRotationCurveKey() -- Read from current position
	local key2 = Buffer:ReadRotationCurveKey(256) -- Read from specific offset
	
	if key.Interpolation == Enum.KeyInterpolationMode.Cubic then
		print(key.LeftTangent, key.RightTangent) -- Will have tangent values
	end
	
	@since v1.8
]]
function BufferComponent.ReadRotationCurveKey(self : BufferComponentClass,offset : number?) : RotationCurveKey | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local t = self:ReadF32(offset)
	local value = self:ReadCFrame(offset+4)
	local enum = self:ReadEnum(offset+100)
	local left,right
	local rotationCurveKey = RotationCurveKey.new(t,value,enum)
	if(rotationCurveKey.Interpolation == Enum.KeyInterpolationMode.Cubic) then
		left = self:ReadF32(offset+104)
		right = self:ReadF32(offset+108)
		rotationCurveKey.LeftTangent = left
		rotationCurveKey.RightTangent = right
	end
	return rotationCurveKey
end

--[[
	Reads a FloatCurveKey from the buffer that was previously written with WriteFloatCurveKey.
	
	Reconstructs the FloatCurveKey from its serialized format:
	- 4 bytes (F32): Time value of the keyframe
	- 8 bytes (F64): Float value at this keyframe (double precision)
	- 4 bytes: Interpolation mode (as Enum)
	- 8 bytes (conditional): Left and Right tangents if Cubic interpolation
	
	@param offset: number? - Optional byte offset to read from. If not provided or invalid,
	                         uses the current buffer offset
	
	@returns: FloatCurveKey | nil - The deserialized FloatCurveKey, or nil if read fails
	
	@note:
	- Value is read as F64 to preserve animation curve precision
	- Automatically detects and handles Cubic interpolation tangents
	
	@example:
	local key = Buffer:ReadFloatCurveKey() -- Read from current position
	local key2 = Buffer:ReadFloatCurveKey(128) -- Read from specific offset
	
	print(key.Time, key.Value) -- Basic properties always present
	if key.Interpolation == Enum.KeyInterpolationMode.Cubic then
		print(key.LeftTangent, key.RightTangent) -- Tangent values for Cubic
	end
	
	@since v1.8
]]
function BufferComponent.ReadFloatCurveKey(self : BufferComponentClass,offset : number?) : FloatCurveKey | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local t = self:ReadF32(offset)
	local value = self:ReadF64(offset+4)
	local enum = self:ReadEnum(offset+12)
	local left,right
	local floatCurveKey = FloatCurveKey.new(t,value,enum)
	if(floatCurveKey.Interpolation == Enum.KeyInterpolationMode.Cubic) then
		left = self:ReadF32(offset+16)
		right = self:ReadF32(offset+20)
		floatCurveKey.LeftTangent = left
		floatCurveKey.RightTangent = right
	end
	return floatCurveKey
end

--[[
	Reads a ColorSequence from the buffer that was previously written with WriteColorSequence.
	
	Binary layout (matches WriteColorSequence):
	- 1 byte (U8): Number of keypoints (N, max 255)
	- For each keypoint (repeated N times):
		- 4 bytes (F32): Time (0.0–1.0)
		- 4 bytes (F32): Red   in 0–255 range
		- 4 bytes (F32): Green in 0–255 range
		- 4 bytes (F32): Blue  in 0–255 range
	
	Offsets relative to the provided offset:
	- offset + 0: keypoint count (U8)
	- offset + 1 + 16*(i-1): Time
	- offset + 5 + 16*(i-1): R
	- offset + 9 + 16*(i-1): G
	- offset + 13 + 16*(i-1): B
	
	@param offset: number? - Optional byte offset to read from. If not provided or invalid,
	                         uses the current buffer offset (self.offset).
	
	@returns: ColorSequence | nil - The reconstructed ColorSequence.
	
	@limitations:
	- Maximum 255 keypoints due to U8 count storage.
	
	@example:
	local seq = Buffer:ReadColorSequence()         -- from current offset
	local seq2 = Buffer:ReadColorSequence(1024)    -- from a specific offset
	
	@since v1.8
]]
function BufferComponent.ReadColorSequence(self : BufferComponentClass,offset : number?) : ColorSequence | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local tblLen = self:ReadU8(offset)
	local sequence = {}
	offset += 1
	for i = 1,tblLen do
		local t = self:ReadF32(offset)
		local r = self:ReadF32(offset+4)
		local g = self:ReadF32(offset+8)
		local b = self:ReadF32(offset+12)
		local point = ColorSequenceKeypoint.new(t,Color3.fromRGB(r,g,b))
		sequence[i] = point
		offset += 16
	end
	return ColorSequence.new(sequence)
end

--[[
	Reads a NumberRange from the buffer that was previously written with WriteNumberRange.
	
	Binary layout (8 bytes total):
	- 4 bytes (F32): Min
	- 4 bytes (F32): Max
	
	@param offset: number? - Optional byte offset to read from. If not provided or invalid
	                         (greater than current write offset), uses self.offset.
	
	@returns: NumberRange | nil - The reconstructed NumberRange.
	          Note: This function does not use pcall; it will throw on out-of-bounds reads.
	
	@example:
	local range = Buffer:ReadNumberRange()       -- from current offset
	local range2 = Buffer:ReadNumberRange(256)   -- from a specific offset
	
	@since v1.8
]]
function BufferComponent.ReadNumberRange(self : BufferComponentClass,offset : number?) : NumberRange | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local min = self:ReadF32(offset)
	local max = self:ReadF32(offset+4)
	return NumberRange.new(min,max)
end

--[[
	Reads a NumberSequence from the buffer that was previously written with WriteNumberSequence.
	
	Binary layout:
	- 1 byte (U8): Number of keypoints (N, max 255)
	- For each keypoint (repeated N times):
		- 4 bytes (F32): Time (0.0–1.0)
		- 4 bytes (F32): Value
		- 4 bytes (F32): Envelope
	
	@param offset: number? - Optional byte offset to read from. If not provided or invalid
	                         (greater than current write offset), uses self.offset.
	
	@returns: NumberSequence | nil - The reconstructed NumberSequence.
	          Note: This function does not use pcall; it will throw on out-of-bounds reads.
	
	
	@limitations:
	- Maximum of 255 keypoints due to U8 count storage.
	
	@example:
	local seq = Buffer:ReadNumberSequence()        -- from current offset
	local seq2 = Buffer:ReadNumberSequence(2048)   -- from a specific offset
	
	@since v1.8
]]
function BufferComponent.ReadNumberSequence(self : BufferComponentClass,offset : number?) : NumberSequence | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local tblLen = self:ReadU8(offset)
	local sequence = {}
	offset += 1
	for i = 1,tblLen do
		local t = self:ReadF32(offset)
		local v = self:ReadF32(offset+4)
		local e = self:ReadF32(offset+8)
		local point = NumberSequenceKeypoint.new(t,v,e)
		sequence[i] = point
		offset += 12
	end
	return NumberSequence.new(sequence)
end

-->-----------------------Cursor/Buffer/Signals-----------------------------<--

--[[
	Connects a callback to the OffsetChanged signal.
	The callback is called when the offset is changed.
	
	@since v2.6
]]
function BufferComponent.OnOffsetChanged(self : BufferComponentClass,
	callback : (oldOffset : number,newOffset : number) -> ()) : Zignal.Connection<number,number>
	return self.OffsetChanged:Connect(callback)
end

--[[
	Connects a callback to the InstanceOffsetChanged signal.
	The callback is called when the instance offset is changed.
	
	@since v2.6
]]
function BufferComponent.OnInstanceOffsetChanged(self : BufferComponentClass,
	callback : (oldOffset : number,newOffset : number) -> ()) : Zignal.Connection<number,number>
	return self.InstanceOffsetChanged:Connect(callback)
end

--[[
	Connects a callback to the CapacityChanged signal.
	The callback is called when the capacity is changed.
	
	@Note
	- __mult can fire CapacityChanged same for __add
	- :allocate can fire CapacityChanged
	
	@since v2.6
]]
function BufferComponent.OnCapacityChanged(self : BufferComponentClass,
	callback : (oldSize : number,newSize : number) -> ()) : Zignal.Connection<number,number>
	return self.CapacityChanged:Connect(callback)
end

--[[
	Return a compressed buffer with the target Compression Algorithm
	
	Note:
	- This function use <code>EncodingService:CompressBuffer()</code>. Please see the Roblox API for more infos
	
	@since v2.6
]]
function BufferComponent.Compress(self : BufferComponentClass,algorithm : Enum.CompressionAlgorithm) : buffer
	return EncodingService:CompressBuffer(self.buffer,algorithm)
end

--[[
	return the actual remaining space of the current buffer
	
	@since v1.7
]]

function BufferComponent.GetRemainingSpace(self : BufferComponentClass) : number
	return buffer.len(self.buffer) - self.offset
end

--[[
	return the actual offset of the buffer
	
	@since v1.2
]]
function BufferComponent.GetOffset(self : BufferComponentClass) : number
	return self.offset
end

--[[
	return the actual instance offset of the buffer
	
	@since v1.2
]]
function BufferComponent.GetInstanceOffset(self : BufferComponentClass) : number
	return self.instance_offset
end

--[[
	return the current buffer
	
	@since v1.2
]]
function BufferComponent.GetBuffer(self : BufferComponentClass) : buffer
	return self.buffer
end

--[[
	return the current instance buffer
	
	@since v1.2
]]
function BufferComponent.GetInstanceBuffer(self : BufferComponentClass) : {Instance?}
	return self.instance_buffer
end

--[[
	return the actual buffer size (not the written data size)
	
	@since v1.2
]]
function BufferComponent.GetBufferSize(self : BufferComponentClass) : number
	return buffer.len(self.buffer)
end

--[[
	clear the instance_buffer and the buffer itself
	both offset will be set to 0.
	
	@return self -- allow you to chain method
	
	@since v2.4
]]
function BufferComponent.clear(self : BufferComponentClass) : BufferComponentClass
	self:clearInstances()
	return self:clearBuffer()
end

--[[
	Clear the instance_buffer.
	instance_offset will be set to 0.
	
	@return self -- allow you to chain method
	
	@since v2.4
]]
function BufferComponent.clearInstances(self : BufferComponentClass) : BufferComponentClass
	table.clear(self.instance_buffer)
	self.instance_offset = 0
	return self
end

--[[
	Clear the buffer.
	The buffer offset will be set to 0.
	
	@return self -- allow you to chain method
	
	@since v2.4
]]
function BufferComponent.clearBuffer(self : BufferComponentClass) : BufferComponentClass
	local buffer_blank = buffer.create(buffer.len(self.buffer))
	self.buffer = buffer_blank
	self.offset = 0
	return self
end

--[[
	Create and return a copy of the current BufferComponent
	
	@since v2.5
]]
function BufferComponent.copy(self : BufferComponentClass) : BufferComponentClass
	local copy = BufferConstructor.create(buffer.len(self.buffer))
	copy.instance_buffer = self.instance_buffer
	copy.instance_offset = self.instance_offset
	copy.buffer = self.buffer
	copy.offset = self.offset
	return copy
end

--[[
	Disconnect all signals
	
	@since v2.6
]]
function BufferComponent.DisconnectAllSignals(self : BufferComponentClass) : ()
	self.CapacityChanged:DisconnectAll()
	self.OffsetChanged:DisconnectAll()
	self.InstanceOffsetChanged:DisconnectAll()
end

--[[
	Destroy the actual BufferComponent.
	You can't use the BufferComponent after this.
	
	@since v1.2
]]
function BufferComponent.Destroy(self : BufferComponentClass) : ()
	self.buffer = nil :: any
	self.instance_buffer = nil :: any
	self.instance_offset = nil :: any
	self.offset = nil :: any
	table.clear(self :: any)
	self = nil :: any
end

--@since v1.3
--Constructor alias
BufferConstructor.new = BufferConstructor.create
BufferConstructor.New = BufferConstructor.create
BufferConstructor.From = BufferConstructor.from
BufferConstructor.FromString = BufferConstructor.fromString
BufferConstructor.Tostring = BufferConstructor.tostring
BufferConstructor.serialize = BufferConstructor.Serialize
BufferConstructor.deserialize = BufferConstructor.Deserialize
BufferConstructor.deserializeAll = BufferConstructor.DeserializeAll
BufferConstructor.serializeAll = BufferConstructor.SerializeAll
BufferConstructor.decompress = BufferConstructor.Decompress
BufferConstructor.serializeCompressed = BufferConstructor.SerializeCompressed
BufferConstructor.deserializeCompressed = BufferConstructor.DeserializeCompressed
BufferConstructor.serializeAllCompressed = BufferConstructor.SerializeAllCompressed
BufferConstructor.deserializeAllCompressed = BufferConstructor.DeserializeAllCompressed

--Component alias
BufferComponent.Allocate = BufferComponent.allocate

--[Writer] signed interger alias
BufferComponent.writeI1 = BufferComponent.WriteI1
BufferComponent.writei1 = BufferComponent.WriteI1
BufferComponent.writeI8 = BufferComponent.WriteI8
BufferComponent.writei8 = BufferComponent.WriteI8
BufferComponent.writeI16 = BufferComponent.WriteI16
BufferComponent.writei16 = BufferComponent.WriteI16
BufferComponent.writeI24 = BufferComponent.WriteI24
BufferComponent.writei24 = BufferComponent.WriteI24
BufferComponent.writeI32 = BufferComponent.WriteI32
BufferComponent.writei32 = BufferComponent.WriteI32
BufferComponent.writeI40 = BufferComponent.WriteI40
BufferComponent.writei40 = BufferComponent.WriteI40
BufferComponent.writeI48 = BufferComponent.WriteI48
BufferComponent.writei48 = BufferComponent.WriteI48
BufferComponent.writeI54 = BufferComponent.WriteI54
BufferComponent.writei54 = BufferComponent.WriteI54

--[Writer] unsigned interger alias
BufferComponent.writeU1 = BufferComponent.WriteU1
BufferComponent.writeu1 = BufferComponent.WriteU1
BufferComponent.writeU8 = BufferComponent.WriteU8
BufferComponent.writeu8 = BufferComponent.WriteU8
BufferComponent.writeU16 = BufferComponent.WriteU16
BufferComponent.writeu16 = BufferComponent.WriteU16
BufferComponent.writeU24 = BufferComponent.WriteU24
BufferComponent.writeu24 = BufferComponent.WriteU24
BufferComponent.writeU32 = BufferComponent.WriteU32
BufferComponent.writeu32 = BufferComponent.WriteU32
BufferComponent.writeU40 = BufferComponent.WriteU40
BufferComponent.writeu40 = BufferComponent.WriteU40
BufferComponent.writeU48 = BufferComponent.WriteU48
BufferComponent.writeu48 = BufferComponent.WriteU48
BufferComponent.writeU54 = BufferComponent.WriteU54
BufferComponent.writeu54 = BufferComponent.WriteU54

--[Writer] float interger alias
BufferComponent.writeF16 = BufferComponent.WriteF16
BufferComponent.writef16 = BufferComponent.WriteF16
BufferComponent.writeF32 = BufferComponent.WriteF32
BufferComponent.writef32 = BufferComponent.WriteF32
BufferComponent.writeF64 = BufferComponent.WriteF64
BufferComponent.writef64 = BufferComponent.WriteF64

--[Writer] string alias
BufferComponent.writeString8 = BufferComponent.WriteString8
BufferComponent.writestring8 = BufferComponent.WriteString8
BufferComponent.writeString16 = BufferComponent.WriteString16
BufferComponent.writestring16 = BufferComponent.WriteString16
BufferComponent.writeString32 = BufferComponent.WriteString32
BufferComponent.writestring32 = BufferComponent.WriteString32
BufferComponent.writeString64 = BufferComponent.WriteString64
BufferComponent.writestring64 = BufferComponent.WriteString64
BufferComponent.writeString = BufferComponent.WriteString
BufferComponent.writestring = BufferComponent.WriteString

--[Writer] boolean alias
BufferComponent.writeBool1 = BufferComponent.WriteBool1
BufferComponent.writebool1 = BufferComponent.WriteBool1
BufferComponent.writeBool8 = BufferComponent.WriteBool8
BufferComponent.writebool8 = BufferComponent.WriteBool8


--[Writer] instance alias
BufferComponent.writeInstance = BufferComponent.WriteInstance
BufferComponent.writeinstance = BufferComponent.WriteInstance

--[Writer] roblox type alias
BufferComponent.writeVector2 = BufferComponent.WriteVector2
BufferComponent.writevector2 = BufferComponent.WriteVector2
BufferComponent.writeVector2int16 = BufferComponent.WriteVector2Int16
BufferComponent.writevector2int16 = BufferComponent.WriteVector2Int16
BufferComponent.writeVector3 = BufferComponent.WriteVector3
BufferComponent.writevector3 = BufferComponent.WriteVector3
BufferComponent.writeVector3int16 = BufferComponent.WriteVector3Int16
BufferComponent.writevector3int16 = BufferComponent.WriteVector3Int16
BufferComponent.writeCFrame = BufferComponent.WriteCFrame
BufferComponent.writecframe = BufferComponent.WriteCFrame
BufferComponent.writeLossyCFrame = BufferComponent.WriteLossyCFrame
BufferComponent.writelossyCFrame = BufferComponent.WriteLossyCFrame
BufferComponent.writeUdim = BufferComponent.WriteUDim
BufferComponent.writeudim = BufferComponent.WriteUDim
BufferComponent.WriteUdim = BufferComponent.WriteUDim
BufferComponent.writeUdim2 = BufferComponent.WriteUDim2
BufferComponent.writeudim2 = BufferComponent.WriteUDim2
BufferComponent.WriteUdim2 = BufferComponent.WriteUDim2
BufferComponent.writeColor3 = BufferComponent.WriteColor3
BufferComponent.writecolor3 = BufferComponent.WriteColor3
BufferComponent.writeRect = BufferComponent.WriteRect
BufferComponent.writerect = BufferComponent.WriteRect
BufferComponent.writeRegion3 = BufferComponent.WriteRegion3
BufferComponent.writeregion3 = BufferComponent.WriteRegion3
BufferComponent.WriteRegion3Int16 = BufferComponent.WriteRegion3int16
BufferComponent.writeRegion3int16 = BufferComponent.WriteRegion3int16
BufferComponent.writeregion3int16 = BufferComponent.WriteRegion3int16
BufferComponent.writeVector = BufferComponent.WriteVector
BufferComponent.writevector = BufferComponent.WriteVector
BufferComponent.writeEnum = BufferComponent.WriteEnum
BufferComponent.writeenum = BufferComponent.WriteEnum

--[Reader] signed interger alias
BufferComponent.readI1 = BufferComponent.ReadI1
BufferComponent.readi1 = BufferComponent.ReadI1
BufferComponent.readI8 = BufferComponent.ReadI8
BufferComponent.readi8 = BufferComponent.ReadI8
BufferComponent.readI16 = BufferComponent.ReadI16
BufferComponent.readi16 = BufferComponent.ReadI16
BufferComponent.readI24 = BufferComponent.ReadI24
BufferComponent.readi24 = BufferComponent.ReadI24
BufferComponent.readI32 = BufferComponent.ReadI32
BufferComponent.readi32 = BufferComponent.ReadI32
BufferComponent.readI40 = BufferComponent.ReadI40
BufferComponent.readi40 = BufferComponent.ReadI40
BufferComponent.readI48 = BufferComponent.ReadI48
BufferComponent.readi48 = BufferComponent.ReadI48
BufferComponent.readI54 = BufferComponent.ReadI54
BufferComponent.readi54 = BufferComponent.ReadI54

--[Reader] unsigned interger alias
BufferComponent.readU1 = BufferComponent.ReadU1
BufferComponent.readu1 = BufferComponent.ReadU1
BufferComponent.readU8 = BufferComponent.ReadU8
BufferComponent.readu8 = BufferComponent.ReadU8
BufferComponent.readU16 = BufferComponent.ReadU16
BufferComponent.readu16 = BufferComponent.ReadU16
BufferComponent.readU24 = BufferComponent.ReadU24
BufferComponent.readu24 = BufferComponent.ReadU24
BufferComponent.readU32 = BufferComponent.ReadU32
BufferComponent.readu32 = BufferComponent.ReadU32
BufferComponent.readU40 = BufferComponent.ReadU40
BufferComponent.readu40 = BufferComponent.ReadU40
BufferComponent.readU48 = BufferComponent.ReadU48
BufferComponent.readu48 = BufferComponent.ReadU48
BufferComponent.readU54 = BufferComponent.ReadU54
BufferComponent.readu54 = BufferComponent.ReadU54

--[Reader] float interger alias
BufferComponent.readF16 = BufferComponent.ReadF16
BufferComponent.readf16 = BufferComponent.ReadF16
BufferComponent.readF32 = BufferComponent.ReadF32
BufferComponent.readf32 = BufferComponent.ReadF32
BufferComponent.readF64 = BufferComponent.ReadF64
BufferComponent.readf64 = BufferComponent.ReadF64

--[Reader] boolean alias
BufferComponent.readBool1 = BufferComponent.ReadBool1
BufferComponent.readbool1 = BufferComponent.ReadBool1
BufferComponent.readBool8 = BufferComponent.ReadBool8
BufferComponent.readbool8 = BufferComponent.ReadBool8


--[Reader] string alias
BufferComponent.readString = BufferComponent.ReadString
BufferComponent.readstring = BufferComponent.ReadString

--[Reader] instance alias
BufferComponent.readInstance = BufferComponent.ReadInstance
BufferComponent.readinstance = BufferComponent.ReadInstance

--[Reader] roblox type alias
BufferComponent.readVector2 = BufferComponent.ReadVector2
BufferComponent.readvector2 = BufferComponent.ReadVector2
BufferComponent.ReadVector2Int16 = BufferComponent.ReadVector2int16
BufferComponent.readVector2int16 = BufferComponent.ReadVector2int16
BufferComponent.readvector2int16 = BufferComponent.ReadVector2int16
BufferComponent.readVector3 = BufferComponent.ReadVector3
BufferComponent.readvector3 = BufferComponent.ReadVector3
BufferComponent.readVector3int16 = BufferComponent.ReadVector3int16
BufferComponent.readvector3int16 = BufferComponent.ReadVector3int16
BufferComponent.ReadVector3Int16 = BufferComponent.ReadVector3int16
BufferComponent.readCFrame = BufferComponent.ReadCFrame
BufferComponent.readcframe = BufferComponent.ReadCFrame
BufferComponent.readLossyCFrame = BufferComponent.ReadLossyCFrame
BufferComponent.readlossyCFrame = BufferComponent.ReadLossyCFrame
BufferComponent.readUdim = BufferComponent.ReadUDim
BufferComponent.readudim = BufferComponent.ReadUDim
BufferComponent.ReadUdim = BufferComponent.ReadUDim
BufferComponent.readUdim2 = BufferComponent.ReadUDim2
BufferComponent.readudim2 = BufferComponent.ReadUDim2
BufferComponent.ReadUdim2 = BufferComponent.ReadUDim2
BufferComponent.readColor3 = BufferComponent.ReadColor3
BufferComponent.readcolor3 = BufferComponent.ReadColor3
BufferComponent.readRect = BufferComponent.ReadRect
BufferComponent.readrect = BufferComponent.ReadRect
BufferComponent.readRegion3 = BufferComponent.ReadRegion3
BufferComponent.readregion3 = BufferComponent.ReadRegion3
BufferComponent.ReadRegion3Int16 = BufferComponent.ReadRegion3int16
BufferComponent.readRegion3int16 = BufferComponent.ReadRegion3int16
BufferComponent.readregion3int16 = BufferComponent.ReadRegion3int16
BufferComponent.readVector = BufferComponent.ReadVector
BufferComponent.readvector = BufferComponent.ReadVector
BufferComponent.readEnum = BufferComponent.ReadEnum
BufferComponent.readenum = BufferComponent.ReadEnum

--[Signals] alias
BufferComponent.onOffsetChanged = BufferComponent.OnOffsetChanged
BufferComponent.onCapacityChanged = BufferComponent.OnCapacityChanged
BufferComponent.onInstanceOffsetChanged = BufferComponent.OnInstanceOffsetChanged
BufferComponent.disconnectAllSignals = BufferComponent.DisconnectAllSignals

--[Cursor] alias
BufferComponent.getOffset = BufferComponent.GetOffset
BufferComponent.getoffset = BufferComponent.GetOffset
BufferComponent.getInstanceOffset = BufferComponent.GetInstanceOffset
BufferComponent.getinstanceoffset = BufferComponent.GetInstanceOffset
BufferComponent.getRemainingSpace = BufferComponent.GetRemainingSpace

--[Buffer] alias
BufferComponent.compress = BufferComponent.Compress
BufferComponent.getBuffer = BufferComponent.GetBuffer
BufferComponent.getbuffer = BufferComponent.GetBuffer
BufferComponent.getInstanceBuffer = BufferComponent.GetInstanceBuffer
BufferComponent.getinstancebuffer = BufferComponent.GetInstanceBuffer
BufferComponent.getBufferSize = BufferComponent.GetBufferSize
BufferComponent.getbuffersize = BufferComponent.GetBufferSize
BufferComponent.Copy = BufferComponent.copy

--[Lifecycle] alias
BufferComponent.Clear = BufferComponent.clear
BufferComponent.ClearInstances = BufferComponent.clearInstances
BufferComponent.ClearBuffer = BufferComponent.clearBuffer
BufferComponent.Destroy = BufferComponent.Destroy

return BufferConstructor
