-- Author: evxry_ll
--
-- Note : THIS IS A PART OF THE BUFFER LIBRARY.
--
-- Purpose: Compute required bytes for a set of values based on a schema.
-- Handles fixed-length string padding/truncation and byte size lookup.

local BufferType = require('./BufferType')
local Constants = require('./Constants')
local Debug = require('./Debug')

type BufferSchema = {
	[string] : BufferType.BufferTypeName | BufferType.BufferComplexType
}

type BufferSchemaValue = {
	[string] : any
}

type ConvertEnum = "Kilobytes" | "Megabytes" | "Gigabytes"

local Utils = {}
Utils.__index = Utils
Utils.ValidComplexType = {
	String = true,
	Array = true,
}

local function debugComplexSchema()
	local failed = Debug["not valid type for complex schema"]
	failed = failed .. ("%s"):format(debug.info(1,"n"))
	error(failed,2)
end

-- Calculates how many bytes are needed for the provided values.
function Utils.GetRequiredBytes<T>(Schema : BufferSchema,Values : {[string] : T})
	local size = 0
	for field,fieldType in Schema do
		if(Values[field] == nil) then continue end
		if(fieldType == "Instance") then continue end
		if(typeof(fieldType) ~= "table" and Utils.ValidComplexType[fieldType]) then
			debugComplexSchema()
		end
		if(typeof(fieldType) == "table" and Utils.ValidComplexType[fieldType.Type]) then
			if(fieldType.Type == "String") then
				size += fieldType.Length
			elseif(fieldType.Type == "Array") then
				-- Calculate the array length using recursive call
				size += Utils.GetRequiredBytes(fieldType.Types,Values[field])
			end
			continue
		end
		if(typeof(Constants.REQUIRED_BYTES[fieldType]) == "function") then
			size += Constants.REQUIRED_BYTES[fieldType](Values[field])
		else
			local boolBits = fieldType:match("^Boolean(%d+)$")
			local floatBits = fieldType:match("^Float(%d+)$")
			if(not boolBits and not floatBits) then 
				size += Constants.REQUIRED_BYTES[fieldType] 
			elseif(boolBits and not floatBits) then
				size += Constants.REQUIRED_BYTES["Bool"..boolBits]
			elseif(floatBits and not boolBits) then
				size += Constants.REQUIRED_BYTES["F"..floatBits]
			end
		end
	end
	return size
end

--Converts bytes to a specified unit.
function Utils.ConvertByte(To : ConvertEnum,bytes : number) : number
	if(To == "Kilobytes") then
		return bytes / 1024
	elseif(To == "Megabytes") then
		return bytes / 1_048_576
	elseif(To == "Gigabytes") then
		return bytes / 1_073_741_824
	end
	return -1
end

--[[
	Generates a mapping of enum values to indices and vice versa.
	@return {[number] : Enum} & {[Enum] : number}
]]
function Utils.GenerateEnumMapping() : {[number] : Enum} & {[Enum] : number}
	local enumMapping = {}
	local reverseMapping = {}
	local index = 1
	for _, enumType in pairs(Enum:GetEnums()) do
		enumMapping[index] = enumType
		reverseMapping[enumType] = index
		index += 1
	end
	return enumMapping, reverseMapping
end

