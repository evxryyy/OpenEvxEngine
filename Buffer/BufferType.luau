--!strict

--[[
	BufferType.luau
	
	author : evxry_ll
	
	BufferType is a module that contains all the possible types of buffers from the BufferModule.
]]

-- Import the main Enum module, which allows creating custom enumerations
local EnumModule = require("./_index/Enum/Enum")

-- Import the EnumType type, used to type the values of enumerations
local EnumType = require("./_index/Enum/EnumType")

-- Define a Luau type "BufferTypeName" that includes all possible buffer type names
-- This is a union of strings representing the different data types a buffer can hold
export type BufferTypeName = 
	"I1"
	| "I8"
	| "I16"
	| "I24"
	| "I32"
	| "I40"
	| "I48"
	| "I54"
	| "U1"
	| "U8"
	| "U16"
	| "U24"
	| "U32"
	| "U40"
	| "U48"
	| "U54"
	| "Float16"
	| "Float32"
	| "Float64"
	| "String"
	| "String8"
	| "String16"
	| "String32"
	| "String64"
	| "Boolean1"
	| "Boolean8"
	| "Color3"
	| "Vector2"
	| "Vector2int16"
	| "Vector3"
	| "Vector3int16"
	| "CFrame"
	| "LossyCFrame"
	| "Rect"
	| "Region3"
	| "Region3int16"
	| "Instance"
	| "UDim"
	| "UDim2"

-- Define a generic type "BufferTypeEnum" based on an enumeration name
-- Each field corresponds to a buffer type and holds a value of type EnumType.EnumIndex
-- Ensures that every buffer value follows the enumeration structure
export type BufferTypeEnum<EnumName = string> = {
	I1: EnumType.EnumIndex<EnumName>,
	I8: EnumType.EnumIndex<EnumName>,
	I16: EnumType.EnumIndex<EnumName>,
	I24: EnumType.EnumIndex<EnumName>,
	I32: EnumType.EnumIndex<EnumName>,
	I40: EnumType.EnumIndex<EnumName>,
	I48: EnumType.EnumIndex<EnumName>,
	I54: EnumType.EnumIndex<EnumName>,
	U1: EnumType.EnumIndex<EnumName>,
	U8: EnumType.EnumIndex<EnumName>,
	U16: EnumType.EnumIndex<EnumName>,
	U24: EnumType.EnumIndex<EnumName>,
	U32: EnumType.EnumIndex<EnumName>,
	U40: EnumType.EnumIndex<EnumName>,
	U48: EnumType.EnumIndex<EnumName>,
	U54: EnumType.EnumIndex<EnumName>,
	Float16: EnumType.EnumIndex<EnumName>,
	Float32: EnumType.EnumIndex<EnumName>,
	Float64: EnumType.EnumIndex<EnumName>,
	String: EnumType.EnumIndex<EnumName>,
	String8: EnumType.EnumIndex<EnumName>,
	String16: EnumType.EnumIndex<EnumName>,
	String32: EnumType.EnumIndex<EnumName>,
	String64: EnumType.EnumIndex<EnumName>,
	Boolean1: EnumType.EnumIndex<EnumName>,
	Boolean8: EnumType.EnumIndex<EnumName>,
	Color3: EnumType.EnumIndex<EnumName>,
	Vector2: EnumType.EnumIndex<EnumName>,
	Vector2int16: EnumType.EnumIndex<EnumName>,
	Vector3: EnumType.EnumIndex<EnumName>,
	Vector3int16: EnumType.EnumIndex<EnumName>,
	CFrame: EnumType.EnumIndex<EnumName>,
	LossyCFrame: EnumType.EnumIndex<EnumName>,
	Rect: EnumType.EnumIndex<EnumName>,
	Region3: EnumType.EnumIndex<EnumName>,
	Region3int16: EnumType.EnumIndex<EnumName>,
	Instance: EnumType.EnumIndex<EnumName>,
	UDim: EnumType.EnumIndex<EnumName>,
	UDim2: EnumType.EnumIndex<EnumName>,
}

-- Actual creation of the "BufferType" enumeration using EnumModule
-- Each value is a buffer type name, typed as BufferTypeName
-- The cast :: BufferTypeEnum<"Buffer"> ensures the result matches the defined type
local BufferType = EnumModule.new("BufferType", {
	"I1",
	"I8",
	"I16",
	"I24",
	"I32",
	"I40",
	"I48",
	"I54",
	"U1",
	"U8",
	"U16",
	"U24",
	"U32",
	"U40",
	"U48",
	"U54",
	"Float16",
	"Float32",
	"Float64",
	"String",
	"String8",
	"String16",
	"String32",
	"String64",
	"Boolean1",
	"Boolean8",
	"Color3",
	"Vector2",
	"Vector2int16",
	"Vector3",
	"Vector3int16",
	"CFrame",
	"LossyCFrame",
	"Rect",
	"Region3",
	"Region3int16",
	"Instance",
	"UDim",
	"UDim2",
} :: {BufferTypeName}) :: BufferTypeEnum<"Buffer">

-- Export the enumeration for use in other modules
return BufferType
