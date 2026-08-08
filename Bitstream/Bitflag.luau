--[[
	@Author : evxry_ll

	BitFlag is a component of the Bitstream framework responsible for
	encoding, decoding, and handling type flags, markers, strings, and structures.

	@Framework Bitstream
]]
const Enumeration = require("./Enumeration")
const Utilities = require("./Utilities")
const Resolver = require("./Resolver")

-- bit32 lib
const arshift = bit32.arshift const band = bit32.band const bnot = bit32.bnot const bor = bit32.bor
const btest = bit32.btest const bxor = bit32.bxor const byteswap = bit32.byteswap const countlz = bit32.countlz
const countrz = bit32.countrz const extract = bit32.extract const replace = bit32.replace const lrotate = bit32.lrotate
const lshift = bit32.lshift const rrotate = bit32.rrotate const rshift = bit32.rshift

-- buffer lib
const create = buffer.create const fromstring = buffer.fromstring const bufftostring = buffer.tostring
const bufflen = buffer.len const readbits = buffer.readbits const readi8 = buffer.readi8
const readi16 = buffer.readi16 const readi32 = buffer.readi32 const readu8 = buffer.readu8
const readu16 = buffer.readu16 const readu32 = buffer.readu32 const readf32 = buffer.readf32
const readf64 = buffer.readf64 const writebits = buffer.writebits const writei8 = buffer.writei8
const writei16 = buffer.writei16 const writei32 = buffer.writei32 const writeu8 = buffer.writeu8
const writeu16 = buffer.writeu16 const writeu32 = buffer.writeu32 const writef32 = buffer.writef32
const writef64 = buffer.writef64 const readstring = buffer.readstring const writestring = buffer.writestring
const copy = buffer.copy const fill = buffer.fill

-- math lib
const abs = math.abs const floor = math.floor const log = math.log
const ceil = math.ceil const modf = math.modf const clamp = math.clamp

-- string lib
const str_char = string.char const str_format = string.format const str_sub = string.sub
const str_byte = string.byte const str_find = string.find const str_match = string.match
const str_gsub = string.gsub const str_upper = string.upper const str_lower = string.lower
const str_rep = string.rep const str_split = string.split const str_pack = string.pack
const str_packsize = string.packsize const str_unpack = string.unpack
const str_len = string.len

--[[
	Defines the numeric identifiers used by the Bitstream framework to
	represent supported data types during serialization and deserialization.

	Each identifier is encoded into the bitstream as a compact type flag.
]]
const TYPE_IDS = {
	I8 = 0x00,
	I16 = 0x01,
	I24 = 0x02,
	I32 = 0x03,
	I40 = 0x04,
	I48 = 0x05,
	I54 = 0x06,

	U1 = 0x07,
	U8 = 0x08,
	U16 = 0x09,
	U24 = 0x0A,
	U32 = 0x0B,
	U40 = 0x0C,
	U48 = 0x0D,
	U54 = 0x0E,

	F8 = 0x0F,
	F16 = 0x10,
	F24 = 0x11,
	F32 = 0x12,
	F64 = 0x13,

	String = 0x14,
	PrefixedString = 0x15,

	Bool1 = 0x16,
	Bool8 = 0x17,

	Vector2float24 = 0x18,
	Vector2float32 = 0x19,
	Vector2int16 = 0x1A,
	Vector2uint16 = 0x1B,
	Vector2 = 0x1C,

	Vector3float24 = 0x1D,
	Vector3float32 = 0x1E,
	Vector3int16 = 0x1F,
	Vector3uint16 = 0x20,
	Vector3 = 0x21,

	CFrameQuaternion = 0x22,
	CFrameF24 = 0x23,
	CFrameF32 = 0x24,
	CFrameF64 = 0x25,
	CFrameQuantized = 0x26,

	Color3 = 0x27,
	Color3F24 = 0x28,
	Color3F32 = 0x29,
	Color3F64 = 0x2A,

	UDim = 0x2B,
	UDim2 = 0x2C,

	RectFloat24 = 0x2D,
	RectFloat32 = 0x2E,
	Rect = 0x2F,

	Enum = 0x30,

	Region3 = 0x31,
	Region3Quaternion = 0x32,
	Region3CFrameF24 = 0x33,
	Region3CFrameF32 = 0x34,
	Region3Quantized = 0x35,

	RotationCurveKey = 0x36,
	RotationCurveKeyQuaternion = 0x37,
	RotationCurveKeyCFrameF24 = 0x38,
	RotationCurveKeyCFrameF32 = 0x39,
	RotationCurveKeyQuantized = 0x3A,

	FloatCurveKey = 0x3B,
	FloatCurveKeyF16 = 0x3C,
	FloatCurveKeyF24 = 0x3D,
	FloatCurveKeyF32 = 0x3E,

	ColorSequence = 0x3F,
	ColorSequenceF24 = 0x40,
	ColorSequenceF32 = 0x41,
	ColorSequenceF64 = 0x42,

	NumberRange = 0x43,
	NumberRangeF16 = 0x44,
	NumberRangeF24 = 0x45,
	NumberRangeF64 = 0x46,

	NumberSequence = 0x47,
	NumberSequenceF16 = 0x48,
	NumberSequenceF24 = 0x49,
	NumberSequenceF64 = 0x4A,

	Array = 0x4B,
	Struct = 0x4C,

	Instance = 0x4D,
}

