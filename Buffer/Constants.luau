return table.freeze({
	--INTEGER TYPES--
	MIN_UINT = 0,
	MAX_UINT1 = 1,
	MAX_UINT8 = 255,
	MAX_UINT16 = 65535,
	MAX_UINT24 = 16777215,
	MAX_UINT32 = 4294967296,
	MAX_UINT40 = 1099511627775,
	MAX_UINT48 = 281474976710655,
	MAX_UINT54 = 18014398509481980, --The maximum value is essentially 18014398509481984, but Roblox does not allow values greater

	MIN_INT1 = -1,
	MAX_INT1 = 1,
	MIN_INT8 = -128,
	MAX_INT8 = 127,
	MIN_INT16 = -32768,
	MAX_INT16 = 32767,
	MIN_INT24 = -8388608,
	MAX_INT24 = 8388607,
	MIN_INT32 = -2147483648,
	MAX_INT32 = 2147483647,
	MIN_INT40 = -549755813888,
	MAX_INT40 = 549755813887,
	MIN_INT48 = -140737488355328,
	MAX_INT48 = 140737488355327,
	MIN_INT54 = -9007199254740992,
	MAX_INT54 = 9007199254740991,

	--FLOAT TYPES--
	--MIN_FLOAT32 = -1.1754943508222875e-38, -- (2 ^ (-126))
	--MAX_FLOAT32 = 3.4028234663852886e+38, -- (2 - 2 ^ -23) * 2 ^ 127
	--MIN_FLOAT64 = -2.2250738585072014e-308, -- (2 ^ (-1022))
	--MAX_FLOAT64 = 1.7976931348623157e+308, -- (2 - 2 ^ (-52)) * 2 ^ 1023

	--STRING TYPES--
	MIN_STRING = 1,
	MAX_STRING8 = 8,
	MAX_STRING16 = 16,
	MAX_STRING32 = 32,
	MAX_STRING64 = 64,

	REQUIRED_BYTES = {
		I1 = 1,
		I8 = 1,
		I16 = 2,
		I24 = 3,
		I32 = 4,
		I40 = 5,
		I48 = 6,
		I54 = 7,
		U1 = 1,
		U8 = 1,
		U16 = 2,
		U24 = 3,
		U32 = 4,
		U40 = 5,
		U48 = 6,
		U54 = 7,
		F16 = 2,
		F32 = 4,
		F64 = 8,
		String = function(str) : number
			return #str	
		end,
		String8 = 8,
		String16 = 16,
		String32 = 32,
		String64 = 64,
		Bool1 = 1,
		Bool8 = 1,
		Color3 = 12,
		Vector2 = 16,
		Vector2int16 = 4,
		Vector3 = 24,
		Vector3int16 = 6,
		CFrame = 96,
		LossyCFrame = 48,
		Rect = 32,
		Region3 = 120,
		Region3int16 = 12,
		UDim = 8,
		UDim2 = 16,
		vector = 24,
		Enum = 4,
		FloatCurveKey = function(floatKey : FloatCurveKey)
			return (floatKey.Interpolation == Enum.KeyInterpolationMode.Cubic) and 24 or 16
		end,
		RotationCurveKey = function(rotationKey : RotationCurveKey)
			return (rotationKey.Interpolation == Enum.KeyInterpolationMode.Cubic) and 112 or 104
		end,
		ColorSequence = function(sequence : ColorSequence)
			return 1 + (16 * #sequence.Keypoints)
		end,
		NumberRange = 8,
		NumberSequence = function(sequence : NumberSequence)
			return 1 + (12 * #sequence.Keypoints)
		end,
	},

	--VERSION--
	VERSION = "2.9",
})