--[[
	Used in `Buffer.Serialize` to serialize complex string types.
	
	@private
]]
function Utils._SerializeComplexString(schema : {Type : "String", Length : number}, value : string)
	-- Right-pad with char(31) to reach exact fixed length
	if(#value < schema.Length) then
		value = value .. string.rep(string.char(31),schema.Length - #value)
	elseif(#value > schema.Length) then
		value = string.sub(value :: string,1,schema.Length)
	end
	-- return the modified value
	return value
end

--[[
	Used in Buffer.WriteAny, this give the exact byte required depending on the number.
	
	@example :
	```luau
	local b = Utils.GetEquivalentBytesInfoFromNumber(65535) -- this will return 2 cause it will required 2 bytes to write 65535
	```
	
	@return : {bits : number, bytes : number, @isUnsigned : boolean }
]]
function Utils.GetEquivalentBytesInfoFromNumber(n : number)
	if n < 0 then
		-- signed
		local bits = 1
		local value = math.abs(n)
		while value > 0 do
			value = math.floor(value / 2)
			bits = bits + 1
		end
		return { bits = bits, bytes = math.ceil(bits / 8), isUnsigned = false }
	else
		-- unsigned
		if n == 0 then
			return { bits = 1, bytes = 1, isUnsigned = true }
		end
		local bits = math.ceil(math.log(n + 1, 2))
		return { bits = bits, bytes = math.ceil(bits / 8), isUnsigned = true }
	end
end

--[[
	Used in Buffer.WriteAny to check if the given table as a valid bool8 table.

	@private
]]
function Utils._isValidBool8Table(value : {boolean}) : boolean
	local count = 1
	for i = 1, #value do
		if(typeof(value[i]) == "boolean") then count += 1 end
	end
	return count >= 8
end

--[[
	Resolves the byte code identifier associated with a given value.

	Description:
	Determines the most efficient byte representation for a value based on its type
	and characteristics. This byte code is later used for serialization to encode
	the value in a compact binary format.

	Handled Types:
	- number: Differentiates between float, signed, and unsigned integers.
	- string: Encoded with a predefined string byte code.
	- boolean: Encoded as a 1-bit boolean.
	- table: Special handling for compact boolean arrays (Bool8).
	- vector: Supports Luau vector type.
	- other Roblox types: Mapped directly via typeof lookup.

	@param value any -- Value to analyze
	@return number -- Byte code representing the value type
]]
function Utils.GetByteCodeValueFromType(value : any)
	-- Retrieve both Luau typeof and Lua type for edge cases (e.g., vector)
	local valueTypeof = typeof(value)
	local valueType = type(value)
	-- Handle numbers
	if(valueTypeof == "number") then
		-- Separate integer and fractional part
		local _,x = math.modf(value :: number)
		-- Get optimal byte size and sign info
		local bytesInfo = Utils.GetEquivalentBytesInfoFromNumber(value)
		-- Normalize fractional part
		x = math.ceil(x)
		-- Floating point case (has decimal part)
		if(x > 0) then
			local sign = "F"

			-- Ensure minimum size (at least 16 bits for small floats)
			local bits = (bytesInfo.bytes <= 1) and (0+2) * 8 or bytesInfo.bytes * 8

			return Constants.BYTES_CODE[sign..bits]
		end
		-- Unsigned integer case
		if(bytesInfo.isUnsigned) then
			local sign = "U"
			local bits = bytesInfo.bytes * 8
			return Constants.BYTES_CODE[sign..bits]
		end
		-- Signed integer case
		local sign = "I"
		local bits = bytesInfo.bytes * 8
		return Constants.BYTES_CODE[sign..bits]
	end
	-- Handle strings
	if(valueTypeof == "string") then
		return Constants.BYTES_CODE.String
	end
	-- Handle booleans (stored as 1 bit)
	if(valueTypeof == "boolean") then
		return Constants.BYTES_CODE.Bool1
	end
	-- Handle tables
	if(valueTypeof == "table") then
		-- Detect optimized boolean array (packed into 8 bits)
		if(Utils._isValidBol8Table(value)) then
			return Constants.BYTES_CODE.Bool8
		end
	end
	-- Special case: Luau vector type
	if(valueType == "vector") then
		return Constants.BYTES_CODE.vector
	end
	-- Fallback: map directly using typeof (Roblox datatypes, etc.)
	return Constants.BYTES_CODE[valueTypeof]
end

--[[
	Reads a single serialized value from the buffer.

	Description:
	Decodes a value from the buffer based on its previously written byte code.
	This function dynamically resolves the type, reads the value accordingly,
	and advances the offset based on the number of bytes consumed.

	Supports:
	- Primitive types (numbers, string, boolean)
	- Roblox types (Instance, vector, etc.)
	- Custom encoded types via Constants.BYTES_CODE
	
	@private function (use it if you know what you're doing)
	@param _writer BufferComponentClass -- Buffer reader instance
	@param _offset number? -- Starting offset (default: 0)
	@param _instanceOffset number? -- Instance index offset (default: 1)
	@return (number, any) -- New offset and decoded value
]]
function Utils._ReadValue(_writer,_offset : number?,_instanceOffset : number?) : (number,any)
	-- Early exit if buffer is empty
	if(_writer:GetBufferSize() == 0) then return end
	-- Initialize offsets with defaults if not provided
	local offset = (_offset ~= nil) and _offset or 0;
	local instanceOffset = (_instanceOffset ~= nil) and _instanceOffset or 1;
	local value
	-- Get current max offset (not directly used but may serve validation/debug)
	local max_offset = _writer:GetOffset()
	-- Read the byte code representing the value type
	local valueTypeof = _writer:ReadU8(offset)
	-- Upper bound index for numeric types in BYTES_CODE
	local maxIndexOfNumbers = 19 -- 19 is the last index of the numbers types
	local valueTypeofName = "undefined"
	-- Resolve byte code to its corresponding type name
	for name,code in Constants.BYTES_CODE do
		if(code == valueTypeof) then
			valueTypeofName = name
		end
	end
	-- Invalid or unknown type
	if(valueTypeofName == "undefined") then return end
	-- Move offset past the type byte
	offset += 1
	-- Handle string (length-prefixed)
	if(valueTypeofName == "String") then
		-- Read string length
		local length = _writer:ReadU8(offset)
		-- Move offset past length byte
		offset += 1
		-- Read actual string
		value = _writer:ReadString(length,offset)
		-- Handle numeric types (optimized dispatch)
	elseif(valueTypeof <= maxIndexOfNumbers) then
		value = _writer["Read"..valueTypeofName](_writer,offset)
		-- Handle vector type (Luau)
	elseif(valueTypeofName == "vector") then
		value = _writer:ReadVector(offset)
		-- Handle Instance references (indexed separately)
	elseif(valueTypeofName == "Instance") then
		value = _writer:ReadInstance(instanceOffset)
		-- Increment instance index for next read
		instanceOffset += 1
		-- Generic fallback for other supported types
	else
		value = _writer["Read"..valueTypeofName](_writer,offset)
	end
	-- Retrieve byte size information for the type
	local getBytesInfo = Constants.REQUIRED_BYTES[valueTypeofName]
	-- Advance offset based on dynamic or static byte size
	if(typeof(getBytesInfo) == "function") then
		offset += getBytesInfo(value)
	elseif(typeof(getBytesInfo) == "number") then
		offset += getBytesInfo
	end
	-- Return updated offset and decoded value
	return offset,value
end

return Utils