--[[
	Provides reverse lookup from a numeric type identifier to its type name.
]]
const IDS_TYPES = {}
for i,v in pairs(TYPE_IDS) do IDS_TYPES[v] = i end


--[[
	Defines the default allocation size, in bytes, for Bitflag buffers.
	This value is used when no custom initial size is provided.
]]
const DEFAULT_SIZE = 256

--[[
	Defines the marker values used by the Bitstream framework to identify
	the beginning and end of structures and nested structures.

	Markers are stored separately from type identifiers to distinguish
	structural information from serialized values.
]]
const MARKER_VALUE = {
	STRUCT_START = 0xFA,
	STRUCT_END = 0xFB,
	SUB_STRUCT_START = 0xFC,
	SUB_STRUCT_END = 0xFD,
}

--[[
	Provides reverse lookup from a numeric marker value to its marker name.
]]
const VALUE_MARKER = {}
for i,v in pairs(MARKER_VALUE) do VALUE_MARKER[v] = i end

--[[
	Represents a buffer used by Bitflag to store serialized data,
	its allocated size, and the current read or write offset.

	@Fields
		buffer : buffer - The underlying Roblox buffer.
		size : number - The allocated buffer size in bytes.
		offset : number - The current position in the buffer.
]]
type BitflagBuffer = {
	buffer : buffer,
	size : number,
	offset : number,
}

--[[
	Represents an array containing Bitstream-compatible values or types.
]]
type Array = {Enumeration.BitstreamTypes}

--[[
	Represents a structure containing named Bitstream-compatible fields.
]]
type Struct = {[string] : Enumeration.BitstreamTypes}

--[[
	Defines the parameters required to serialize a structure.

	@Fields
		markerBuffer : BitflagBuffer - Buffer used to store type and structure markers.
		fieldsBuffer : BitflagBuffer - Buffer used to store field names and metadata.
		fields : {[string] : any} - Structure fields to serialize.
]]
type WriteStructParameters = {
	markerBuffer : BitflagBuffer,
	fieldsBuffer : BitflagBuffer,
	fields : {[string] : any},
}

--[[
	Defines the parameters required to deserialize a compiled structure.

	@Fields
		compiledBuffer : BitflagBuffer - Buffer containing the serialized structure.
		markerStartOffset : number? - Optional byte offset where marker reading starts.
		fieldsStartOffset : number? - Optional offset where field reading starts.
]]
type ReadStructParameters = {
	compiledBuffer : BitflagBuffer,
	markerStartOffset : number?,
	fieldsStartOffset : number?,
}

const function ensureCapacity(data : BitflagBuffer,bytesNeeded : buffer) : buffer
	local required = floor(data.offset) + bytesNeeded
	if(data.size <= required) then
		local newBuffer = create(required)
		copy(newBuffer,0,data.buffer,0,data.size)
		data.buffer = newBuffer
		data.size = required
	end
	return data.buffer
end

const function ensureReadable(data : BitflagBuffer,offset : number,bytes : number) : boolean
	offset = (typeof(offset) == "number" and offset or data.offset)
	if(offset < 0 or offset + bytes > bufflen(data.buffer)) then
		return false
	end
	return true
end

const function verifyNestedElements(types : Array) : boolean
	for i = 1, #types do
		local typeInfo = types[i]
		if(typeof(typeInfo) == "table") then
			return true
		end
	end
	return false
