--[[
	Author : evxry_ll

	@class Extensions
	
	Contains all extensions methods used in `Bitstream`
]]

const Signal = require("./Shared/Zignal")
const Debugger = require("./Debugger")
const Types = require("./Types")
const Enumeration = require("./Enumeration")
const Utilities = require("./Utilities")
const Constants = require("./Constants")

-- Luau imports:

-- math lib
const huge = math.huge const modf = math.modf const floor = math.floor
const clamp = math.clamp const ceil = math.ceil const log = math.log
const sin = math.sin const cos = math.cos

-- bit32 lib
const arshift = bit32.arshift const band = bit32.band const bnot = bit32.bnot const bor = bit32.bor
const btest = bit32.btest const bxor = bit32.bxor const byteswap = bit32.byteswap const countlz = bit32.countlz
const countrz = bit32.countrz const extract = bit32.extract const replace = bit32.replace const lrotate = bit32.lrotate
const lshift = bit32.lshift const rrotate = bit32.rrotate const rshift = bit32.rshift

-- string lib
const sub = string.sub const char = string.char const byte = string.byte const format = string.format
const len = string.len const strpack = string.pack const strunpack = string.unpack

-- buffer lib, micro gain but i prefer this way
const create = buffer.create const fromstring = buffer.fromstring const tostring = buffer.tostring
const bufflen = buffer.len const readbits = buffer.readbits const readi8 = buffer.readi8
const readi16 = buffer.readi16 const readi32 = buffer.readi32 const readu8 = buffer.readu8
const readu16 = buffer.readu16 const readu32 = buffer.readu32 const readf32 = buffer.readf32
const readf64 = buffer.readf64 const writebits = buffer.writebits const writei8 = buffer.writei8
const writei16 = buffer.writei16 const writei32 = buffer.writei32 const writeu8 = buffer.writeu8
const writeu16 = buffer.writeu16 const writeu32 = buffer.writeu32 const writef32 = buffer.writef32
const writef64 = buffer.writef64 const readstring = buffer.readstring const writestring = buffer.writestring
const copy = buffer.copy const fill = buffer.fill

-- string lib
const strlen = string.len const strsub = string.sub const strmatch = string.match

-- Fixed numbers (used for big-endian manual packing etc..)
const fNaN = 0x7E00 -- 32_256 (used for NaN in float16)
const fInfinity = 0x7C00 -- 31_744 (used for infinity in float16)
const fSubNormal = 0x3FF -- 1023 (used for subnormals in float16)
const f31bit = 0x1F -- 31 (used for 31 bit fixed numbers)
const f15bit = 0xF -- 15 (used for 15 bit fixed numbers)
const f10bit = 0x0A -- 10 (used for the exponent in f16)
const f24_exp_bits = 5 -- 5 (used for 24 bit fp fixed numbers)
const f24_mant_bits = 18 -- 18 (used for 24 bit fp fixed numbers)

--[[
	@function floatToBits
	@within Extensions
	
	@param number -- The number to convert.
	
	@returns number -- The number converted to bits.
	
	Convert a float to its unsigned 32-bit representation.
]]
const function floatToBits(n)
	return strunpack(">I4",strpack(">f",n))
end

--[[
	@function bitsToFloat
	@within Extensions
	
	@param bits number -- The number in bits to convert.
	@returns number -- The number converted to float.
	
	Convert a 32-bit unsigned integer to a float.
]]
const function bitsToFloat(bits)
	return strunpack(">f",strpack(">I4",bits))
end

--[[
	@function axisAngleToQuaternion
	@within Extensions
	
	@param axis Vector3
	@param angle number
	
	@returns {X : number, Y : number, Z : number, W : number} -- Quaternion
	Converts an axis-angle representation to a quaternion.
]]
const function axisAngleToQuaternion(axis : Vector3,angle : number) : Types.Quaternion
	local halfAngle = angle / 2
	local s,c = sin(halfAngle),cos(halfAngle)
	return {
		x = axis.X * s,
		y = axis.Y * s,
		z = axis.Z * s,
		w = c
	}
end

--[[
	@function quaternionToCFrame
	@within Extensions
	
	@param pos Vector3
	@param quaternion {X : number, Y : number, Z : number, W : number}
	
	@returns CFrame
	Converts a quaternion to a CFrame with the given position.
]]
const function quaternionToCFrame(pos : Vector3,quaternion : Types.Quaternion)
	local xx,yy,zz = 
		quaternion.x*quaternion.x,
		quaternion.y*quaternion.y,
		quaternion.z*quaternion.z
	local xy,xz,yz = 
		quaternion.x*quaternion.y,
		quaternion.x*quaternion.z,
		quaternion.y*quaternion.z
	local wx,wy,wz = 
		quaternion.w*quaternion.x,
		quaternion.w*quaternion.y,
		quaternion.w*quaternion.z
	return CFrame.new(pos.X,pos.Y,pos.Z,
		1 - 2 * (yy + zz), 2 * (xy - wz), 2 * (xz + wy),
		2 * (xy + wz), 1 - 2 * (xx + zz), 2 * (yz - wx),
		2 * (xz - wy), 2 * (yz + wx), 1 - 2 * (xx + yy)
	)
