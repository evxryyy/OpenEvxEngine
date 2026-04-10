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
			return 1
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

return Utils
