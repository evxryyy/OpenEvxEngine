--!optimize 2

--[[
	@name: Bitstream.Resolver
	
	@description : 
	Resolver is a utility module for the Bitstream module.
	It is used to resolve types and their properties.
]]

const Enumeration = require("./Enumeration")
const Constants = require("./Constants")
const Utilities = require("./Utilities")

const strmatch = string.match const strsub = string.sub const strrep = string.rep

const tblinsert = table.insert const tblclone = table.clone const tblclear = table.clear
const tblconcat = table.concat

type Array = {Enumeration.BitstreamTypes}
type Struct = {[string] : Enumeration.BitstreamTypes}
type ActionCallback = (...any) -> ()

const ERROR_MESSAGES_LIST = {
	CANT_WRITE_STRUCT_IN_ARRAY = [[
		Trying to write a struct in an array, but it's not supported.
		You can only write simple types in arrays and nested arrays.
		Please see : `#### API LINK ###`
	]],
	CANT_WRITE_DEEPLY_NESTED_ARRAY = [[
		Trying to write a table nested more than two levels deep, but it's not supported.
		You can only write simple types in arrays and nested arrays.
		I.e. : {10,{{10}},10} -> error you can only do {10,10,10} or {{10,10,10},{10,10,10}}.
	]]
}

const MAPPED_RBX_TYPES = {
	["CFrame"] = "CFrameF32",
	["Color3"] = "Color3",
	["Rect"] = "Rect",
	["Region3"] = "Region3CFrameF32",
	["RotationCurveKey"] = {
		Type = "RotationCurveKey",
		Option = "CFrameF32"
	},
	["FloatCurveKey"] = {
		Type = "FloatCurveKey",
		Option = "F32"
	},
	["ColorSequence"] = {
		Type = "ColorSequence",
		Option = "F32"
	},
}

const function verifyNestedElements(types : Array) : boolean
	for i = 1, #types do
		local typeInfo = types[i]
		if(typeof(typeInfo) == "table" and (typeInfo.Type == "Array" or "Struct")) then
			return true
		end
	end
	return false
end

const function verifiyNestedStruct(fields : Array) : boolean
	for _, field in fields do
		if(typeof(field) == "table" and field.Type == "Struct") then
			return true
		end
	end
	return false
end

local Resolver = {}
Resolver.__index = Resolver

--[[
	Iterates over an array schema and executes a callback for each resolved value.

	Supports repeated types using the `:<count>` syntax (e.g. `"U8:3"`),
	as well as nested arrays.

	Multi-dimensional arrays are currently not supported.
	
	@Note: only used for writeAs/Serialize and nothing else.

	@Parameters:
		- types : {Enumeration.BitstreamTypes}
		- values : {any}
		- func : (string, any) -> ()

	@Returns: ()
]]
Resolver.iterateArray = function(
	types : Array,
	values : {any},
	func : ActionCallback
)
	for i = 1,#types do
		local typeInfo = types[i]
		if(typeof(typeInfo) == "table" and (typeInfo.Type == "Array" or "Struct")) then
			if(typeInfo.Type == "Struct") then
				error(ERROR_MESSAGES_LIST.CANT_WRITE_STRUCT_IN_ARRAY,2)
			end
			-- nested array
			if(verifyNestedElements(typeInfo.Types)) then continue end
			Resolver.iterateArray(typeInfo.Types,values[i],func)
		else
			-- Simples types or type with count that came from an array (i.e U8:3)
			local typeHasCount = tonumber(strmatch(typeInfo,":(%d+)"))
			if(typeHasCount) then
				local typeOf = strmatch(typeInfo,"([^:]+)")
				for i = 1,typeHasCount do
					func(typeOf,values[i])
				end
			else
				func(typeInfo,values[i])
			end
		end
	end
end