end

--[[
	@function toFloat16
	@within Extensions

	@param value number
	The float32 value to convert.

	@returns Tuple(
		uint16: number,
		sign: number,
		mantissa: number,
		exponent: number
	)

	Returns the IEEE 754 half-precision floating-point representation.

	- uint16: The encoded 16-bit unsigned integer value.
	- sign: The sign bit (0 = positive, 1 = negative).
	- mantissa: The 10-bit mantissa field.
	- exponent: The 5-bit exponent field.
]]
const function toFloat16(value : number)
	local uint16;
	local sign : number;
	local mantissa : number;
	local exponent : number;
	if (value == 0) then
		uint16 = 0
	elseif(value ~= value) then
		uint16 = fNaN
	elseif(value == huge) then
		uint16 = fInfinity
	elseif(value == -huge) then
		uint16 = fInfinity
	else
		sign = 0
		if(value < 0) then
			sign = 1
			value = -value
		end
		exponent = floor(log(value,2))
		mantissa = value / (2 ^ exponent) - 1
		exponent = exponent + 15
		if(exponent <= 0) then
			mantissa = value / (2 ^ -14)
			exponent = 0
		elseif(exponent >= 31) then
			uint16 = bor(lshift(sign,15),fInfinity)
			return uint16,sign,mantissa,exponent
		end
		uint16 = bor(lshift(sign,f15bit),lshift(exponent,f10bit),band(floor(mantissa * 1024),fSubNormal))
	end
	return uint16,sign,mantissa,exponent
end

--[[
	@function decodeF16
	@within Extensions
	
	@param buff buffer
	The buffer containing the 16-bit float.
	@param offset number
	The offset to start reading from.
	
	@returns number
	Decodes a 16-bit IEEE 754 half-precision floating-point value from the buffer at the specified offset.
]]
const function decodeF16(buff : buffer,offset : number) : number
	local uint16 = readu16(buff,offset)
	local sign = rshift(uint16,f15bit)
	local exponent = band(rshift(uint16,f10bit),f31bit)
	local mantissa = band(uint16,fSubNormal)
	if(exponent == 0) then
		if(mantissa == 0) then
			-- +0 or -0
			return sign == 0 and 0 or -0
		else
			local value = (mantissa / 1024) * (2 ^ -14)
			return sign == 0 and value or -value
		end
	elseif(exponent == 31) then
		if(mantissa == 0) then
			return sign == 0 and huge or -huge
		else
			return fNaN
		end
	end
	local value = (1 + mantissa / 1024) * (2 ^ (exponent - f15bit))
	return sign == 0 and value or -value
end

--[[
	@function getEnumTypeFromIdentifier
	@within Extensions
	
	@param : number (i.e : 1)
	The identifier of the enum type to retrieve.
	
	@return : string
	The name of the enum type with the given identifier.
]]
const function getEnumTypeFromIdentifier(typeIdentifier : number) : Enumeration.BitstreamTypesName
	for enumName,enumValue in pairs(Enumeration.__enum) do
		if(enumValue.Value == typeIdentifier) then
			return enumName :: Enumeration.BitstreamTypesName
		end
	end
end

--[[
	@function bitstreamTypesToLiteralTypes
	@within Extensions
	
	@param : Enumeration.BitstreamTypesName
	The Bitstream type name.
	
	@returns string
	The Luau/Roblox type.

	Converts a Bitstream type name into its corresponding Luau/Roblox type.
]]
const function bitstreamTypesToLiteralTypes(Type : Enumeration.BitstreamTypesName) : string
	if(Type == "UDim" or Type == "UDim2") then return Type end
	-- Enum
	if(Type == "Enum") then return "EnumItem" end
	-- Strings
	if(Type == "PrefixedString" or
		Type == "String") then return "string" end
	-- Color3
	if(Type == "Color3F32" or 
		Type == "Color3F64") then return "Color3" end
	-- Rect
	if(Type == "RectFloat32") then return "Rect" end
	-- CFrame
	if(Type == "CFrameF32" or
		Type == "CFrameQuaternion" or 
		Type == "CFrameQuantized" or 
		Type == "CFrameF64") then return "CFrame" end
	-- Vectors
	if(Type == "Vector3float32" or 
		Type == "Vector3uint16") then return "Vector3" end
	if(Type == "Vector2float32" or 
		Type == "Vector2uint16") then return "Vector2" end
	-- Regions
	if(Type == "Region3CFrameF32" or
		Type == "Region3Quaternion" or 
		Type == "Region3Quantized") then return "Region3" end
	-- NumberRanges
	if(Type == "NumberRangeF16" or
		Type == "NumberRangeF64") then return "NumberRange" end
	-- Get the first letter of the type for numbers
	const symbol = sub(Type,1,1)
	const isOnly3Letters = len(Type) == 3
	if(symbol == "U" or
		symbol == "I" or 
		symbol == "F" and isOnly3Letters) then 
		return "number" 
	elseif(symbol == "B" and isOnly3Letters) then
		return "boolean"
	end
	return Type
