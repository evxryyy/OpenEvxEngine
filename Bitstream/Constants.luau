--!optimize 2

const Types = require("./Types")
const Utilities = require("./Utilities")

const EnumItemList = {} :: {[number] : EnumItem}
const EnumItemIndex = {} :: {[EnumItem] : number}

const strlen = string.len

for i, enum in ipairs(Enum:GetEnums()) do
	for j, enumItem in ipairs(enum:GetEnumItems()) do
		table.insert(EnumItemList,enumItem)
		EnumItemIndex[enumItem] = #EnumItemList
	end
end
table.freeze(EnumItemList)
table.freeze(EnumItemIndex)

return table.freeze({
	
	-- // INTEGER TYPES //  -- 
	
	-- Signed integers
	MIN_INT1 = -1, MAX_INT1 = 1,
	MIN_INT8 = -128, MAX_INT8 = 127, -- [min = -2^7, max = 2^7 - 1]
	MIN_INT16 = -32_768, MAX_INT16 = 32_767, -- [min = -2^15, max = 2^15 - 1]
	MIN_INT24 = -8_388_608, MAX_INT24 = 8_388_607, -- [min = -2^23, max = 2^23 - 1]
	MIN_INT32 = -2_147_483_648, MAX_INT32 = 2_147_483_647, -- [min = -2^31, max = 2^31 - 1]
	MIN_INT40 = -549_755_813_888, MAX_INT40 = 549_755_813_887, -- [min = -2^39, max = 2^39 - 1]
	MIN_INT48 = -140_737_488_355_328, MAX_INT48 = 140_737_488_355_327, -- [min = -2^47, max = 2^47 - 1]
	MIN_INT54 = -9_007_199_254_740_992, MAX_INT54 = 9_007_199_254_740_991, -- [min = -2^53, max = 2^53 - 1]
	
	-- Unsigned integers
	MIN_UINT = 0,
	MAX_UINT8 = 255, -- [max = 2^8 - 1]
	MAX_UINT16 = 65_535, -- [max = 2^16 - 1]
	MAX_UINT24 = 16_777_215, -- [max = 2^24 - 1]
	MAX_UINT32 = 4_294_967_295, -- [max = 2^32 - 1]
	MAX_UINT40 = 1_099_511_627_775, -- [max = 2^40 - 1]
	MAX_UINT48 = 281_474_976_710_655, -- [max = 2^48 - 1]
	MAX_UINT54 = 18_014_398_509_481_980, -- [max = 2^54 - 1], max is reduced by 3 due to `IEEE754` range
	
	-- // STRINGS TYPES // -- 
	MIN_STRING = 1,
	MAX_STRING8 = 8,
	MAX_STRING16 = 16,
	MAX_STRING32 = 32,
	MAX_STRING64 = 64,
	
	-- How many bytes required for each available type.
	REQUIRED_BYTES = {
		-- Signed Integers
		I1 = 1,
		I8 = 1,
		I16 = 2,
		I24 = 3,
		I32 = 4,
		I40 = 5,
		I48 = 6,
		I54 = 7,
		-- Unsigned Integers
		U1 = 1,
		U8 = 1,
		U16 = 2,
		U24 = 3,
		U32 = 4,
		U40 = 5,
		U48 = 6,
		U54 = 7,
		-- Floats
		F8 = 1,
		F16 = 2,
		F24 = 3,
		F32 = 4,
		F64 = 8,
		-- Strings
		String = function(str) 
			return strlen(str) 
		end,
		PrefixedString = function(str)
			const len = strlen(str)
			const bytesData = Utilities.GetEquivalentBytesInfoFromNumber(len)
			--[[
				calculation:
					1 byte for the type identifier
					n bytes for the string length (U8, U16, U24, ..., U48)
					len bytes for the string data

				schema:
					(1 + n + len)
			]]
			return 1 + bytesData.bytes + len
		end,
		-- Booleans
		Bool1 = 1,
		Bool8 = 1,
		-- Others
		Vector2float32 = 8, -- (half-precision vector2)
		Vector2int16 = 4, -- (Vector2int16 by default)
		Vector2uint16 = 4, -- (Same as Vector2int16 but use unsigned integer)
		Vector2 = 16, -- (full precision Vector2)
		Vector3float32 = 12, -- (half-precision vector3)
		Vector3int16 = 6, -- (Vector3int16 by default)
		Vector3uint16 = 6, -- (Same as Vector3int16 but use unsigned integer)
		Vector3 = 24, -- (full precision Vector3)
		CFrameQuaternion = 28, -- (CFrame converted into a quaternion (x,y,z,w) )
		CFrameF32 = 24, -- (convert to euler angles and write (pos + rx,ry,rz) as f32)
		CFrameF64 = 48, -- (convert to euler angles and write (pos + rx,ry,rz) as f64)
		CFrameQuantized = 12, -- (quantized CFrame, 12 bytes using i16)
		Color3 = 3, -- (1 byte each for R,G,B)
		Color3F32 = 12, -- (4 bytes each for R,G,B)
		Color3F64 = 24, -- (8 bytes each for R,G,B)
		UDim = 8,
		UDim2 = 16,
		RectFloat32 = 16, -- (Store min and max vector as f32)
		Rect = 32, -- (Store min and max vector as f64)
		Enum = 2,
		Region3 = 72, -- (Vec3, CFrameF64)
		Region3Quaternion = 52, -- (Vec3, CFrameQuaternion)
		Region3CFrameF32 = 48,-- (Vec3, CFrameF32)
		Region3Quantized = 36, -- (Vec3, CFrameQuantized)
		Region3int16 = 12, --  (Vec3int16, Vec3int16)
		RotationCurveKey = function(rotationKey : RotationCurveKey,option : Types.RotationCurveKeyOption)
			if(not option or option == "") then option = "Normal" end
			if(option == "Normal") then
				return (rotationKey.Interpolation == Enum.KeyInterpolationMode.Cubic) and 62 or 54
			elseif(option == "Quaternion") then
				return (rotationKey.Interpolation == Enum.KeyInterpolationMode.Cubic) and 42 or 34
			elseif(option == "CFrameF32") then
				return (rotationKey.Interpolation == Enum.KeyInterpolationMode.Cubic) and 38 or 30
			elseif(option == "Quantized") then
				return (rotationKey.Interpolation == Enum.KeyInterpolationMode.Cubic) and 26 or 18
			end
		end,
		FloatCurveKey = function(key : FloatCurveKey,option : Types.FloatCurveKeyOption)
			if(not option or option == "") then option = "Normal" end
			if(option == "Normal") then
				return (key.Interpolation == Enum.KeyInterpolationMode.Cubic) and 22 or 14
			elseif(option == "F32") then
				return (key.Interpolation == Enum.KeyInterpolationMode.Cubic) and 18 or 10
			elseif(option == "F16") then
				return (key.Interpolation == Enum.KeyInterpolationMode.Cubic) and 16 or 8
			end
		end,
		ColorSequence = function(key : ColorSequence,option : Types.ColorSequenceOption)
			if(not option or option == "") then option = "Normal" end
			if(option == "Normal") then
				return 1 + (7 * #key.Keypoints)
			elseif(option == "F32") then
				return 1 + (16 * #key.Keypoints)
			elseif(option == "F64") then
				return 1 + (28 * #key.Keypoints)
			end
		end,
		NumberRange = 8,
		NumberRangeF16 = 4,
		NumberRangeF64 = 16,
		NumberSequence = function(key : NumberSequence,option : Types.NumberSequenceOption)
			if(not option or option == "") then option = "Normal" end
			if(option == "Normal") then
				return 1 + (12 * #key.Keypoints)
			elseif(option == "F16") then
				return 1 + (10 * #key.Keypoints)
			elseif(option == "F64") then
				return 1 + (16 * #key.Keypoints)
			end
		end,
	},
	
	-- [number] = EnumItem, table identifiers to avoid 2 extra bytes while writing Enums
	EnumItemList = EnumItemList,
	-- [EnumItem] = number, O(1) research when writing
	EnumItemIndex = EnumItemIndex
	
})
