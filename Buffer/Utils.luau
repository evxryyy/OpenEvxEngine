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
	[string] : BufferType.BufferTypeName | {Type : BufferType.BufferTypeName, Length : number?}
}

type BufferSchemaValue = {
	[string] : any
}

type ConvertEnum = "Kilobytes" | "Megabytes" | "Gigabytes"

local Utils = {}
Utils.__index = Utils
Utils.ValidComplexType = {
	String = true,
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
		if(not Values[field]) then continue end
		if(fieldType == "Instance") then continue end
		if(typeof(fieldType) ~= "table" and Utils.ValidComplexType[fieldType]) then
			debugComplexSchema()
		end
		if(typeof(fieldType) == "table" and Utils.ValidComplexType[fieldType.Type]) then
			size += fieldType.Length
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

return Utils