end

--[[
	@function encodeF24
	@within Extensions
	
	@param : number
	The float to encode.
	
	@returns number
	The encoded float-24 number.
	
	Converts a standard floating-point number into the custom 24-bit floating-point format by extracting its IEEE-754 sign, 
	exponent, and mantissa, then compressing them into a 24-bit representation 
]]
const function encodeF24(float : number) : number
	local sign = 0
	
	if(float < 0) then 
		sign = 1
		float = -float
	end
	if(float == 0) then return 0 end
	
	local bits = floatToBits(float)
	local exponent = extract(bits,23,8)
	local mantissa = extract(bits,0,23)
	
	-- Subnormal & Overflow
	local exp = exponent - 127 + f15bit + 1
	if(exp <= 0) then
		local m = floor(float * 2 ^ (f15bit + f24_mant_bits) + 0.5)
		return bor(lshift(sign,23),m)
	elseif(exp > f31bit) then
		return bor(lshift(sign,23),0x7FFFFF)
	end

	mantissa = rshift(mantissa,23 - f24_mant_bits)

	return bor(lshift(sign,23),lshift(exp,f24_mant_bits),mantissa)
end

--[[
	@function decodeF24
	@within Extensions
	
	@param : number
	The 24-bit float to decode.
	
	@returns number
	The decoded float.
	
	Converts a value stored in the custom 24-bit floating-point format back into a standard floating-point number 
	by reconstructing its IEEE-754 sign, exponent and mantissa.
]]
const function decodeF24(b24 : number) : number
	local sign = extract(b24,23,1)
	local exponent = extract(b24,f24_mant_bits,f24_exp_bits)
	local mantissa = extract(b24,0,f24_mant_bits)
	
	if(exponent == 0 and mantissa == 0) then return 0 end
	
	local value
	
	if(exponent == 0) then
		value = mantissa * 2 ^ -(f24_exp_bits + f24_mant_bits)
	else
		local ieeeExponent = exponent - f15bit + 127 - 1
		local ieee = bor(lshift(ieeeExponent,23),lshift(mantissa,23 - f24_mant_bits))
		value = bitsToFloat(ieee)
	end
	
	if(sign == 1) then value = -value end
	
	return value
end

--[[
	@function encodeF8
	@within Extensions
	
	@param : number
	The float to encode.
	
	@returns number
	The encoded float-8 number.
	
	Converts a standard floating-point value into its 8-bit E4M3 representation by encoding its sign, exponent, and mantissa
]]
const function encodeF8(float : number) : number
	local sign = 0
	
	if(float < 0 ) then
		sign = 1
		float = -float
	end
	
	if(float == 0) then
		return 0
	end
	
	local exponent = floor(log(float) / log(2))
	local mantissa = floor(((float / (2 ^ exponent)) - 1) * 8 + 0.5)
	
	exponent += 7
	
	if(exponent < 0) then
		exponent = 0
		mantissa = 0
	elseif(exponent > 15) then
		exponent = 15
		mantissa = 7
	end
	
	return bor(lshift(sign,7),lshift(exponent,3),mantissa)
end

--[[
	@function decodeF8
	@within Extensions
	
	@param : number
	The float-8 number to decode.
	
	@returns number
	The decoded float.
	
	Converts an 8-bit E4M3 floating-point representation back into a standard floating-point value 
	by reconstructing its sign, exponent, and mantissa
]]
const function decodeF8(b8 : number) : number
	local sign = rshift(b8,7)
	local exponent = band(rshift(b8,3),f15bit)
	local mantissa = band(b8,0x7)
	
	if(exponent == 0 and mantissa == 0) then return 0 end
	
	local value = (1 + mantissa / 8) * (2 ^ (exponent - 7))
	
	if(sign == 1) then value = -value end
	
	return value
end

return {
	
	axisAngleToQuaternion = axisAngleToQuaternion,
	quaternionToCFrame = quaternionToCFrame,
	encodeF8 = encodeF8,
	decodeF8 = decodeF8,
	toFloat16 = toFloat16,
	decodeF16 = decodeF16,
	encodeF24 = encodeF24,
	decodeF24 = decodeF24,
	getEnumTypeFromIdentifier = getEnumTypeFromIdentifier,
	bitstreamTypesToLiteralTypes = bitstreamTypesToLiteralTypes,
	
}
