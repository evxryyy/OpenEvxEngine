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

type ConvertEnum = "Kilobytes" | "Megabytes" | "Gigabyte"

local Utils = {}
Utils.__index = Utils

-- Calculates how many bytes are needed for the provided values.
Utils.getRequiredBytes = function(Schema : BufferSchema,Values : BufferSchemaValue) : number
	local listOfBytes = Constants.REQUIRED_BYTES
	local n = 0
	for field,fieldType in pairs(Schema) do
		if(not Values[field]) then continue end
		if(typeof(fieldType) == "table") then
			if(fieldType.Type ~= "String") then
				local failed = Debug["not valid type for complex schema"]
				failed = failed .. ("%s"):format(debug.info(1,"n"))
				error(failed,2)
			end
			local len = fieldType.Length :: number
			if(#Values[field] < len) then
				Values[field] = Values[field] .. string.rep(string.char(31),len - #Values[field])
			elseif(#Values[field] > len) then
				Values[field] = string.sub(Values[field],1,len)
			end
			n += listOfBytes.String(Values[field])
		elseif(fieldType == "Instance") then
			continue
		elseif(string.find(fieldType,"Boolean")) then
			local splitType = string.split(fieldType,"e")
			fieldType = splitType[1] .. string.sub(splitType[2],3,3)
			n += listOfBytes[fieldType]
		elseif(string.find(fieldType,"String")) then
			local splitStringType = string.split(fieldType, "g")
			if not splitStringType[2] or splitStringType[2] == "" then
				-- Invalid complex schema error
				local failed = Debug["not valid type for complex schema"]
				failed = failed .. ("%s"):format(debug.info(1,"n"))
				error(failed, 2)
			else
				local len = tonumber(splitStringType[2]) :: number
				if #Values[field] < len then
					Values[field] = Values[field] .. string.rep(string.char(31), len - #Values[field])
				elseif(#Values[field] > len) then
					Values[field] = string.sub(Values[field],1,len)
				end
				n += listOfBytes.String(Values[field])
			end
		else
			if(string.find(fieldType,"Float")) then
				local splitType = string.split(fieldType,"t")
				fieldType = "F" .. splitType[2]
			end
			n += listOfBytes[fieldType]
		end
	end
	return n
end

--Converts bytes to a specified unit.
function Utils.ConvertByte(To : ConvertEnum,bytes : number) : number
	if(To == "Kilobytes") then
		return bytes / 1024
	elseif(To == "Megabytes") then
		return bytes / 1_048_576
	elseif(To == "Gigabyte") then
		return bytes / 1_073_741_824
	end
	return -1
end

return Utils