--[[
	Iterates over a struct schema and executes a callback for each resolved value.

	Supports nested structs and arrays.

	Multi-dimensional arrays and structs are currently not supported.

	@Note: only used for writeAs/Serialize and nothing else.

	@Parameters:
		- struct : {[string] : Enumeration.BitstreamTypes}
		- values : {[string] : any}
		- func : (...any) -> ()

	@Returns: ()
]]
Resolver.iterateStruct = function(
	struct : {[string] : Enumeration.BitstreamTypes},
	values  : {[string] : any},
	func : ActionCallback
)
	for i,v in pairs(struct) do
		if(not values[i]) then continue end
		if(typeof(v) == "table" and (v.Type == "Array")) then
			Resolver.iterateArray(v.Types,values[i],func)
		elseif(typeof(v) == "table" and (v.Type == "Struct")) then
			if(verifiyNestedStruct(v.Fields)) then continue end
			Resolver.iterateStruct(v.Fields,values[i],func)
		else
			func(v,values[i])
		end
	end
end

--[[
	Resolves an array of bitstream types and executes a callback for each type.
	
	@Parameters:
		- types : {Enumeration.BitstreamTypes}
		- func : (...any) -> ()
		
	@Returns: ()
]]
Resolver.resolveArray = function(
	types : Array,
	func : ActionCallback,
	... : any
)
	for i = 1, #types do
		local typeInfo = types[i]
		if(typeof(typeInfo) == "table" and (typeInfo.Type == "Array" or "Struct")) then
			if(typeInfo.Type == "Struct") then
				error(ERROR_MESSAGES_LIST.CANT_WRITE_STRUCT_IN_ARRAY,2)
			end
			-- nested array
			if(verifyNestedElements(typeInfo.Types :: Array)) then continue end
			-- Last argument mean the nested array flag
			Resolver.resolveArray(typeInfo.Types :: Array,func,true)
		else
			-- Simples types or type with count that came from an array (i.e U8:3)
			local hasNestedFlag = (select("#",...) == 1) and true or false
			local typeOf = strmatch(typeInfo,"([^:]+)")
			local typeHasCount = tonumber(strmatch(typeInfo,":(%d+)"))
			func(typeOf,typeHasCount or 1,hasNestedFlag)
		end
	end
end

--[[
	Resolves a struct and executes a callback for each field.
	
	@Parameters:
		- struct : {[string] : Enumeration.BitstreamTypes}
		- func : (...any) -> element,elementOffset
		
	@Returns: ()
]]
Resolver.resolveStruct = function(
	struct : Struct,
	func : ActionCallback
) : {[string] : any}
	local resolvedStruct = {}
	for i,v in pairs(struct) do
		if(typeof(v) == "table" and (v.Type == "Array")) then
			if(not resolvedStruct[i]) then resolvedStruct[i] = {} end
			local nestedArray = {}
			Resolver.resolveArray(v.Types,function(targetType,typeCount,hasNestedFlag)
				for j = 1,typeCount do
					local element,elementOffset = func(targetType)
					if(hasNestedFlag) then
						tblinsert(nestedArray,element)
					else
						tblinsert(resolvedStruct[i],element)
					end
				end
				if(hasNestedFlag) then
					tblinsert(resolvedStruct[i],tblclone(nestedArray))
				end
				tblclear(nestedArray)	
			end)
		elseif(typeof(v) == "table" and (v.Type == "Struct")) then
			if(not resolvedStruct[i]) then resolvedStruct[i] = {} end
			if(verifiyNestedStruct(v.Fields)) then continue end
			for j,k in pairs(v.Fields) do
				if(typeof(k) == "table" and (k.Type == "Array")) then
					if(not resolvedStruct[i]) then resolvedStruct[i] = {} end
					resolvedStruct[i] = Resolver.resolveStruct(v.Fields,func)
					break
				end
			end
		else
			local element,elementOffset = func(v)
			resolvedStruct[i] = element
		end
	end
	return resolvedStruct
end