end

const function verifyNestedStruct(fields : Struct) : boolean
	for _, field in fields do
		if(typeof(field) == "table") then
			return true
		end
	end
	return false
end

const function writestringbits(data : BitflagBuffer,offset : number,str : string)
	writebits(data.buffer,offset,8,str_len(str))
	offset += 8
	for i = 1, str_len(str) do
		local char = str_sub(str,i,i):byte()
		if(char > 127) then
			error("String contains non-ascii characters")
		end
		writebits(data.buffer,offset,7,char)
		offset += 7
	end
end

const function readstringbits(data : BitflagBuffer,offset : number)
	local str = ""
	local len = readbits(data.buffer,offset,8); offset += 8
	ensureReadable(data,offset,len)
	for i = 1,len do
		local char = str_char(readbits(data.buffer,offset,7))
		str = str .. char
		offset += 7
	end
	return str
end

local BitFlag = {}
BitFlag.__index = BitFlag

--[[
	Creates a new BitFlag buffer used for bit-level read and write operations.

	@Parameters
		size : number? - The initial buffer size in bytes.

	@Returns
		BitflagBuffer - The newly created buffer.
]]
BitFlag.createBuffer = function(size : number) : BitflagBuffer
	size = size or DEFAULT_SIZE
	return {
		buffer = create(size),
		size = size,
		offset = 0,
	}
end

--[[
	Writes a type flag and its optional metadata into the buffer.

	@Parameters
		data : BitflagBuffer - The target buffer.
		flag : Enumeration.BitstreamTypesName - The type identifier to write.
		... : any - Optional metadata associated with the type.

	@Returns
		nil
]]
BitFlag.write = function(data : BitflagBuffer,flag : Enumeration.BitstreamTypesName,... : any)
	if(flag == "String") then
		ensureCapacity(data,3)
		writeu8(data.buffer,floor(data.offset),TYPE_IDS[flag])
		writeu16(data.buffer,floor(data.offset + 1),...)
		data.offset += 3
	else
		ensureCapacity(data,1)
		writeu8(data.buffer,floor(data.offset),TYPE_IDS[flag])
		data.offset += 1
	end
end

--[[
	Writes a marker value into the buffer to identify a structural element.

	@Parameters
		data : BitflagBuffer - The target buffer.
		markerValue : number - The marker value to write.

	@Returns
		nil
]]
BitFlag.writeMarker = function(data : BitflagBuffer,markerValue : number)
	ensureCapacity(data,1)
	writeu8(data.buffer,data.offset,abs(markerValue))
	data.offset += 1
end

--[[
	Writes an ASCII string using a compact 7-bit character representation.

	@Parameters
		data : BitflagBuffer - The target buffer.
		str : string - The ASCII string to write.

	@Returns
		nil
]]
BitFlag.writeString = function(data : BitflagBuffer,str : string)
	ensureCapacity(data,1)
	writestringbits(data,data.offset,str)
	data.offset += 8 + str_len(str) * 7
end

--[[
	Serializes a structure into a Bitstream-compatible buffer containing
	type markers, field names, and nested structure metadata.

	@Parameters
		parameters : WriteStructParameters - The buffers and fields used to build the structure.

	@Returns
		BitflagBuffer - The compiled structure buffer.
]]
BitFlag.writeStruct = function(parameters : WriteStructParameters)
	local markerBuffer = parameters.markerBuffer
	local fieldsBuffer = parameters.fieldsBuffer
	BitFlag.writeMarker(markerBuffer, MARKER_VALUE.STRUCT_START)
	for key, value in parameters.fields do
		local tag = Resolver.resolveValueType(value)
		if(tag == "Struct") then
			if(verifyNestedStruct(value)) then
				error("Error : Nested struct is not supported")
			end
			BitFlag.writeMarker(markerBuffer, MARKER_VALUE.SUB_STRUCT_START)
			BitFlag.writeString(fieldsBuffer, key)
			for sk, sv in value do
				local stag = Resolver.resolveValueType(sv)
				BitFlag.writeString(fieldsBuffer, sk)
				BitFlag.write(markerBuffer,stag,(stag == "String") and str_len(sv) or nil)
			end
			BitFlag.writeMarker(markerBuffer, MARKER_VALUE.SUB_STRUCT_END)
		else
			BitFlag.write(markerBuffer,tag,(tag == "String") and str_len(value) or nil)
			BitFlag.writeString(fieldsBuffer, key)
		end
	end
	BitFlag.writeMarker(markerBuffer, MARKER_VALUE.STRUCT_END)
	local markerBytes = markerBuffer.offset
	local fieldBytes = ceil(fieldsBuffer.offset / 8)
	local merged = create(markerBytes + fieldBytes)
	copy(merged,0,markerBuffer.buffer,0,markerBytes)
	copy(merged,markerBytes,fieldsBuffer.buffer,0,fieldBytes)
	return {
		buffer = merged,
		size = markerBytes + fieldBytes,
		offset = markerBytes + fieldBytes,
	}
