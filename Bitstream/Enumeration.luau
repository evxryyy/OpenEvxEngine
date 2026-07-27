--!strict

--[[
	Bitstream - Buffer Type Enumeration

	author : evxry_ll

	Purpose:
	This module defines the full set of supported buffer types used by Bitstream.

	It acts as a strict, type-safe enumeration mapping each buffer type name
	to a numeric identifier via a shared Enum system.

	Design goals:
	- Strong typing for all buffer primitives
	- Centralized definition of supported serialization types
	- Runtime-safe enum structure via EnumModule
	- Avoid accidental modification (frozen structure)

	Notes:
	- This enumeration is static and should not be modified at runtime.
	- Any change here affects serialization compatibility.
	- Values are explicit and must remain stable across versions.
]]

-- Types
const Types = require("./Types")

-- Core enum system (custom implementation)
const EnumModule = require("./Shared/Enum/index")

-- EnumIndex type definition (runtime metadata structure)
const EnumType = require("./Shared/Enum/indexType")

--[[
	Type: BitstreamTypesName

	Represents all supported types in Bitstream.
]]
export type BitstreamTypesName =
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
	| "F16"
	| "F32"
	| "F64"
	| "String"
	| "PrefixedString"
	| "Bool1"
	| "Bool8"
	| "Vector2float32"
	| "Vector2int16"
	| "Vector2uint16"
	| "Vector2"
	| "Vector3float32"
	| "Vector3int16"
	| "Vector3uint16"
	| "Vector3"
	| "CFrameQuaternion"
	| "CFrameF32"
	| "CFrameF64"
	| "CFrameQuantized"
	| "Color3"
	| "Color3F32"
	| "Color3F64"
	| "UDim"
	| "UDim2"
	| "RectFloat32"
	| "Rect"
	| "Enum"
	| "Region3"
	| "Region3Quaternion"
	| "Region3CFrameF32"
	| "Region3Quantized"
	| "RotationCurveKey"
	| "RotationCurveKeyQuaternion"
	| "RotationCurveKeyCFrameF32"
	| "RotationCurveKeyQuantized"
	| "FloatCurveKey"
	| "FloatCurveKeyF16"
	| "FloatCurveKeyF32"
	| "ColorSequence"
	| "ColorSequenceF32"
	| "ColorSequenceF64"
	| "NumberRange"
	| "NumberRangeF16"
	| "NumberRangeF64"
	| "NumberSequence"
	| "NumberSequenceF16"
	| "NumberSequenceF64"
	| "Array"
	| "Struct"

--[[
	Type = BitstreamTypes
	
	Represents the types that can be used at seriliazation and at dynamic runtime (writeAs, etc...)
]]
export type BitstreamTypes = 	
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
	| "F16"
	| "F32"
	| "F64"
	| {["Type"] : "String", Length : number?} -- Optional for `writeAs`
	| "PrefixedString"
	| "Bool1"
	| "Bool8"
	| "Vector2float32"
	| "Vector2int16"
	| "Vector2uint16"
	| "Vector2"
	| "Vector3float32"
	| "Vector3int16"
	| "Vector3uint16"
	| "Vector3"
	| "CFrameQuaternion"
	| "CFrameF32"
	| "CFrameF64"
	| "CFrameQuantized"
	| "Color3"
	| "Color3F32"
	| "Color3F64"
	| "UDim"
	| "UDim2"
	| "RectFloat32"
	| "Rect"
	| "Enum"
	| "Region3"
	| "Region3Quaternion"
	| "Region3CFrameF32"
	| "Region3Quantized"
	| {["Type"] : "RotationCurveKey", Option : Types.RotationCurveKeyOption}
	| {["Type"] : "FloatCurveKey", Option : Types.FloatCurveKeyOption}
	| {["Type"] : "ColorSequence", Option : Types.ColorSequenceOption}
	| "NumberRange"
	| "NumberRangeF16"
	| "NumberRangeF64"
	| {["Type"] : "NumberSequence", Option : Types.NumberSequenceOption}
	| ArraySchema
	| StructSchema
	

-- Serialization types
export type SerializationSchema = {[string] : BitstreamTypes}


-- Array and struct types
export type ArraySchema = {
	["Type"] : "Array",
	["Types"] : {[number]: BitstreamTypes}
}

export type StructSchema = {
	["Type"] : "Struct",
	["Fields"] : {[string] : BitstreamTypes},
}

--[[
	Runtime enumeration instance.

	Represents the full set of supported buffer types with stable numeric IDs.

	IMPORTANT:
	- Do not modify values after release
	- These IDs are part of serialization compatibility
	- Any change must be versioned explicitly
]]
local BitstreamTypes = EnumModule.new("BitstreamTypes", {
	I8 = 0x01,
	I16 = 0x02,
	I24 = 0x03,
	I32 = 0x04,
	I40 = 0x05,
	I48 = 0x06,
	I54 = 0x07,

	U1 = 0x08,
	U8 = 0x09,
	U16 = 0x0A,
	U24 = 0x0B,
	U32 = 0x0C,
	U40 = 0x0D,
	U48 = 0x0E,
	U54 = 0x0F,

	F16 = 0x10,
	F32 = 0x11,
	F64 = 0x12,

	String = 0x13,
	PrefixedString = 0x14,
	
	Bool1 = 0x15,
	Bool8 = 0x16,
	
	Vector2float32 = 0x17,
	Vector2int16 = 0x18,
	Vector2uint16 = 0x19,
	Vector2 = 0x1A,
	
	Vector3float32 = 0x1B,
	Vector3int16 = 0x1C,
	Vector3uint16 = 0x1D,
	Vector3 = 0x1E,
	
	CFrameQuaternion = 0x1F,
	CFrameF32 = 0x20,
	CFrameF64 = 0x21,
	CFrameQuantized = 0x22,
	
	Color3 = 0x23,
	Color3F32 = 0x24,
	Color3F64 = 0x25,
	
	UDim = 0x26,
	UDim2 = 0x27,
	
	RectFloat32 = 0x28,
	Rect = 0x29,
	
	Enum = 0x2A,
	
	Region3 = 0x2B,
	Region3Quaternion = 0x2C,
	Region3CFrameF32 = 0x2D,
	Region3Quantized = 0x2E,
	
	RotationCurveKey = 0x2F,
	
	FloatCurveKey = 0x30,
	
	ColorSequence = 0x31,
	
	NumberRange = 0x32,
	NumberRangeF16 = 0x33,
	NumberRangeF64 = 0x34,
	
	NumberSequence = 0x35,
	
	Array = 0x36,
	Struct = 0x37,
}) :: EnumModule.EnumClass<BitstreamTypesName,number>

return BitstreamTypes