--[[
	Resolves the number of bytes needed to encode a value.
	
	@Parameters:
		- dataType : string
		- value : any
		
	@Returns: number
]]
Resolver.resolveBytesNeeded = function(typeInfo : Enumeration.BitstreamTypes,value : any)
	local bytes = 0
	if(typeof(typeInfo) == "table") then
		local extra = typeInfo.Length or typeInfo.Option
		if(typeof(extra) ~= "number") then
			typeInfo = typeInfo.Type .. extra
		end
		bytes += Constants.REQUIRED_BYTES[typeInfo](value)
	else
		bytes += (typeof(Constants.REQUIRED_BYTES[typeInfo]) == "function") 
			and Constants.REQUIRED_BYTES[typeInfo](value) 
			or Constants.REQUIRED_BYTES[typeInfo]
	end
	return bytes
end

--[[
	Resolves the type of a value.
	
	Some Roblox types can be redirected via the MAPPED_RBX_TYPES table.
	For example, "CFrame" is redirected to "CFrameF32".
	You can change the target variation by modifying the corresponding mapping entry.
	
	@Parameters:
		- value : any
		
	@Returns: string (i.e. Enumeration.BitstreamTypesName)
]]
Resolver.resolveValueType = function(value : any) : Enumeration.BitstreamTypesName
	local valueType = typeof(value)
	if(valueType == "number") then
		local isInt = (value % 1 == 0)
		local valueData = Utilities.GetEquivalentBytesInfoFromNumber(value)
		valueData.bits = valueData.bytes * 8
		if(not isInt) then
			return Enumeration.__enum["F"..valueData.bits].Name
		elseif(valueData.isUnsigned) then
			return Enumeration.__enum["U"..valueData.bits].Name
		else
			return Enumeration.__enum["I"..valueData.bits].Name
		end
	elseif(valueType == "string") then return Enumeration.__enum.String.Name
	elseif(valueType == "boolean") then return Enumeration.__enum.Bool1.Name
	elseif(valueType == "table") then
		if(Utilities.IsBool8(value)) then return Enumeration.__enum.Bool8.Name
		elseif(Utilities.IsArray(value)) then return Enumeration.__enum.Array.Name
		else return Enumeration.__enum.Struct.Name
		end
	elseif(MAPPED_RBX_TYPES[valueType]) then
		if(MAPPED_RBX_TYPES[valueType].Option) then
			return valueType..MAPPED_RBX_TYPES[valueType].Option
		end
		return MAPPED_RBX_TYPES[valueType]
	end
	return Enumeration.__enum[valueType].Name
end

--[[
	Rebuilds the schema representation of an array from its contained values.
	
	Each element is analyzed to determine its corresponding type, including nested arrays,
	while validating unsupported structures and invalid deep nesting cases.
	
	@Parameters:
		- value : array
		
	@Returns: ArraySchema
]]
Resolver.resolveArraySchema = function(value : {[number] : any}) : Enumeration.ArraySchema
	local schema = {
		Type = "Array",
		Types = {}
	}
	for i = 1,#value do
		local valueType = Resolver.resolveValueType(value[i])
		if(valueType == "Array") then
			local subSchema = Resolver.resolveArraySchema(value[i])
			schema.Types[i] = subSchema
			continue
		elseif(valueType == "Struct") then
			error(ERROR_MESSAGES_LIST.CANT_WRITE_STRUCT_IN_ARRAY,2)
		end
		schema.Types[i] = valueType
	end
	for i = 1,#schema.Types do
		local typeInfo = schema.Types[i]
		if(typeof(typeInfo) == "table" and (typeInfo.Type == "Array")) then
			-- nested array check
			if(verifyNestedElements(typeInfo.Types :: Array)) then 
				error(ERROR_MESSAGES_LIST.CANT_WRITE_DEEPLY_NESTED_ARRAY,2)
			end
		end
	end
	return schema
end


return Resolver