end

--[[
	Reads a type flag from the specified buffer offset.

	@Parameters
		data : BitflagBuffer - The source buffer.
		offset : number - The byte offset from which to read.

	@Returns
		number - The encoded type identifier.
]]
BitFlag.read = function(data : BitflagBuffer, offset : number)
	ensureReadable(data,offset,1)
	return readu8(data.buffer,offset)
end

--[[
	Reads a compact 7-bit ASCII string from the specified buffer offset.

	@Parameters
		data : BitflagBuffer - The source buffer.
		offset : number - The bit offset from which to read.

	@Returns
		string - The decoded ASCII string.
]]
BitFlag.readString = function(data : BitflagBuffer,offset : number)
	ensureReadable(data,offset,1)
	return readstringbits(data,offset)
end

--[[
	Reads and resolves a structural marker from the specified buffer offset.

	@Parameters
		data : BitflagBuffer - The source buffer.
		offset : number - The byte offset from which to read.

	@Returns
		string? - The name of the corresponding marker, if valid.
]]
BitFlag.readMarker = function(data : BitflagBuffer, offset : number)
	ensureReadable(data,offset,1)
	return VALUE_MARKER[readu8(data.buffer,offset)]
end

--[[
	Deserializes a compiled structure buffer and reconstructs its field schema.

	@Parameters
		parameters : ReadStructParameters - The compiled buffer and optional read offsets.

	@Returns
		table - The reconstructed structure schema.
		number - The total size of the compiled buffer in bytes.
]]
BitFlag.readStruct = function(parameters : ReadStructParameters)
	local compiledBuffer = parameters.compiledBuffer
	local offset = parameters.markerStartOffset or 0
	local schema = {}
	BitFlag.readMarker(compiledBuffer, offset)
	offset += 1
	while(true) do
		local id = readu8(compiledBuffer.buffer, offset)
		if(id == MARKER_VALUE.STRUCT_END) then
			offset += 1
			break
		end
		local target = IDS_TYPES[id] or VALUE_MARKER[id]
		if(id == TYPE_IDS.String) then
			local len = readu16(compiledBuffer.buffer,offset + 1)
			offset += 2
			target = target .. ":" .. len
		end
		schema[#schema + 1] = target
		offset += 1
	end
	local fieldOffset = offset * 8
	local formatted = {}
	local index = 1
	while(index <= #schema) do
		local valueType = schema[index]
		if(valueType == "SUB_STRUCT_START") then
			local structName = BitFlag.readString(compiledBuffer, fieldOffset)
			fieldOffset += 8 + str_len(structName) * 7
			formatted[structName] = {}
			index += 1
			while(index <= #schema) and (schema[index] ~= "SUB_STRUCT_END") do
				local field = BitFlag.readString(compiledBuffer, fieldOffset)
				fieldOffset += 8 + str_len(field) * 7
				formatted[structName][field] = schema[index]
				index += 1
			end
			index += 1
		else
			local field = BitFlag.readString(compiledBuffer, fieldOffset)
			fieldOffset += 8 + str_len(field) * 7
			formatted[field] = valueType
			index += 1
		end
	end
	return formatted, compiledBuffer.size
end

--[[
	Executes a function with the provided arguments and returns its results.

	@Parameters
		actFunc : (...A) -> ...R - The function to execute.
		... : A - The arguments passed to the function.

	@Returns
		...R - The results returned by the executed function.
]]
BitFlag.act = function<A,R>(actFunc : (...A) -> ...R,... : A) : R
	if(typeof(actFunc) ~= "function") then return end
	return actFunc(...) :: R
end

return BitFlag
