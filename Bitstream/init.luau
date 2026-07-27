--[[
	Author: evxry_ll
	
	@Name: Bitstream
	
	@Description:
	This module provides a set of functions for reading and writing binary data.
	It provides a convenient way to serialize and deserialize data.
	
	@Features:
	- Supports all types of data
	- Supports auto allocation
	- Supports custom types
]]

--!optimize 2

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const EncodingService = game:GetService("EncodingService")
const HttpService = game:GetService("HttpService")

const Shared = script.Parent.Shared

const Types = require("./Types")
const Utilities = require("./Utilities")
const Enumeration = require("./Enumeration")
const Constants = require("./Constants")
const Signal = require(Shared.Zignal)
const Extensions = require("./Extensions")
const Debugger = require("./Debugger")
const Resolver = require("./Resolver")

-- Version control (only once)
local versionIsVerified = false
if(not versionIsVerified) then 
	task.spawn(Debugger.verifyVersion)
	versionIsVerified = true
end
 
 --[[ 
 	Luau imports : 
	
	High-performance Luau bindings for bit32 and other APIs.
	Local caching is used to eliminate repeated global table lookups and reduce
	overhead in hot execution paths (serialization, networking, binary processing).
	This improves performance in tight loops by relying on faster local variable access.
]]

-- bit32 lib
const arshift = bit32.arshift const band = bit32.band const bnot = bit32.bnot const bor = bit32.bor
const btest = bit32.btest const bxor = bit32.bxor const byteswap = bit32.byteswap const countlz = bit32.countlz
const countrz = bit32.countrz const extract = bit32.extract const replace = bit32.replace const lrotate = bit32.lrotate
const lshift = bit32.lshift const rrotate = bit32.rrotate const rshift = bit32.rshift

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

-- math lib
const huge = math.huge const modf = math.modf const floor = math.floor
const clamp = math.clamp const ceil = math.ceil const log = math.log
const round = math.round const abs = math.abs

-- string lib
const strlen = string.len const strgmatch = string.gmatch const strchar = string.char const strbyte = string.byte
const strsub = string.sub const strmatch = string.match

-- table lib
const tblinsert = table.insert const tblclone = table.clone const tblclear = table.clear
const tblconcat = table.concat

-- Fixed (Unsigned) numbers (used for big-endian manual packing etc..)
const fbit8 = 0x100 -- 256
const fbit16 = 0x10000 -- 65_536
const fbit24 = 0x1000000 -- 16_777_216
const fbit32 = 0x100000000 -- 4_294_967_296
const fbit40 = 0x10000000000 -- 109_951_162_777_6
const fbit48 = 0x1000000000000 -- 281_474_976_710_656
const fbit54 = 0x40000000000000 -- 18_014_398_509_481_984 (slightly upper than the IEEE754 double max)
		
-- Signed
const fsbit8 = 0x80 -- 128
const fsbits40 = 0x8000000000 -- 549_755_813_888
const fsbits48 = 0x800000000000 -- 140_737_488_355_328
const fsbits54 = 0x20000000000000 -- 9_007_199_254_740_992

-- Manual packing constants
const bm6 = 0x3F -- 63 (Mask used to keep only the lowest 6 bits of a value.)

-- CFrame Quantization constants
const POSITION_SCALE = 1000 -- ~0.05°, Range: ±π radians
const ROTATION_SCALE = 10430.38 -- 1mm, Range: ±32km

-- API Constructor & Component --
local BitstreamConstructor = {}
local Bitstream = {}

BitstreamConstructor.__index = BitstreamConstructor
Bitstream.__index = Bitstream

-- Instance type for BitstreamComponent
export type BitstreamComponent = typeof(setmetatable({} :: {
	-- Internal
	__buffer : buffer,
	__offset : number,
	__useAutoAllocation : boolean,
	__maximumAllowedSize : number,

	-- Instances (not in raw buffer directly)
	__instanceBuffer : {Instance},
	__instanceOffset : number,
	
	-- Signals
	__capacityChanged : Signal.Signal<number>,
	__offsetChanged : Signal.Signal<number>,
	__instanceOffsetChanged : Signal.Signal<number>,
},Bitstream))

-- Functions

--[[
	Ensure the buffer has enough space to write at the current offset.
	Will throw an error if there is not enough space.
	Otherwise auto-allocate more space if `self.__useAutoAllocation` is true.
]]
const function ensureWritable(self : BitstreamComponent,size : number) : boolean
	local needed = self.__offset + size
	if(needed <= bufflen(self.__buffer)) then
		return true
	end
	if(not self.__useAutoAllocation) then
		error(
			Debugger.catchError("Doesn\'t have enough space"):format(
				Debugger.getFunctionName()))
	else
		self = self:allocate(needed - self.__offset)
		return true,self
	end
end

--[[
	Ensure the buffer has enough space to read at the current offset.
	Will throw an error if the offset is out of bounds or if their not enough spaces.
]]
const function ensureReadable(self : BitstreamComponent,offset : number,bytes : number) : boolean
	offset = (typeof(offset) == "number" and offset or self.__offset)
	if(offset < 0 or offset + bytes > bufflen(self.__buffer)) then
		error(
			Debugger.catchError("Out of bounds"):format(
				Debugger.getFunctionName(4),
				offset,bytes,bufflen(self.__buffer)
			))
	end
	return true
end

--[[
	Execute a function on the buffer at the current offset.
	Will throw an error if there is not enough space or out of bounds.
	
	@Generics A : Array of parameters for the function.
	@Generics R : Return type of the function.
	
	@Parameters: 
		- component : BitstreamComponent
		- func : (buffer, number) -> any
		- ... : A
		
	@Returns: R
]]
const function executeRead<A,R>(self : BitstreamComponent,readFunc : (...A) -> R,... : A) : R
	if(not readFunc) then return nil end
	local args = table.pack(...)
	local argsLen = args.n
	
	-- Make the offset is here and marked as a number
	local offset = if(typeof(args[1]) == "number") then (args[1] :: number) else (args[2] :: number)
	local useBitoffset = false

	local functionName = Debugger.getFunctionName(3)
	local functionType = strsub(functionName,5,#functionName) -- U8
	
	if(functionType == "U1" or "Bool1" or "Bool8") then
		useBitoffset = true
	end
	
	-- Ensure there is enough space to read
	local bytes = if(args[argsLen] == offset and args.n <= 2) then nil else (args[argsLen] :: number)
	if(bytes == nil and Constants.REQUIRED_BYTES[functionType]) then
		bytes = (typeof(Constants.REQUIRED_BYTES[functionType]) == "number") 
			and Constants.REQUIRED_BYTES[functionType] or 0
	end

	-- Check if the bytes is 0 
	if(bytes == 0) then
		error("No bytes specified for function " .. functionType .. "")
	end
	
	ensureReadable(self,(useBitoffset == true) and offset / 8 or offset,bytes)
		
	-- Execute the function and return the result
	return readFunc(...) :: R
end

--[[
	Construct a new Bitstream-Component with the actual configuration.
	
	@Parameters: ctorConfiguration : ConstructorConfiguration
		The configuration table used to initialize the Bitstream instance.

	@Returns: Bitstream-Component
		A newly created Bitstream component instance.
]]
function BitstreamConstructor.new(ctorConfiguration : Types.ConstructorConfiguration) : BitstreamComponent
	return setmetatable({
		-- Internal
		__buffer = create(ctorConfiguration.Size or 0),
		__offset = 0,
		__useAutoAllocation = ctorConfiguration.UseAutoAllocation or false,
		__maximumAllowedSize = ctorConfiguration.MaximumAllowedSize or huge,
		-- Instances data
		__instanceBuffer = {},
		__instanceOffset = 0,
		-- Signals
		__capacityChanged = Signal.new(),
		__offsetChanged = Signal.new(),
		__instanceOffsetChanged = Signal.new(),
	},Bitstream)	
end

--[[
	Construct a new Bitstream-Component with the actual configuration.
	The offset is directly set to the length of the source buffer.
	
	If `ctor.MaximumAllowedSize` is less than the length of the source buffer,
	the maximum allowed size is set to the length of the source buffer. this only apply if ctor.MaximumAllowedSize is not-
	set to nil.
	
	@Parameters: ctorConfiguration : ConstructorConfiguration
		The configuration table used to initialize the Bitstream instance.
		
	@Required: ctorConfiguration.SourceBuffer : buffer
		The buffer to use as source buffer.
	
	@Returns: Bitstream-Component
		A newly created Bitstream component instance.
]]
function BitstreamConstructor.from(ctorConfiguration : Types.ConstructorConfiguration)
	assert(ctorConfiguration.SourceBuffer ~= nil, "SourceBuffer is nil, but it is required")
	return setmetatable({
		-- Internalf
		__buffer = ctorConfiguration.SourceBuffer :: buffer,
		__offset = bufflen(ctorConfiguration.SourceBuffer :: buffer),
		__useAutoAllocation = ctorConfiguration.UseAutoAllocation or false,
		__maximumAllowedSize = 
			(((ctorConfiguration.MaximumAllowedSize :: number) < bufflen(ctorConfiguration.SourceBuffer :: buffer))
			and bufflen(ctorConfiguration.SourceBuffer :: buffer) or ctorConfiguration.MaximumAllowedSize :: number)
			or huge,
		-- Instances data
		__instanceBuffer = {},
		__instanceOffset = 0,
		-- Signals
		__capacityChanged = Signal.new(),
		__offsetChanged = Signal.new(),
		__instanceOffsetChanged = Signal.new(),
	},Bitstream)	
end

--[[
	@TODO: Constructor methods
		.Deserialize
		.Decompress
		.SerializeAll
		.DeserialzeAll
		.SerializeCompressed
		.DeserializeCompressed
		.SerializeAllCompressed
		.DeserializeAllCompressed
]]

--[[
	Serializes a Lua table into a buffer using the provided serialization schema.

	Supports primitive types, arrays, and nested structs.

	Arrays are flattened according to their schema definition before being
	written to the buffer.

	@Parameters:
		- schema : Enumeration.SerializationSchema
		- value : {[string] : any}

	@Returns: buffer
	
	@lastest modification : v4.0
	@since v2.0
	
	TODO: Start the refactorized Serialize
]]
function BitstreamConstructor.Serialize(schema : Enumeration.SerializationSchema,value : {[string] : any})
	
end

-- /// Bitstream methods /// --

--[[
	@TODO: Constructor methods
		.All Writers
		.All Readers
]]

--[[
	When `print` is called instead of showing a table with all data it will return a string.
	i.e. `Bitstream(Size:100)`
]]
function Bitstream.__tostring(self : BitstreamComponent)
	return `Bitstream(Size:{bufflen(self.__buffer)})`
end

--[[
	Using the `#` symbol it will return the current length of the buffer.
]]
function Bitstream.__len(self : BitstreamComponent)
	return bufflen(self.__buffer)
end

--[[
	Using the `+` symbol it will call the `allocate` method.
]]
function Bitstream.__add(self : BitstreamComponent,size : number)
	assert(typeof(size) == "number","Using `+` symbol with Bitstream requires the right argument to be a number")
	return self:allocate(size)
end

--[[
	Using the `*` symbol it will multiply the size of the buffer.
]]
function Bitstream.__mul(self : BitstreamComponent,size : number)
	assert(typeof(size) == "number","Using `*` symbol with Bitstream requires the right argument to be a number")
	size = modf(size)
	if(size <= 1) then 
		error("You can't reduce the size of the buffer manually") 
	end	
	local newBuffer = create(bufflen(self.__buffer) * size)
	copy(newBuffer,0,self.__buffer,bufflen(self.__buffer))
	self.__buffer = newBuffer
	self.__capacityChanged:Fire(bufflen(self.__buffer))
	return self
end

--[[
	Allocates new space to the buffer.
	
	@Parameters: size : number
		The size to allocate in bytes.
	
	@Returns: Bitstream-Component (self)
]]
function Bitstream.allocate(self : BitstreamComponent,size :  number) :  BitstreamComponent
	if(size <= 0) then return self end
	local newBuffer = create(bufflen(self.__buffer) + size)
	copy(newBuffer,0,self.__buffer,0,bufflen(self.__buffer))
	self.__buffer = newBuffer
	self.__capacityChanged:Fire(bufflen(self.__buffer))
	return self
end

-- // Writers // --

--[[
	Write a signed 8-bit integer (-128 to 127).
	
	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeI8(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.I8)
	if(component) then self = (component :: BitstreamComponent) end
	writei8(self.__buffer,self.__offset,value)
	self.__offset += 1
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a signed 16-bit integer (-32_768 to 32_767).
	
	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeI16(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.I16)
	if(component) then self = (component :: BitstreamComponent) end
	writei16(self.__buffer,self.__offset,value)
	self.__offset += 2
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a signed 24-bit integer (-8,388,608 to 8,388,607).
	- Clamped and truncated.
    - 3 bytes, big-endian manual packing.

	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeI24(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	value = clamp(modf(value),Constants.MIN_INT24,Constants.MAX_INT24)
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.I24)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,extract(value,16,8))
	writeu8(self.__buffer,self.__offset + 1,extract(value,8,8))
	writeu8(self.__buffer,self.__offset + 2,extract(value,0,8))
	self.__offset += 3
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a signed 32-bit integer (-2,147,483,648 to 2,147,483,647).
	
	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeI32(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.I32)
	if(component) then self = (component :: BitstreamComponent) end
	writei32(self.__buffer,self.__offset,value)
	self.__offset += 4
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a signed 40-bit integer (-549,755,813,888 to 549,755,813,887).
    - Clamped and truncated.
    - If negative, add 2^40 to represent as unsigned (two's complement style) before writing.
    - 5 bytes, big-endian manual packing.

	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeI40(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	value = clamp(modf(value),Constants.MIN_INT40,Constants.MAX_INT40)
	if(value < 0) then
		-- Convert negative to unsigned representation over 40 bits (two's complement range)
		value += fbit40
	end
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.I40)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,floor(value / fbit32) % fbit8)
	writeu8(self.__buffer,self.__offset + 1,extract(value % fbit32,24,8))
	writeu8(self.__buffer,self.__offset + 2,extract(value % fbit32,16,8))
	writeu8(self.__buffer,self.__offset + 3,extract(value % fbit32,8,8))
	writeu8(self.__buffer,self.__offset + 4,extract(value % fbit32,0,8))
	self.__offset += 5
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a signed 48-bit integer (-140,737,488,355,328 to 140,737,488,355,327).
    - Clamped and truncated.
    - If negative, add 2^48 to represent as unsigned before writing.
    - 6 bytes, big-endian manual packing.	
    
	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeI48(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	value = clamp(modf(value),Constants.MIN_INT48,Constants.MAX_INT48)
	if(value < 0) then 
		-- Represent as 48-bit unsigned for storage
		value += fbit48
	end
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.I48)
	if(component) then self = (component :: BitstreamComponent) end
	-- Big-endian packing: 6 bytes MSB -> LSB
	writeu8(self.__buffer,self.__offset,floor(value / fbit40) % fbit8)
	writeu8(self.__buffer,self.__offset + 1,floor(value / fbit32) % fbit8)
	writeu8(self.__buffer,self.__offset + 2,extract(value % fbit32,24,8))
	writeu8(self.__buffer,self.__offset + 3,extract(value % fbit32,16,8))
	writeu8(self.__buffer,self.__offset + 4,extract(value % fbit32,8,8))
	writeu8(self.__buffer,self.__offset + 5,extract(value % fbit32,0,8))
	self.__offset += 6
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a signed 54-bit integer (-9,007,199,254,740,992 to 9,007,199,254,740,991).
    - Clamped and truncated.
    - If negative, add 2^54 to represent as unsigned before writing.
    - 7 bytes, big-endian manual packing.
    
	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeI54(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	value = clamp(modf(value),Constants.MIN_INT54,Constants.MAX_INT54)
	if(value < 0) then 
		-- Represent as 54-bit unsigned for storage
		value += fbit54
	end
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.I54)
	if(component) then self = (component :: BitstreamComponent) end
	-- Big-endian packing: 7 bytes MSB -> LSB
	writeu8(self.__buffer,self.__offset,floor(value / fbit48) % fbit8)
	writeu8(self.__buffer,self.__offset + 1,floor(value / fbit40) % fbit8)
	writeu8(self.__buffer,self.__offset + 2,floor(value / fbit32) % fbit8)
	writeu8(self.__buffer,self.__offset + 3,extract(value % fbit32,24,8))
	writeu8(self.__buffer,self.__offset + 4,extract(value % fbit32,16,8))
	writeu8(self.__buffer,self.__offset + 5,extract(value % fbit32,8,8))
	writeu8(self.__buffer,self.__offset + 6,extract(value % fbit32,0,8))
	self.__offset += 7
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a single unsigned bit (0 or 1).
    - Reserves 1 byte (by design)

	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.3
]]
function Bitstream.writeU1(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.U1)
	if(component) then self = (component :: BitstreamComponent) end
	writebits(self.__buffer,self.__offset * 8,1,(value > 1) and 1 or 0)
	self.__offset += 1
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write an unsigned 8-bit integer (0 to 255).
    
	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeU8(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.U8)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,value)
	self.__offset += 1
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write an unsigned 16-bit integer (0 to 65,535).
    
	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeU16(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.U16)
	if(component) then self = (component :: BitstreamComponent) end
	writeu16(self.__buffer,self.__offset,value)
	self.__offset += 2
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write an unsigned 24-bit integer (0 to 16,777,215).
    - Clamped and truncated.
    - 3 bytes, big-endian manual packing.

	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeU24(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	value = clamp(modf(value),Constants.MIN_UINT,Constants.MAX_UINT24)
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.U24)
	if(component) then self = (component :: BitstreamComponent) end
	-- Big-endian manual packing
	writeu8(self.__buffer,self.__offset,extract(value,16,8))
	writeu8(self.__buffer,self.__offset + 1,extract(value,8,8))
	writeu8(self.__buffer,self.__offset + 2,extract(value,0,8))
	self.__offset += 3
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write an unsigned 32-bit integer (0 to 4,294,967,295).

	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeU32(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.U32)
	if(component) then self = (component :: BitstreamComponent) end
	writeu32(self.__buffer,self.__offset,value)
	self.__offset += 4
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write an unsigned 40-bit integer (0 to 1,099,511,627,775).

	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeU40(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	value = clamp(modf(value),Constants.MIN_UINT,Constants.MAX_UINT40)
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.U40)
	if(component) then self = (component :: BitstreamComponent) end
	-- Big-endian manual packing
	local remainder = value % fbit32
	writeu8(self.__buffer,self.__offset,floor(value / fbit32) % fbit8)
	writeu8(self.__buffer,self.__offset + 1,extract(remainder,24,8))
	writeu8(self.__buffer,self.__offset + 2,extract(remainder,16,8))
	writeu8(self.__buffer,self.__offset + 3,extract(remainder,8,8))
	writeu8(self.__buffer,self.__offset + 4,extract(remainder,0,8))
	self.__offset += 5
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write an unsigned 48-bit integer (0 to 281,474,976,710,655).
    - Clamped and truncated.
    - 6 bytes, big-endian manual packing.
    
	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeU48(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	value = clamp(modf(value),Constants.MIN_UINT,Constants.MAX_UINT48)
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.U48)
	if(component) then self = (component :: BitstreamComponent) end
	-- Big-endian packing: 6 bytes MSB -> LSB
	writeu8(self.__buffer,self.__offset,floor(value / fbit40) % fbit8)
	writeu8(self.__buffer,self.__offset + 1,floor(value / fbit32) % fbit8)
	writeu8(self.__buffer,self.__offset + 2,extract(value % fbit32,24,8))
	writeu8(self.__buffer,self.__offset + 3,extract(value % fbit32,16,8))
	writeu8(self.__buffer,self.__offset + 4,extract(value % fbit32,8,8))
	writeu8(self.__buffer,self.__offset + 5,extract(value % fbit32,0,8))
	self.__offset += 6
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write an unsigned 54-bit integer (0 to 18,014,398,509,481,980).
    - Clamped and truncated.
    - 7 bytes, big-endian manual packing.
    
	@Parameter(s): number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeU54(self : BitstreamComponent,value : number) : BitstreamComponent 
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	value = clamp(modf(value),Constants.MIN_UINT,Constants.MAX_UINT54)
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.U54)
	if(component) then self = (component :: BitstreamComponent) end
	-- Big-endian packing: 7 bytes MSB -> LSB
	writeu8(self.__buffer,self.__offset,floor(value / fbit48) % fbit8) 
	writeu8(self.__buffer,self.__offset + 1,floor(value / fbit40) % fbit8)
	writeu8(self.__buffer,self.__offset + 2,floor(value / fbit32) % fbit8)
	writeu8(self.__buffer,self.__offset + 3,extract(value % fbit32,24,8))
	writeu8(self.__buffer,self.__offset + 4,extract(value % fbit32,16,8))
	writeu8(self.__buffer,self.__offset + 5,extract(value % fbit32,8,8))
	writeu8(self.__buffer,self.__offset + 6,extract(value % fbit32,0,8))
	self.__offset += 7
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write an unsigned `N-bit` integer.
    - Clamped and truncated.
    - min[U1] - max[U54] 
    
	@Parameter(s): number, number
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeUInt(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const bytesData = Utilities.GetEquivalentBytesInfoFromNumber(value)
	value = clamp(modf(value),Constants.MIN_UINT,Constants["MAX_UINT"..bytesData.bytes * 8])
	self["writeU"..bytesData.bytes * 8](self,value)
	return self
end

--[[
    Write a 16-bit float (half-precision) to the buffer.
    - Lower precision than F32/F64; expect rounding.
    - NaN/Inf are handled; finite values are encoded with sign/exponent/mantissa.
    
    @Parameter(s): number, number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeF16(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.F16)
	if(component) then self = (component :: BitstreamComponent) end
	local uint16,sign,mantissa,exponent = Extensions.toFloat16(value);
	writeu16(self.__buffer,self.__offset,uint16)
	self.__offset += 2
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a 32-bit float to the buffer.
    - 4 bytes, big-endian.
    - The default float format.
    
    @Parameter(s): number, number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeF32(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.F32)
	if(component) then self = (component :: BitstreamComponent) end
	writef32(self.__buffer,self.__offset,value)
	self.__offset += 4
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a 64-bit float to the buffer.
    - 8 bytes, big-endian.
    - The default float format.
    
    @Parameter(s): number, number
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeF64(self : BitstreamComponent,value : number) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "number","Type-missmatch",{
		Debugger.getFunctionName(),
		"number"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.F64)
	if(component) then self = (component :: BitstreamComponent) end
	writef64(self.__buffer,self.__offset,value)
	self.__offset += 8
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a string without caring about length limits.
    - Writes exactly #value bytes.
    - Reader must know or infer the length (no prefix is written).
    
	@Parameter(s): string
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeString(self : BitstreamComponent,value : string) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "string","Type-missmatch",{
		Debugger.getFunctionName(),
		"string"
	})
	const length = strlen(value)
	const result,component = ensureWritable(self,length)
	if(component) then self = (component :: BitstreamComponent) end
	writestring(self.__buffer,self.__offset,value,length)
	self.__offset += length
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a string without caring about length limits.
    - Writes exactly byte-code + len + #value bytes. (1 + n[(1-7)bytes] + #value)
    
	@Parameter(s): string
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writePrefixedString(self : BitstreamComponent,value : string) : BitstreamComponent
	Debugger.handleAssert(typeof(value) == "string","Type-missmatch",{
		Debugger.getFunctionName(),
		"string"
	})
	const length = strlen(value)
	const bytesData = Utilities.GetEquivalentBytesInfoFromNumber(length)
	
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.PrefixedString(value))
	if(component) then self = (component :: BitstreamComponent) end
	
	self:writeU8(Enumeration.__enum["U"..bytesData.bytes * 8].Value)
	self:writeUInt(length)
	self:writeString(value)
	return self
end

--[[
    Write a single boolean using 1 bit.
    - nil/false -> 0, anything else -> 1
    
	@Parameter(s): any
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeBool1(self : BitstreamComponent,value : any) : BitstreamComponent
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Bool1)
	if(component) then self = (component :: BitstreamComponent) end
	writebits(self.__buffer,self.__offset * 8,1,if(value) then 1 else 0)
	self.__offset += 1
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write 8 booleans packed into 1 byte.
    - Accepts an array-like table of up to 8 values.
    - Each truthy value sets the corresponding bit to 1.
    
	@Parameter(s): {any}
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeBool8(self : BitstreamComponent,values : {any}) : BitstreamComponent
	Debugger.handleAssert(typeof(values) == "table","Type-missmatch",{
		Debugger.getFunctionName(),
		"table"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Bool8)
	if(component) then self = (component :: BitstreamComponent) end
	for i = 1,8 do
		writebits(self.__buffer,(self.__offset * 8 + i - 1),1,if(values[i]) then 1 else 0)
	end
	self.__offset += 1
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a Vector2 as two f32 (x, y).
    - 8 bytes total.
    
	@Parameter(s): Vector2
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeVector2float32(self : BitstreamComponent,value : Vector2)
	Debugger.handleAssert(typeof(value) == "Vector2","Type-missmatch",{
		Debugger.getFunctionName(),
		"Vector2"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Vector2float32)
	if(component) then self = (component :: BitstreamComponent) end
	writef32(self.__buffer,self.__offset,value.X)
	writef32(self.__buffer,self.__offset + 4,value.Y)
	self.__offset += 8
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a Vector2int16 as two i16 (x, y).
    - 4 bytes total.
    
	@Parameter(s): Vector2int16
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeVector2int16(self : BitstreamComponent,value : Vector2int16)
	Debugger.handleAssert(typeof(value) == "Vector2int16","Type-missmatch",{
		Debugger.getFunctionName(),
		"Vector2int16"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Vector2int16)
	if(component) then self = (component :: BitstreamComponent) end
	writei16(self.__buffer,self.__offset,value.X)
	writei16(self.__buffer,self.__offset + 2,value.Y)
	self.__offset += 4
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a Vector2uint16 as two u16 (x, y).
    - 4 bytes total.
    
	@Parameter(s): Vector2
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeVector2uint16(self : BitstreamComponent,value : Vector2)
	Debugger.handleAssert(typeof(value) == "Vector2","Type-missmatch",{
		Debugger.getFunctionName(),
		"Vector2"
	})
	local x,y = 
		clamp(modf(abs(value.X)),Constants.MIN_UINT,Constants.MAX_UINT16),
		clamp(modf(abs(value.Y)),Constants.MIN_UINT,Constants.MAX_UINT16)
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Vector2uint16)
	if(component) then self = (component :: BitstreamComponent) end
	writeu16(self.__buffer,self.__offset,x)
	writeu16(self.__buffer,self.__offset + 2,y)
	self.__offset += 4
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a Vector2 as two f64 (x, y).
    - 16 bytes total.
    
	@Parameter(s): Vector2
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeVector2(self : BitstreamComponent,value : Vector2)
	Debugger.handleAssert(typeof(value) == "Vector2","Type-missmatch",{
		Debugger.getFunctionName(),
		"Vector2"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Vector2)
	if(component) then self = (component :: BitstreamComponent) end
	writef64(self.__buffer,self.__offset,value.X)
	writef64(self.__buffer,self.__offset + 8,value.Y)
	self.__offset += 16
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a Vector3 as three f32 (x, y, z).
    - 12 bytes total.
    
	@Parameter(s): Vector3
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeVector3float32(self : BitstreamComponent,value : Vector3)
	Debugger.handleAssert(typeof(value) == "Vector3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Vector3"
	})
	local x,y,z = value.X,value.Y,value.Z
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Vector3float32)
	if(component) then self = (component :: BitstreamComponent) end
	writef32(self.__buffer,self.__offset,x)
	writef32(self.__buffer,self.__offset + 4,y)
	writef32(self.__buffer,self.__offset + 8,z)
	self.__offset += 12
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a Vector3int16 as three i16 (x, y, z).
    - 6 bytes total.
    
	@Parameter(s): Vector3int16
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeVector3int16(self : BitstreamComponent,value : Vector3int16)
	Debugger.handleAssert(typeof(value) == "Vector3int16","Type-missmatch",{
		Debugger.getFunctionName(),
		"Vector3int16"
	})
	local x,y,z = value.X,value.Y,value.Z
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Vector3int16)
	if(component) then self = (component :: BitstreamComponent) end
	writei16(self.__buffer,self.__offset,x)
	writei16(self.__buffer,self.__offset + 2,y)
	writei16(self.__buffer,self.__offset + 4,z)
	self.__offset += 6
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a Vector3uint16 as three u16 (x, y, z).
    - 6 bytes total.
    
	@Parameter(s): Vector3
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeVector3uint16(self : BitstreamComponent,value : Vector3)
	Debugger.handleAssert(typeof(value) == "Vector3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Vector3"
	})
	local x,y,z = 
		clamp(modf(abs(value.X)),Constants.MIN_UINT,Constants.MAX_UINT16),
		clamp(modf(abs(value.Y)),Constants.MIN_UINT,Constants.MAX_UINT16),
		clamp(modf(abs(value.Z)),Constants.MIN_UINT,Constants.MAX_UINT16)
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Vector3uint16)
	if(component) then self = (component :: BitstreamComponent) end
	writeu16(self.__buffer,self.__offset,x)
	writeu16(self.__buffer,self.__offset + 2,y)
	writeu16(self.__buffer,self.__offset + 4,z)
	self.__offset += 6
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a Vector3 as three f64 (x, y, z).
    - 24 bytes total.
    
    @Parameter(s): Vector3
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeVector3(self : BitstreamComponent,value : Vector3)
	Debugger.handleAssert(typeof(value) == "Vector3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Vector3"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Vector3)
	if(component) then self = (component :: BitstreamComponent) end
	writef64(self.__buffer,self.__offset,value.X)
	writef64(self.__buffer,self.__offset + 8,value.Y)
	writef64(self.__buffer,self.__offset + 16,value.Z)
	self.__offset += 24
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
    Write a CFrame converted into a quaternion.
    - 28 bytes total.
    - Write position first and then turn the axis angle to a quaternion and write it to the buffer.
    
    @Parameter(s): CFrame
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeCFrameQuaternion(self : BitstreamComponent,value : CFrame)
	Debugger.handleAssert(typeof(value) == "CFrame","Type-missmatch",{
		Debugger.getFunctionName(),
		"CFrame"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.CFrameQuaternion)
	if(component) then self = (component :: BitstreamComponent) end
	local pos = value.Position
	local axis,angle = value:ToAxisAngle()
	-- Write position first
	writef32(self.__buffer,self.__offset,pos.X)
	writef32(self.__buffer,self.__offset + 4,pos.Y)
	writef32(self.__buffer,self.__offset + 8,pos.Z)
	-- Write quaternion
	local quaternion = Extensions.axisAngleToQuaternion(axis,angle)
	writef32(self.__buffer,self.__offset + 12,quaternion.x)
	writef32(self.__buffer,self.__offset + 16,quaternion.y)
	writef32(self.__buffer,self.__offset + 20,quaternion.z)
	writef32(self.__buffer,self.__offset + 24,quaternion.w)
	self.__offset += 28
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a CFrame to the buffer using float32.
	- 24 bytes total.
	- Convert the CFrame to Euler angles and write them to the buffer.
	
	@Parameter(s): CFrame
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeCFrameF32(self : BitstreamComponent,value : CFrame)
	Debugger.handleAssert(typeof(value) == "CFrame","Type-missmatch",{
		Debugger.getFunctionName(),
		"CFrame"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.CFrameF32)
	if(component) then self = (component :: BitstreamComponent) end
	local pos = value.Position
	local rx,ry,rz = value:ToEulerAnglesXYZ()
	writef32(self.__buffer,self.__offset,pos.X)
	writef32(self.__buffer,self.__offset + 4,pos.Y)
	writef32(self.__buffer,self.__offset + 8,pos.Z)
	writef32(self.__buffer,self.__offset + 12,rx)
	writef32(self.__buffer,self.__offset + 16,ry)
	writef32(self.__buffer,self.__offset + 20,rz)
	self.__offset += 24
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Writes a quantized CFrame to the buffer using 12 bytes (16-bit integers)
	
	Memory layout (12 bytes total):
	- Position X, Y, Z: 3 × i16 (6 bytes) - Precision: 1mm, Range: ±32km
	- Rotation X, Y, Z: 3 × i16 (6 bytes) - Precision: ~0.05°, Range: ±π radians
	
	Quantization scales:
	- POSITION_SCALE = 1000 (converts meters to millimeters)
	- ROTATION_SCALE = 10430.38 (32767/π for optimal angle precision)
	
	@Parameter(s): CFrame
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeCFrameQuantized(self : BitstreamComponent,value : CFrame)
	Debugger.handleAssert(typeof(value) == "CFrame","Type-missmatch",{
		Debugger.getFunctionName(),
		"CFrame"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.CFrameQuantized)
	if(component) then self = (component :: BitstreamComponent) end
	local pos = value.Position
	local rx,ry,rz = value:ToEulerAnglesXYZ()
	writei16(self.__buffer,self.__offset,clamp(round(pos.X * POSITION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 2,clamp(round(pos.Y * POSITION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 4,clamp(round(pos.Z * POSITION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 6,clamp(round(rx * ROTATION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 8,clamp(round(ry * ROTATION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 10,clamp(round(rz * ROTATION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	self.__offset += 12
	self.__offsetChanged:Fire(self.__offset)
	return self
end


--[[
	Write a CFrame to the buffer using float64.
	- 48 bytes total.
	- Convert the CFrame to Euler angles and write them to the buffer.
	
	@Parameter(s): CFrame
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeCFrameF64(self : BitstreamComponent,value : CFrame)
	Debugger.handleAssert(typeof(value) == "CFrame","Type-missmatch",{
		Debugger.getFunctionName(),
		"CFrame"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.CFrameF64)
	if(component) then self = (component :: BitstreamComponent) end
	local pos = value.Position
	local rx,ry,rz = value:ToEulerAnglesXYZ()
	writef64(self.__buffer,self.__offset,pos.X)
	writef64(self.__buffer,self.__offset + 8,pos.Y)
	writef64(self.__buffer,self.__offset + 16,pos.Z)
	writef64(self.__buffer,self.__offset + 24,rx)
	writef64(self.__buffer,self.__offset + 32,ry)
	writef64(self.__buffer,self.__offset + 40,rz)
	self.__offset += 48
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a UDim to the buffer.
	- 8 bytes total.
	- Scale use f32, Offset use i32.
	
	@Parameter(s): UDim
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeUDim(self : BitstreamComponent,value : UDim)
	Debugger.handleAssert(typeof(value) == "UDim","Type-missmatch",{
		Debugger.getFunctionName(),
		"UDim"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.UDim)
	if(component) then self = (component :: BitstreamComponent) end
	writef32(self.__buffer,self.__offset,value.Scale)
	writei32(self.__buffer,self.__offset + 4,value.Offset)
	self.__offset += 8
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a UDim2 to the buffer.
	- 16 bytes total.
	- Scales use f32, Offsets use i32.
	
	@Parameter(s): UDim2
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeUDim2(self : BitstreamComponent,value : UDim2)
	Debugger.handleAssert(typeof(value) == "UDim2","Type-missmatch",{
		Debugger.getFunctionName(),
		"UDim2"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.UDim2)
	if(component) then self = (component :: BitstreamComponent) end
	writef32(self.__buffer,self.__offset,value.X.Scale)
	writei32(self.__buffer,self.__offset + 4,value.X.Offset)
	writef32(self.__buffer,self.__offset + 8,value.Y.Scale)
	writei32(self.__buffer,self.__offset + 12,value.Y.Offset)
	self.__offset += 16
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Color3 to the buffer.
	- 3 bytes total.
	- Each component is stored as an unsigned 8-bit integer.
	
	@Parameter(s): Color3
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeColor3(self : BitstreamComponent,value : Color3)
	Debugger.handleAssert(typeof(value) == "Color3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Color3"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Color3)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,round(value.R * 255))
	writeu8(self.__buffer,self.__offset + 1,round(value.G * 255))
	writeu8(self.__buffer,self.__offset + 2,round(value.B * 255))
	self.__offset += 3
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Color3 to the buffer.
	- 12 bytes total.
	- Each component is stored as an 32-bit float.
	
	@Parameter(s): Color3
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeColor3F32(self : BitstreamComponent,value : Color3)
	Debugger.handleAssert(typeof(value) == "Color3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Color3"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Color3F32)
	if(component) then self = (component :: BitstreamComponent) end
	writef32(self.__buffer,self.__offset,value.R)
	writef32(self.__buffer,self.__offset + 4,value.G)
	writef32(self.__buffer,self.__offset + 8,value.B)
	self.__offset += 12
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Color3 to the buffer.
	- 24 bytes total.
	- Each component is stored as an 64-bit float.
	
	@Parameter(s): Color3
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeColor3F64(self : BitstreamComponent,value : Color3)
	Debugger.handleAssert(typeof(value) == "Color3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Color3"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Color3F64)
	if(component) then self = (component :: BitstreamComponent) end
	writef64(self.__buffer,self.__offset,value.R)
	writef64(self.__buffer,self.__offset + 8,value.G)
	writef64(self.__buffer,self.__offset + 16,value.B)
	self.__offset += 24
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Rect(Float32) to the buffer.
	- 16 bytes total.
	
	@Parameter(s): Rect
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeRectFloat32(self : BitstreamComponent,value : Rect)
	Debugger.handleAssert(typeof(value) == "Rect","Type-missmatch",{
		Debugger.getFunctionName(),
		"Rect"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.RectFloat32)
	if(component) then self = (component :: BitstreamComponent) end
	writef32(self.__buffer,self.__offset,value.Min.X)
	writef32(self.__buffer,self.__offset + 4,value.Min.Y)
	writef32(self.__buffer,self.__offset + 8,value.Max.X)
	writef32(self.__buffer,self.__offset + 12,value.Max.Y)
	self.__offset += 16
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Rect to the buffer. (Use f64)
	- 32 bytes total.
	
	@Parameter(s): Rect
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeRect(self : BitstreamComponent,value : Rect)
	Debugger.handleAssert(typeof(value) == "Rect","Type-missmatch",{
		Debugger.getFunctionName(),
		"Rect"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Rect)
	if(component) then self = (component :: BitstreamComponent) end
	writef64(self.__buffer,self.__offset,value.Min.X)
	writef64(self.__buffer,self.__offset + 8,value.Min.Y)
	writef64(self.__buffer,self.__offset + 16,value.Max.X)
	writef64(self.__buffer,self.__offset + 24,value.Max.Y)
	self.__offset += 32
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Region3 to the buffer. (Use f64 for CFrame and Size)
	- 72 bytes total.
	
	@Parameter(s): Region3
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeRegion3(self : BitstreamComponent,value : Region3)
	Debugger.handleAssert(typeof(value) == "Region3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Region3"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Region3)
	if(component) then self = (component :: BitstreamComponent) end
	local size,cf = value.Size,value.CFrame
	local pos = cf.Position
	local rx,ry,rz = cf:ToEulerAnglesXYZ()
	-- Write CFrame first
	writef64(self.__buffer,self.__offset,pos.X)
	writef64(self.__buffer,self.__offset + 8,pos.Y)
	writef64(self.__buffer,self.__offset + 16,pos.Z)
	writef64(self.__buffer,self.__offset + 24,rx)
	writef64(self.__buffer,self.__offset + 32,ry)
	writef64(self.__buffer,self.__offset + 40,rz)
	-- Write Size
	writef64(self.__buffer,self.__offset + 48,size.X)
	writef64(self.__buffer,self.__offset + 56,size.Y)
	writef64(self.__buffer,self.__offset + 64,size.Z)
	self.__offset += 72
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Region3 to the buffer.
	- 52 bytes total.
	- CFrame is converted to quaternion.
	
	@Parameter(s): Region3
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeRegion3Quaternion(self : BitstreamComponent,value : Region3)
	Debugger.handleAssert(typeof(value) == "Region3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Region3"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Region3Quaternion)
	if(component) then self = (component :: BitstreamComponent) end
	local size,cf = value.Size,value.CFrame
	local pos = cf.Position
	local axis,angle = cf:ToAxisAngle()
	-- Write CFrame first
	writef32(self.__buffer,self.__offset,pos.X)
	writef32(self.__buffer,self.__offset + 4,pos.Y)
	writef32(self.__buffer,self.__offset + 8,pos.Z)
	local quaternion = Extensions.axisAngleToQuaternion(axis,angle)
	writef32(self.__buffer,self.__offset + 12,quaternion.x)
	writef32(self.__buffer,self.__offset + 16,quaternion.y)
	writef32(self.__buffer,self.__offset + 20,quaternion.z)
	writef32(self.__buffer,self.__offset + 24,quaternion.w)
	-- Write Size
	writef64(self.__buffer,self.__offset + 28,size.X)
	writef64(self.__buffer,self.__offset + 36,size.Y)
	writef64(self.__buffer,self.__offset + 44,size.Z)
	self.__offset += 52
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Region3 to the buffer. (Use f32 for CFrame but use f64 for the Size)
	- 48 bytes total.
	
	@Parameter(s): Region3
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeRegion3CFrameF32(self : BitstreamComponent,value : Region3)
	Debugger.handleAssert(typeof(value) == "Region3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Region3"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Region3CFrameF32)
	if(component) then self = (component :: BitstreamComponent) end
	local size,cf = value.Size,value.CFrame
	local pos = cf.Position
	local rx,ry,rz = cf:ToEulerAnglesXYZ()
	-- Write CFrame first
	writef32(self.__buffer,self.__offset,pos.X)
	writef32(self.__buffer,self.__offset + 4,pos.Y)
	writef32(self.__buffer,self.__offset + 8,pos.Z)
	writef32(self.__buffer,self.__offset + 12,rx)
	writef32(self.__buffer,self.__offset + 16,ry)
	writef32(self.__buffer,self.__offset + 20,rz)
	-- Write Size
	writef64(self.__buffer,self.__offset + 24,size.X)
	writef64(self.__buffer,self.__offset + 32,size.Y)
	writef64(self.__buffer,self.__offset + 40,size.Z)
	self.__offset += 48
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Region3int16 to the buffer.
	
	@Parameter(s): Region3int16
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeRegion3int16(self : BitstreamComponent,value : Region3int16)
	Debugger.handleAssert(typeof(value) == "Region3int16","Type-missmatch",{
		Debugger.getFunctionName(),
		"Region3int16"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Region3int16)
	if(component) then self = (component :: BitstreamComponent) end
	local min,max = value.Min,value.Max
	-- Write Min
	writei16(self.__buffer,self.__offset,min.X)
	writei16(self.__buffer,self.__offset + 2,min.Y)
	writei16(self.__buffer,self.__offset + 4,min.Z)
	-- Write Max
	writei16(self.__buffer,self.__offset + 6,max.X)
	writei16(self.__buffer,self.__offset + 8,max.Y)
	writei16(self.__buffer,self.__offset + 10,max.Z)
	self.__offset += 12
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Region3 to the buffer.
	- 36 bytes total.
	- CFrame will be quantized to this format : 
		Position : 16-bit signed integers, quantized (1/1000)
		Rotation : 16-bit signed integers, quantized (~0.0055°)
	- Size still use (f64)
	
	@Parameter(s): Region3
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeRegion3Quantized(self : BitstreamComponent,value : Region3)
	Debugger.handleAssert(typeof(value) == "Region3","Type-missmatch",{
		Debugger.getFunctionName(),
		"Region3"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Region3Quantized)
	if(component) then self = (component :: BitstreamComponent) end
	local size,cf = value.Size,value.CFrame
	local pos = cf.Position
	local rx,ry,rz = cf:ToEulerAnglesXYZ()
	-- Write Quantized-CFrame first
	writei16(self.__buffer,self.__offset,clamp(round(pos.X * POSITION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 2,clamp(round(pos.Y * POSITION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 4,clamp(round(pos.Z * POSITION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 6,clamp(round(rx * ROTATION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 8,clamp(round(ry * ROTATION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 10,clamp(round(rz * ROTATION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))	
	-- Write Size
	writef64(self.__buffer,self.__offset + 12,size.X)
	writef64(self.__buffer,self.__offset + 20,size.Y)
	writef64(self.__buffer,self.__offset + 28,size.Z)
	self.__offset += 36
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a Enum to the buffer.
	- 2 bytes total.
	
	@Parameter(s): EnumItem
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeEnum(self : BitstreamComponent,value : EnumItem)
	Debugger.handleAssert(typeof(value) == "EnumItem","Type-missmatch",{
		Debugger.getFunctionName(),
		"EnumItem"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.Enum)
	if(component) then self = (component :: BitstreamComponent) end
	local id = Constants.EnumItemIndex[value]
	writeu16(self.__buffer,self.__offset,id)
	self.__offset += 2
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a RotationCurveKey to the buffer.
	- 54 bytes or 62 bytes total.
		- 54 bytes for Non-Cubic interpolation-mode.
		- 62 bytes for Cubic interpolation-mode.
		
	@Parameter(s): RotationCurveKey
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeRotationCurveKey(self : BitstreamComponent,value : RotationCurveKey)
	Debugger.handleAssert(typeof(value) == "RotationCurveKey","Type-missmatch",{
		Debugger.getFunctionName(),
		"RotationCurveKey"
	})
	const bytes = Constants.REQUIRED_BYTES.RotationCurveKey(value,"Normal")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	local id = Constants.EnumItemIndex[value.Interpolation]
	local pos = value.Value.Position
	local rx,ry,rz = value.Value:ToEulerAnglesXYZ()
	-- Write Time
	writef32(self.__buffer, self.__offset, value.Time)
	-- Write CFrame
	writef64(self.__buffer, self.__offset + 4,  pos.X)
	writef64(self.__buffer, self.__offset + 12, pos.Y)
	writef64(self.__buffer, self.__offset + 20, pos.Z)
	writef64(self.__buffer, self.__offset + 28, rx)
	writef64(self.__buffer, self.__offset + 36, ry)
	writef64(self.__buffer, self.__offset + 44, rz)
	-- Write Enum Id
	writeu16(self.__buffer, self.__offset + 52, id)
	-- Write Tangents if is Cubic
	if value.Interpolation == Enum.KeyInterpolationMode.Cubic then
		if(not value.LeftTangent) then value.LeftTangent = 0 end
		if(not value.RightTangent) then value.RightTangent = 0 end
		local left, right = value.LeftTangent, value.RightTangent
		writef32(self.__buffer, self.__offset + 54, left)
		writef32(self.__buffer, self.__offset + 58, right)
	end
	self.__offset += bytes
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a RotationCurveKey to the buffer.
	- 42 bytes or 34 bytes total.
		- 34 bytes for Non-Cubic interpolation-mode.
		- 42 bytes for Cubic interpolation-mode.
	- CFrame is converted to a quaternion.
		
	@Parameter(s): RotationCurveKey
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeRotationCurveKeyQuaternion(self : BitstreamComponent,value : RotationCurveKey)
	Debugger.handleAssert(typeof(value) == "RotationCurveKey","Type-missmatch",{
		Debugger.getFunctionName(),
		"RotationCurveKey"
	})
	const bytes = Constants.REQUIRED_BYTES.RotationCurveKey(value,"Quaternion")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	local id = Constants.EnumItemIndex[value.Interpolation]
	local pos = value.Value.Position
	local axis,angle = value.Value:ToAxisAngle()
	-- Write Time
	writef32(self.__buffer, self.__offset, value.Time)
	-- Write CFrame
	writef32(self.__buffer,self.__offset + 4,pos.X)
	writef32(self.__buffer,self.__offset + 8,pos.Y)
	writef32(self.__buffer,self.__offset + 12,pos.Z)
	local quaternion = Extensions.axisAngleToQuaternion(axis,angle)
	writef32(self.__buffer,self.__offset + 16,quaternion.x)
	writef32(self.__buffer,self.__offset + 20,quaternion.y)
	writef32(self.__buffer,self.__offset + 24,quaternion.z)
	writef32(self.__buffer,self.__offset + 28,quaternion.w)
	-- Write Enum Id
	writeu16(self.__buffer, self.__offset + 32, id)
	-- Write Tangents if is Cubic
	if value.Interpolation == Enum.KeyInterpolationMode.Cubic then
		if(not value.LeftTangent) then value.LeftTangent = 0 end
		if(not value.RightTangent) then value.RightTangent = 0 end
		local left, right = value.LeftTangent, value.RightTangent
		writef32(self.__buffer, self.__offset + 34, left)
		writef32(self.__buffer, self.__offset + 38, right)
	end
	self.__offset += bytes
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a RotationCurveKey to the buffer.
	- 30 bytes or 38 bytes total.
		- 30 bytes for Non-Cubic interpolation-mode.
		- 38 bytes for Cubic interpolation-mode.
	- Everything is written using f32 (but always u16 for the enumItem).
		
	@Parameter(s): RotationCurveKey
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeRotationCurveKeyCFrameF32(self : BitstreamComponent,value : RotationCurveKey)
	Debugger.handleAssert(typeof(value) == "RotationCurveKey","Type-missmatch",{
		Debugger.getFunctionName(),
		"RotationCurveKey"
	})
	const bytes = Constants.REQUIRED_BYTES.RotationCurveKey(value,"CFrameF32")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	local id = Constants.EnumItemIndex[value.Interpolation]
	local pos = value.Value.Position
	local rx,ry,rz = value.Value:ToEulerAnglesXYZ()
	-- Write Time
	writef32(self.__buffer, self.__offset, value.Time)
	-- Write CFrame
	writef32(self.__buffer,self.__offset + 4,pos.X)
	writef32(self.__buffer,self.__offset + 8,pos.Y)
	writef32(self.__buffer,self.__offset + 12,pos.Z)
	writef32(self.__buffer,self.__offset + 16,rx)
	writef32(self.__buffer,self.__offset + 20,ry)
	writef32(self.__buffer,self.__offset + 24,rz)
	-- Write Enum Id
	writeu16(self.__buffer, self.__offset + 28, id)
	-- Write Tangents if is Cubic
	if value.Interpolation == Enum.KeyInterpolationMode.Cubic then
		if(not value.LeftTangent) then value.LeftTangent = 0 end
		if(not value.RightTangent) then value.RightTangent = 0 end
		local left, right = value.LeftTangent, value.RightTangent
		writef32(self.__buffer, self.__offset + 30, left)
		writef32(self.__buffer, self.__offset + 34, right)
	end
	self.__offset += bytes
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a RotationCurveKey to the buffer.
	- 18 bytes or 26 bytes total.
		- 18 bytes for Non-Cubic interpolation-mode.
		- 26 bytes for Cubic interpolation-mode.
	- CFrame will be quantized to this format : 
		Position : 16-bit signed integers, quantized (1/1000)
		Rotation : 16-bit signed integers, quantized (~0.0055°) 
		
	@Parameter(s): RotationCurveKey
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeRotationCurveKeyQuantized(self : BitstreamComponent,value : RotationCurveKey)
	Debugger.handleAssert(typeof(value) == "RotationCurveKey","Type-missmatch",{
		Debugger.getFunctionName(),
		"RotationCurveKey"
	})
	const bytes = Constants.REQUIRED_BYTES.RotationCurveKey(value,"Quantized")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	local id = Constants.EnumItemIndex[value.Interpolation]
	local pos = value.Value.Position
	local rx,ry,rz = value.Value:ToEulerAnglesXYZ()
	-- Write Time
	writef32(self.__buffer, self.__offset, value.Time)
	-- Write CFrame (Quantized)
	writei16(self.__buffer,self.__offset + 4,clamp(round(pos.X * POSITION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 6,clamp(round(pos.Y * POSITION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 8,clamp(round(pos.Z * POSITION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 10,clamp(round(rx * ROTATION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 12,clamp(round(ry * ROTATION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	writei16(self.__buffer,self.__offset + 14,clamp(round(rz * ROTATION_SCALE),Constants.MIN_INT16,Constants.MAX_INT16))
	-- Write Enum Id
	writeu16(self.__buffer, self.__offset + 16, id)
	-- Write Tangents if is Cubic
	if value.Interpolation == Enum.KeyInterpolationMode.Cubic then
		if(not value.LeftTangent) then value.LeftTangent = 0 end
		if(not value.RightTangent) then value.RightTangent = 0 end
		local left, right = value.LeftTangent, value.RightTangent
		writef32(self.__buffer, self.__offset + 18, left)
		writef32(self.__buffer, self.__offset + 22, right)
	end
	self.__offset += bytes
	self.__offsetChanged:Fire(self.__offset)
end

--[[
	Write a FloatCurveKey to the buffer.
	- 16 bytes or 24 bytes total.
		- 16 bytes for Linear/Constant interpolation
		- 24 bytes for Cubic interpolation (includes tangent data)
		
	@Parameter(s): FloatCurveKey
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeFloatCurveKey(self : BitstreamComponent,value : FloatCurveKey)
	Debugger.handleAssert(typeof(value) == "FloatCurveKey","Type-missmatch",{
		Debugger.getFunctionName(),
		"FloatCurveKey"
	})
	const bytes = Constants.REQUIRED_BYTES.FloatCurveKey(value,"Normal")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	local id = Constants.EnumItemIndex[value.Interpolation]
	writef32(self.__buffer,self.__offset,value.Time)
	writef64(self.__buffer,self.__offset + 4,value.Value)
	writeu16(self.__buffer,self.__offset + 12,id)
	if(value.Interpolation == Enum.KeyInterpolationMode.Cubic) then
		if(not value.LeftTangent) then value.LeftTangent = 0 end
		if(not value.RightTangent) then value.RightTangent = 0 end
		writef32(self.__buffer,self.__offset + 14,value.LeftTangent)
		writef32(self.__buffer,self.__offset + 18,value.RightTangent)
	end
	self.__offset += bytes
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a FloatCurveKey to the buffer.
	- 18 bytes or 10 bytes total.
		- 10 bytes for Linear/Constant interpolation
		- 18 bytes for Cubic interpolation (includes tangent data)
	
	Write the property `.Value` as a f32 instead of a f64.
	
	@Parameter(s): FloatCurveKey
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeFloatCurveKeyF32(self : BitstreamComponent,value : FloatCurveKey)
	Debugger.handleAssert(typeof(value) == "FloatCurveKey","Type-missmatch",{
		Debugger.getFunctionName(),
		"FloatCurveKey"
	})
	const bytes = Constants.REQUIRED_BYTES.FloatCurveKey(value,"F32")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	local id = Constants.EnumItemIndex[value.Interpolation]
	writef32(self.__buffer,self.__offset,value.Time)
	writef32(self.__buffer,self.__offset + 4,value.Value)
	writeu16(self.__buffer,self.__offset + 8,id)
	if(value.Interpolation == Enum.KeyInterpolationMode.Cubic) then
		if(not value.LeftTangent) then value.LeftTangent = 0 end
		if(not value.RightTangent) then value.RightTangent = 0 end
		writef32(self.__buffer,self.__offset + 10,value.LeftTangent)
		writef32(self.__buffer,self.__offset + 14,value.RightTangent)
	end
	self.__offset += bytes
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a FloatCurveKey to the buffer.
	- 16 bytes or 8 bytes total.
		- 8 bytes for Linear/Constant interpolation
		- 16 bytes for Cubic interpolation (includes tangent data)
	
	Write the property `.Value` as a f16 instead of a f64.
	
	@Parameter(s): FloatCurveKey
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeFloatCurveKeyF16(self : BitstreamComponent,value : FloatCurveKey)
	Debugger.handleAssert(typeof(value) == "FloatCurveKey","Type-missmatch",{
		Debugger.getFunctionName(),
		"FloatCurveKey"
	})
	const bytes = Constants.REQUIRED_BYTES.FloatCurveKey(value,"F16")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	local id = Constants.EnumItemIndex[value.Interpolation]
	writef32(self.__buffer,self.__offset,value.Time)
	local uint16,sign,mantissa,exponent = Extensions.toFloat16(value.Time)
	writeu16(self.__buffer,self.__offset + 4,uint16)
	writeu16(self.__buffer,self.__offset + 6,id)
	if(value.Interpolation == Enum.KeyInterpolationMode.Cubic) then
		if(not value.LeftTangent) then value.LeftTangent = 0 end
		if(not value.RightTangent) then value.RightTangent = 0 end
		writef32(self.__buffer,self.__offset + 8,value.LeftTangent)
		writef32(self.__buffer,self.__offset + 12,value.RightTangent)
	end
	self.__offset += bytes
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Writes a ColorSequence to the buffer with all its keypoints.
	Limited to 255 keypoints.
	
	Size : 1 + (7 * #numbersOfKeypoints)
	
	@Parameter(s): ColorSequence
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeColorSequence(self : BitstreamComponent,value : ColorSequence)
	Debugger.handleAssert(typeof(value) == "ColorSequence","Type-missmatch",{
		Debugger.getFunctionName(),
		"ColorSequence"
	})
	if(#value.Keypoints <= 0) then 
		warn("Skipped ColorSequence, because it\'s empty")
		return 
	end
	const bytes = Constants.REQUIRED_BYTES.ColorSequence(value,"Normal")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,#value.Keypoints)
	self.__offset += 1
	for i = 1,#value.Keypoints do
		local keypoint = value.Keypoints[i]
		writef32(self.__buffer,self.__offset,keypoint.Time)
		writeu8(self.__buffer,self.__offset + 4,round(keypoint.Value.R*255))
		writeu8(self.__buffer,self.__offset + 5,round(keypoint.Value.G*255))
		writeu8(self.__buffer,self.__offset + 6,round(keypoint.Value.B*255))
		self.__offset += 7
	end
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Writes a ColorSequence to the buffer with all its keypoints.
	Limited to 255 keypoints.

	NOTE: This method uses 32-bit floating point numbers to store the RGB values, 
	
	Size : 1 + (16 * #numbersOfKeypoints)
	
	@Parameter(s): ColorSequence
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeColorSequenceF32(self : BitstreamComponent,value : ColorSequence)
	Debugger.handleAssert(typeof(value) == "ColorSequence","Type-missmatch",{
		Debugger.getFunctionName(),
		"ColorSequence"
	})
	if(#value.Keypoints <= 0) then 
		warn("Skipped ColorSequence, because it\'s empty")
		return 
	end
	const bytes = Constants.REQUIRED_BYTES.ColorSequence(value,"F32")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,#value.Keypoints)
	self.__offset += 1
	for i = 1,#value.Keypoints do
		local keypoint = value.Keypoints[i]
		writef32(self.__buffer,self.__offset,keypoint.Time)
		writef32(self.__buffer,self.__offset + 4,keypoint.Value.R)
		writef32(self.__buffer,self.__offset + 8,keypoint.Value.G)
		writef32(self.__buffer,self.__offset + 12,keypoint.Value.B)
		self.__offset += 16
	end
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Writes a ColorSequence to the buffer with all its keypoints.
	Limited to 255 keypoints.

	NOTE: This method uses 64-bit floating point numbers to store the RGB values, 
	
	Size : 1 + (28 * #numbersOfKeypoints)
	
	@Parameter(s): ColorSequence
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeColorSequenceF64(self : BitstreamComponent,value : ColorSequence)
	Debugger.handleAssert(typeof(value) == "ColorSequence","Type-missmatch",{
		Debugger.getFunctionName(),
		"ColorSequence"
	})
	if(#value.Keypoints <= 0) then 
		warn("Skipped ColorSequence, because it\'s empty")
		return 
	end
	const bytes = Constants.REQUIRED_BYTES.ColorSequence(value,"F64")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,#value.Keypoints)
	self.__offset += 1
	for i = 1,#value.Keypoints do
		local keypoint = value.Keypoints[i]
		writef32(self.__buffer,self.__offset,keypoint.Time)
		writef64(self.__buffer,self.__offset + 4,keypoint.Value.R)
		writef64(self.__buffer,self.__offset + 12,keypoint.Value.G)
		writef64(self.__buffer,self.__offset + 20,keypoint.Value.B)
		self.__offset += 28
	end
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a NumberRange to the buffer
	- 8 bytes total
		- 4 bytes for Min (F32)
		- 4 bytes for Max (F32)
	
	@Parameter(s): NumberRange
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeNumberRange(self : BitstreamComponent,value : NumberRange)
	Debugger.handleAssert(typeof(value) == "NumberRange","Type-missmatch",{
		Debugger.getFunctionName(),
		"NumberRange"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.NumberRange)
	if(component) then self = (component :: BitstreamComponent) end
	writef32(self.__buffer,self.__offset,value.Min)
	writef32(self.__buffer,self.__offset + 4,value.Max)
	self.__offset += 8
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a NumberRange to the buffer
	- 4 bytes total
		- 2 bytes for Min (F16)
		- 2 bytes for Max (F16)
	
	@Parameter(s): NumberRange
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeNumberRangeF16(self : BitstreamComponent,value : NumberRange)
	Debugger.handleAssert(typeof(value) == "NumberRange","Type-missmatch",{
		Debugger.getFunctionName(),
		"NumberRange"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.NumberRangeF16)
	if(component) then self = (component :: BitstreamComponent) end
	local minF16 = Extensions.toFloat16(value.Min)
	local maxF16 = Extensions.toFloat16(value.Max)
	writeu16(self.__buffer,self.__offset,minF16)
	writeu16(self.__buffer,self.__offset + 2,maxF16)
	self.__offset += 4
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a NumberRange to the buffer
	- 16 bytes total
		- 8 bytes for Min (F64)
		- 8 bytes for Max (F64)
	
	@Parameter(s): NumberRange
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeNumberRangeF64(self : BitstreamComponent,value : NumberRange)
	Debugger.handleAssert(typeof(value) == "NumberRange","Type-missmatch",{
		Debugger.getFunctionName(),
		"NumberRange"
	})
	const result,component = ensureWritable(self,Constants.REQUIRED_BYTES.NumberRangeF64)
	if(component) then self = (component :: BitstreamComponent) end
	writef64(self.__buffer,self.__offset,value.Min)
	writef64(self.__buffer,self.__offset + 8,value.Max)
	self.__offset += 16
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a NumberSequence to the buffer
	Limited to 255 keypoints.

	Size : 1 + (12 * #numbersOfKeypoints)
	
	@Parameter(s): NumberSequence
	
	@lastest modification : v4.0
	@since v1.0
]]
function Bitstream.writeNumberSequence(self : BitstreamComponent,value : NumberSequence)
	Debugger.handleAssert(typeof(value) == "NumberSequence","Type-missmatch",{
		Debugger.getFunctionName(),
		"NumberSequence"
	})
	if(#value.Keypoints <= 0) then 
		warn("Skipped NumberSequence, because it\'s empty")
		return 
	end
	const bytes = Constants.REQUIRED_BYTES.NumberSequence(value,"Normal")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,#value.Keypoints)
	self.__offset += 1
	local keypoints = value.Keypoints
	for i = 1,#keypoints do
		local keypoint = keypoints[i]
		writef32(self.__buffer,self.__offset,keypoint.Time)
		writef32(self.__buffer,self.__offset + 4,keypoint.Value)
		writef32(self.__buffer,self.__offset + 8,keypoint.Envelope)
		self.__offset += 12
	end
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a NumberSequence to the buffer
	Limited to 255 keypoints.
	
	NOTE : This function use F16 to write the number
	
	Size : 1 + (10 * #numbersOfKeypoints)
	
	@Parameter(s): NumberSequence
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeNumberSequenceF16(self : BitstreamComponent,value : NumberSequence)
	Debugger.handleAssert(typeof(value) == "NumberSequence","Type-missmatch",{
		Debugger.getFunctionName(),
		"NumberSequence"
	})
	if(#value.Keypoints <= 0) then 
		warn("Skipped NumberSequence, because it\'s empty")
		return 
	end
	const bytes = Constants.REQUIRED_BYTES.NumberSequence(value,"F16")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,#value.Keypoints)
	self.__offset += 1
	local keypoints = value.Keypoints
	for i = 1,#keypoints do
		local keypoint = keypoints[i]
		writef32(self.__buffer,self.__offset,keypoint.Time)
		local valuef16 = Extensions.toFloat16(keypoint.Value)
		writeu16(self.__buffer,self.__offset + 4,valuef16)
		writef32(self.__buffer,self.__offset + 6,keypoint.Envelope)
		self.__offset += 10
	end
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Write a NumberSequence to the buffer
	Limited to 255 keypoints.
	
	NOTE : This function use F64 to write the number
	
	Size : 1 + (16 * #numbersOfKeypoints)
	
	@Parameter(s): NumberSequence
	
	@lastest modification : v4.0
	@since v4.0
]]
function Bitstream.writeNumberSequenceF64(self : BitstreamComponent,value : NumberSequence)
	Debugger.handleAssert(typeof(value) == "NumberSequence","Type-missmatch",{
		Debugger.getFunctionName(),
		"NumberSequence"
	})
	if(#value.Keypoints <= 0) then 
		warn("Skipped NumberSequence, because it\'s empty")
		return 
	end
	const bytes = Constants.REQUIRED_BYTES.NumberSequence(value,"F64")
	const result,component = ensureWritable(self,bytes)
	if(component) then self = (component :: BitstreamComponent) end
	writeu8(self.__buffer,self.__offset,#value.Keypoints)
	self.__offset += 1
	local keypoints = value.Keypoints
	for i = 1,#keypoints do
		local keypoint = keypoints[i]
		writef32(self.__buffer,self.__offset,keypoint.Time)
		writef64(self.__buffer,self.__offset + 4,keypoint.Value)
		writef32(self.__buffer,self.__offset + 12,keypoint.Envelope)
		self.__offset += 16
	end
	self.__offsetChanged:Fire(self.__offset)
	return self
end

--[[
	Writes a value to the buffer using the specified Bitstream type.

	Supports primitive types, arrays, and structs. Complex types are
	recursively expanded and written to the buffer.

	@Parameters:
		- writeType : Enumeration.BitstreamTypes
		- value : any
	
	@lastest modification : v4.0
	@since v2.8
]]
function Bitstream.writeAs(self: BitstreamComponent,writeType : Enumeration.BitstreamTypes, value : any)
	assert(typeof(writeType) ~= "nil","A specific type is required.")
	assert(typeof(value) ~= "nil","A value is required.")
	local rbxType : string;
	if(typeof(writeType) == "table") then
		local typeName = writeType.Type
		if(typeName == "Array") then
			Resolver.iterateArray(writeType.Types,value,function(targetType,_value)
				self:writeAs(targetType,_value)
			end)
		elseif(typeName == "Struct") then
			Resolver.iterateStruct(writeType.Fields,value,function(targetType,_value)
				self:writeAs(targetType,_value)
			end)
		else
			local extra = writeType.Length or writeType.Option
			print(extra,writeType)
			if(typeof(extra) ~= "number") then
				writeType = writeType .. extra
			end
			self["write"..writeType](self,value)
		end
		return self
	end
	-- Fallback to literal string types (i.e. "I8" etc...)
	rbxType = Extensions.bitstreamTypesToLiteralTypes(writeType)
	Debugger.handleAssert(typeof(value) == rbxType,"Type-missmatch",{
		Debugger.getFunctionName(),
		rbxType
	})
	self["write"..writeType](self,value)
	return self
end

--[[
	Writes an array of typed values to the buffer.
	
	@Parameter(s): 
		Types = {Enumeration.BitstreamTypes}
		Values = {T}

	Note : Its preferable to directly use the target type function instead of `writeArray`.
		It directly call `writeAs` for each value in the array.
	
	@lastest modification : v4.0
	@since v2.8
]]
function Bitstream.writeArray<T>(self : BitstreamComponent,Types : {Enumeration.BitstreamTypes},Values : {T})
	assert(typeof(Types) == "table", "array must be a table")
	assert(typeof(Values) == "table", "value must be a table")
	Resolver.iterateArray(Types,Values,function(typeOf,v)
		self:writeAs(typeOf,v)
	end)
	return self
end

--[[
	Writes any supported value into the buffer by dynamically selecting
	the appropriate serialization method based on its runtime type.
	
	@Parameter(s): any
	
	@latest modification : v4.0
	@since v3.1
]]
function Bitstream.writeAny(self : BitstreamComponent,value : any)
	local valueType = Resolver.resolveValueType(value)
	if(valueType) == "Array" then
		local schema = Resolver.resolveArraySchema(value)
		self:writeAs(schema,value)
		return self
	elseif(valueType == "Struct") then
		return self
	end
	if(self["write"..valueType]) then
		self["write"..valueType](self,value)
	else
		self:writeAs(valueType,value)
	end
	return self
end

--[=[
	Writes a structured table (dictionary) into the buffer.
		
	@latest modification : v4.0
	@since v3.2
]=]
function Bitstream.writeStruct(
	self : BitstreamComponent,
	schema : Enumeration.StructSchema,
	struct : {[string] : any}
)
	assert(typeof(schema) == "table", "schema must be a table")
	assert(typeof(struct) == "table", "struct must be a table")
	Resolver.iterateStruct(schema.Fields,struct,function(targetType,_value)
		self:writeAs(targetType,_value)
	end)
end

--[[
	Read a Signed 8-bit integer from the buffer
	
	@Returns number in [-128, 127] 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readI8(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readi8,self.__buffer,offset)
end

--[[
	Read a Signed 16-bit integer from the buffer
	
	@Returns number in [-32_768, 32_767] 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readI16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readi16,self.__buffer,offset)
end

--[[
	Read a Signed 24-bit integer from the buffer
	
	@Returns number in [-8_388_608, 8_388_607] 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readI24(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		const b1 = readu8(self.__buffer,offset)
		const b2 = readu8(self.__buffer,offset + 1)
		const b3 = readu8(self.__buffer,offset + 2)
		local value = bor(lshift(b1,16),lshift(b2,8),b3)
		if b1 >= fsbit8 then -- sign bit set (2^7 in the MSB)
			value = value - fbit24 -- subtract 2^24
		end
		return value
	end,offset)
end

--[[
	Read a Signed 32-bit integer from the buffer
	
	@Returns number in [-2_147_483_648, 2_147_483_647] 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readI32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readi32,self.__buffer,offset)	
end

--[[
	Read a Signed 40-bit integer from the buffer
	
	@Returns number in [-549_755_813_888, 549_755_813_887] 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readI40(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		const b1 = readu8(self.__buffer,offset)
		const b2 = readu8(self.__buffer,offset + 1)
		const b3 = readu8(self.__buffer,offset + 2)
		const b4 = readu8(self.__buffer,offset + 3)
		const b5 = readu8(self.__buffer,offset + 4)
		local value = 
			b1 * fbit32 + 
			b2 * fbit24 + 
			b3 * fbit16 + 
			b4 * fbit8 + 
			b5
		if(value >= fsbits40) then
			value = value - fbit40
		end
		return value
	end,offset)
end

--[[
	Read a Signed 48-bit integer from the buffer
	
	@Returns number in [-140_737_488_355_328, 140_737_488_355_327] 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readI48(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		const b1 = readu8(self.__buffer,offset)
		const b2 = readu8(self.__buffer,offset + 1)
		const b3 = readu8(self.__buffer,offset + 2)
		const b4 = readu8(self.__buffer,offset + 3)
		const b5 = readu8(self.__buffer,offset + 4)
		const b6 = readu8(self.__buffer,offset + 5)
		local value =
			b1 * fbit40 + -- 2^40
			b2 * fbit32   + -- 2^32
			b3 * fbit24     + -- 2^24
			b4 * fbit16       + -- 2^16
			b5 * fbit8         + -- 2^8
			b6                  -- 2^0
		-- Two's complement sign fix: if value >= 2^47, subtract 2^48
		if value >= fsbits48 then
			value = value - fbit48
		end
		return value
	end,offset)
end

--[[
	Read a Signed 54-bit integer from the buffer
	
	@Returns number in [-9_007_199_254_740_992, 9_007_199_254_740_991] 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readI54(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		const b7 = readu8(self.__buffer,offset)
		const b6 = readu8(self.__buffer,offset + 1)
		const b5 = readu8(self.__buffer,offset + 2)
		const b4 = readu8(self.__buffer,offset + 3)
		const b3 = readu8(self.__buffer,offset + 4)
		const b2 = readu8(self.__buffer,offset + 5)
		const b1 = readu8(self.__buffer,offset + 6)
		-- Mask to 54 bits: keep only lower 6 bits of the MSB
		const msb54 = band(b7,bm6)
		local value =
			msb54 * fbit48 + -- 2^48 (with only 6 bits in msb54, total width = 54 bits)
			b6 * fbit40   + -- 2^40
			b5 * fbit32     + -- 2^32
			b4 * fbit24       + -- 2^24
			b3 * fbit16         + -- 2^16
			b2 * fbit8           + -- 2^8
			b1                    -- 2^0
		-- Two's complement sign fix for 54-bit:
		-- If value >= 2^53, subtract 2^54
		if value >= fsbits54 then
			value = value - fbit54
		end
		return value
	end,offset)
end

--[[
	Read 1 unsigned bit from the buffer.

	@Returns number in [0, 1]
	
	@latest modification : v4.0
	@since v1.3
]]
function Bitstream.readU1(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readbits,self.__buffer,offset * 8,1)
end

--[[
	Read an Unsigned 8-bit integer from the buffer.
	
	@Returns number in [0, 255]
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readU8(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readu8,self.__buffer,offset)
end

--[[
	Read an Unsigned 16-bit integer from the buffer.
	
	@Returns number in [0, 65_535]
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readU16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readu16,self.__buffer,offset)
end

--[[
	Read an Unsigned 24-bit integer from the buffer.
	
	@Returns number in [0, 16_777_215]
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readU24(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		const b1 = readu8(self.__buffer,offset)
		const b2 = readu8(self.__buffer,offset + 1)
		const b3 = readu8(self.__buffer,offset + 2)
		return bor(lshift(b1,16),lshift(b2,8),b3)
	end,offset)
end

--[[
	Read an Unsigned 32-bit integer from the buffer.
	
	@Returns number in [0, 4_294_967_295]
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readU32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readu32,self.__buffer,offset)
end

--[[
	Read an Unsigned 40-bit integer from the buffer.
	
	@Returns number in [0, 109_951_162_777_5]
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readU40(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		const b1 = readu8(self.__buffer,offset)
		const b2 = readu8(self.__buffer,offset + 1)
		const b3 = readu8(self.__buffer,offset + 2)
		const b4 = readu8(self.__buffer,offset + 3)
		const b5 = readu8(self.__buffer,offset + 4)
		local value =
			b1 * fbit32 + -- 2^32
			b2 * fbit24   + -- 2^24
			b3 * fbit16     + -- 2^16
			b4 * fbit8       + -- 2^8
			b5                -- 2^0
		return value
	end,offset)
end

--[[
	Read an Unsigned 48-bit integer from the buffer.
	
	@Returns number in [0, 281_474_976_710_655]
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readU48(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		const b1 = readu8(self.__buffer,offset)
		const b2 = readu8(self.__buffer,offset + 1)
		const b3 = readu8(self.__buffer,offset + 2)
		const b4 = readu8(self.__buffer,offset + 3)
		const b5 = readu8(self.__buffer,offset + 4)
		const b6 = readu8(self.__buffer,offset + 5)
		local value =
			b1 * fbit40 + -- 2^40
			b2 * fbit32   + -- 2^32
			b3 * fbit24     + -- 2^24
			b4 * fbit16       + -- 2^16
			b5 * fbit8         + -- 2^8
			b6                  -- 2^0
		return value	
	end,offset)
end

--[[
	Read an Unsigned 54-bit integer from the buffer.
	
	@Returns number in [0, 18_014_398_509_481_980]
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readU54(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local b1 = readu8(self.__buffer,offset)
		local b2 = readu8(self.__buffer,offset + 1)
		local b3 = readu8(self.__buffer,offset + 2)
		local b4 = readu8(self.__buffer,offset + 3)
		local b5 = readu8(self.__buffer,offset + 4)
		local b6 = readu8(self.__buffer,offset + 5)
		local b7 = readu8(self.__buffer,offset + 6)
		local value =
			b1 * fbit48 + -- 2^48
			b2 * fbit40   + -- 2^40
			b3 * fbit32     + -- 2^32
			b4 * fbit24       + -- 2^24
			b5 * fbit16         + -- 2^16
			b6 * fbit8           + -- 2^8
			b7                    -- 2^0
		return value
	end,offset)
end

--[[
 	Read a String from the buffer.
 	
	@Returns exepected string 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readString(self : BitstreamComponent,offset : number?,length : number)
	assert(typeof(length) == "number","length must be a number")
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readstring,self.__buffer,offset,length)
end

--[[
	Read a String from the buffer with a prefix.
	
	Read Order :
		1. Read the unsigned bit to know the length of the string
		2. Read the length from the unsigned bit
		3. Read the string with all required information

	@Returns exepected string 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readPrefixedString(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	local enumValue = self:readU8(offset)
	local enum = Enumeration:fromValue(enumValue)
	const length = self["read"..enum.Name](self,offset + 1)
	ensureReadable(self,offset + 1 + Constants.REQUIRED_BYTES[enum.Name],length)
	return readstring(self.__buffer,offset + 2,length)
end

--[[
	Read a 1-bit boolean from the buffer at a given bit offset.
	
	@Returns boolean 
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readBool1(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return (executeRead(self,readbits,self.__buffer,offset * 8,1) == 1 and true or false)
end

--[[
	Read 8 booleans (1 bit each) starting at a given bit offset.
	
	@Returns Table(
		value : {boolean} -- 8 booleans
		majority : () -> boolean -- returns the majority of the 8 booleans
	)
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readBool8(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local booleans : {boolean} = {}
		for i = 0,7 do
			booleans[i + 1] = (readbits(self.__buffer,offset * 8 + i,1) == 1) and true or false
		end
		return {
			value = booleans,
			majority = function()
				local tcount,fcount = 0,0
				for i = 1,#booleans do
					if(booleans[i]) then
						tcount += 1
					else
						fcount += 1
					end
				end
				return (tcount >= fcount and true or false)
			end,
		}
	end,offset)
end

--[[
	Read a 16-bit half-precision float (IEEE 754 binary16) from the buffer.
	
	@Returns number
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readF16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,Extensions.decodeF16,self.__buffer,offset)
end

--[[
	Read a 32-bit single-precision float from the buffer.
	
	@Returns number
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readF32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readf32,self.__buffer,offset)
end

--[[
	Read a 64-bit double-precision float from the buffer.
	
	@Returns number
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readF64(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,readf64,self.__buffer,offset)
end

--[[
	Read a Vector2 (single-precision) from the buffer
	
	@Returns Vector2
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readVector2float32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local x,y = readf32(self.__buffer,offset),readf32(self.__buffer,offset + 4)
		return Vector2.new(x,y)
	end,offset)
end

--[[
	Read a Vector2int16 from the buffer
	
	@Returns Vector2int16
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readVector2int16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local x,y = readi16(self.__buffer,offset),readi16(self.__buffer,offset + 2)
		return Vector2int16.new(x,y)
	end,offset)
end

--[[
	Read a Vector2uint16 from the buffer
	
	@Returns Vector2 (unsigned 16-int)
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readVector2uint16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local x,y = readu16(self.__buffer,offset),readu16(self.__buffer,offset + 2)
		return Vector2.new(x,y)
	end,offset)
end

--[[
	Read a Vector2 (double-precision) from the buffer
	
	@Returns Vector2
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readVector2(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local x,y = readf64(self.__buffer,offset),readf64(self.__buffer,offset + 8)
		return Vector2.new(x,y)
	end,offset)
end

--[[
	Read a Vector3 (single-precision) from the buffer
	
	@Returns Vector3
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readVector3float32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local x,y,z = readf32(self.__buffer,offset),readf32(self.__buffer,offset + 4),readf32(self.__buffer,offset + 8)
		return Vector3.new(x,y,z)
	end,offset)
end

--[[
	Read a Vector3int16 from the buffer
	
	@Returns Vector3int16
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readVector3int16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local x,y,z = readi16(self.__buffer,offset),readi16(self.__buffer,offset + 2),readi16(self.__buffer,offset + 4)
		return Vector3int16.new(x,y,z)
	end,offset)
end

--[[
	Read a Vector3uint16 from the buffer
	
	@Returns Vector3 (unsigned 16-int)
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readVector3uint16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local x,y,z = readu16(self.__buffer,offset),readu16(self.__buffer,offset + 2),readu16(self.__buffer,offset + 4)
		return Vector3.new(x,y,z)
	end,offset)
end

--[[
	Read a Vector3 (double-precision) from the buffer
	
	@Returns Vector3
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readVector3(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local x,y,z = readf64(self.__buffer,offset),readf64(self.__buffer,offset + 8),readf64(self.__buffer,offset + 16)
		return Vector3.new(x,y,z)
	end,offset)
end

--[[
	Read a Quaternion and convert it to a CFrame from the buffer
	
	@Returns CFrame
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readCFrameQuaternion(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local pos = {
			x = readf32(self.__buffer,offset),
			y = readf32(self.__buffer,offset + 4),
			z = readf32(self.__buffer,offset + 8)
		}
		local quat = {
			x = readf32(self.__buffer,offset + 12),
			y = readf32(self.__buffer,offset + 16),
			z = readf32(self.__buffer,offset + 20),
			w = readf32(self.__buffer,offset + 24)
		}
		return Extensions.quaternionToCFrame(
			Vector3.new(pos.x,pos.y,pos.z),
			quat
		)
	end,offset)
end

--[[
	Read a CFrame (single-precision) from the buffer
	
	@Returns CFrame
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readCFrameF32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local px,py,pz = readf32(self.__buffer,offset),readf32(self.__buffer,offset + 4),readf32(self.__buffer,offset + 8)
		local x,y,z = readf32(self.__buffer,offset + 12),readf32(self.__buffer,offset + 16),readf32(self.__buffer,offset + 20)
		return CFrame.Angles(x,y,z) + Vector3.new(px,py,pz)	
	end,offset)
end

--[[
	Read a CFrame (double-precision) from the buffer
	
	@Returns CFrame
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readCFrameF64(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local px,py,pz = readf64(self.__buffer,offset),readf64(self.__buffer,offset + 8),readf64(self.__buffer,offset + 16)
		local x,y,z = readf64(self.__buffer,offset + 24),readf64(self.__buffer,offset + 32),readf64(self.__buffer,offset + 40)
		return CFrame.Angles(x,y,z) + Vector3.new(px,py,pz)
	end,offset)
end

--[[
	Read a Quantized-CFrame from the buffer
	
	Quantization scales:
	- POSITION_SCALE = 1000 (converts meters to millimeters)
	- ROTATION_SCALE = 10430.38 (32767/π for optimal angle precision)
	
	@Returns CFrame
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readCFrameQuantized(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local pos = {
			x = readi16(self.__buffer,offset) / POSITION_SCALE,
			y = readi16(self.__buffer,offset + 2) / POSITION_SCALE,
			z = readi16(self.__buffer,offset + 4) / POSITION_SCALE
		}
		local rot = {
			x = readi16(self.__buffer,offset + 6) / ROTATION_SCALE,
			y = readi16(self.__buffer,offset + 8) / ROTATION_SCALE,
			z = readi16(self.__buffer,offset + 10) / ROTATION_SCALE,
		}
		return CFrame.new(pos.x,pos.y,pos.z) * CFrame.fromEulerAnglesXYZ(rot.x,rot.y,rot.z)
	end,offset)
end

--[[
	Read a Color3 from the buffer
	
	@Returns Color3
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readColor3(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local r,g,b = readu8(self.__buffer,offset)/255,readu8(self.__buffer,offset + 1)/255,readu8(self.__buffer,offset + 2)/255
		return Color3.new(r,g,b)
	end,offset)
end

--[[
	Read a Color3 (single-precision) from the buffer
	
	@Returns Color3
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readColor3F32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local r,g,b = readf32(self.__buffer,offset),readf32(self.__buffer,offset + 4),readf32(self.__buffer,offset + 8)
		return Color3.new(r,g,b)
	end,offset)
end

--[[
	Read a Color3 (double-precision) from the buffer
	
	@Returns Color3
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readColor3F64(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local r,g,b = readf64(self.__buffer,offset),readf64(self.__buffer,offset + 8),readf64(self.__buffer,offset + 16)
		return Color3.new(r,g,b)
	end,offset)
end

--[[
	Read a UDim from the buffer
	
	@Returns UDim
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readUDim(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local scale = readf32(self.__buffer,offset)
		local offset = readi32(self.__buffer,offset + 4)
		return UDim.new(scale,offset)
	end,offset)
end

--[[
	Read a UDim2 from the buffer
	
	@Returns UDim2
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readUDim2(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local scaleX,scaleY = readf32(self.__buffer,offset),readf32(self.__buffer,offset + 8)
		local offsetX,offsetY = readi32(self.__buffer,offset + 4),readi32(self.__buffer,offset + 12)
		return UDim2.new(scaleX,offsetX,scaleY,offsetY)
	end,offset)
end

--[[
	Read a Rect(Float32) from the buffer.
	Store min and max as Vector2Float32 (single-precision)
	
	@Returns Rect
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readRectFloat32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local minX,minY = readf32(self.__buffer,offset),readf32(self.__buffer,offset + 4)
		local maxX,maxY = readf32(self.__buffer,offset + 8),readf32(self.__buffer,offset + 12)
		return Rect.new(minX,minY,maxX,maxY)
	end,offset)
end

--[[
	Read a Rect from the buffer.
	
	@Returns Rect
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readRect(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local minX,minY = readf64(self.__buffer,offset),readf64(self.__buffer,offset + 8)
		local maxX,maxY = readf64(self.__buffer,offset + 16),readf64(self.__buffer,offset + 24)
		return Rect.new(minX,minY,maxX,maxY)
	end,offset)
end

--[[
	Read a Enum from the buffer.
	
	@Returns EnumItem
	
	@latest modification : v4.0
	@since v1.7
]]
function Bitstream.readEnum(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local id = readu16(self.__buffer,offset)
		return Constants.EnumItemList[id]
	end,offset)
end

--[[
	Read a Region3 from the buffer
	
	@Returns Region3
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readRegion3(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local cf = self:readCFrameF64(offset)
		local size = self:readVector3(offset + 48)
		local halfSize = size * 0.5
		local min = cf.Position - halfSize
		local max = cf.Position + halfSize
		return Region3.new(min,max)
	end,offset)
end

--[[
	Read a Region3int16 from the buffer
	
	@Returns Region3int16
	
	@latest modification : v4.0
	@since v1.0
]]
function Bitstream.readRegion3int16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local min = self:readVector3int16(offset)
		local max = self:readVector3int16(offset + 6)
		return Region3int16.new(min,max)
	end,offset)
end

--[[
	Read a Region3 from the buffer using Quaternion CFrames.
	
	@Returns Region3
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readRegion3Quaternion(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local cf = self:readCFrameQuaternion(offset)
		local size = self:readVector3(offset + 28)
		local halfSize = size * 0.5
		local min = cf.Position - halfSize
		local max = cf.Position + halfSize
		return Region3.new(min,max)
	end,offset)
end

--[[
	Read a Region3 from the buffer using F32 CFrames.
	
	@Returns Region3
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readRegion3CFrameF32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local cf = self:readCFrameF32(offset)
		local size = self:readVector3(offset + 24)
		local halfSize = size * 0.5
		local min = cf.Position - halfSize
		local max = cf.Position + halfSize
		return Region3.new(min,max)
	end,offset)
end

--[[
	Read a Region3 from the buffer using a Quantized CFrames.
	
	@Returns Region3
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readRegion3Quantized(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local cf = self:readCFrameQuantized(offset)
		local size = self:readVector3(offset + 12)
		local halfSize = size * 0.5
		local min = cf.Position - halfSize
		local max = cf.Position + halfSize
		return Region3.new(min,max)
	end,offset)
end

--[[
	Read a RotationCurveKey from the buffer.
	
	@Returns RotationCurveKey
	
	@latest modification : v4.0
	@since v1.8
]]
function Bitstream.readRotationCurveKey(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,4)
	local t = readf32(self.__buffer,offset)
	local cf = self:readCFrameF64(offset + 4)
	local enum = self:readEnum(offset + 52)
	local leftTangent,rightTangent = nil,nil
	local rotKey = RotationCurveKey.new(t,cf,enum)
	if(enum == Enum.KeyInterpolationMode.Cubic) then
		ensureReadable(self,offset + 54,8)
		leftTangent = readf32(self.__buffer,offset + 54)
		rightTangent = readf32(self.__buffer,offset + 58)
		rotKey.LeftTangent = leftTangent
		rotKey.RightTangent = rightTangent
	end
	return rotKey	
end

--[[
	Read a RotationCurveKey from the buffer using Quaternion CFrames.
	
	@Returns RotationCurveKey
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readRotationCurveKeyQuaternion(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,4)
	local t = readf32(self.__buffer,offset)
	local cf = self:readCFrameQuaternion(offset + 4)
	local enum = self:readEnum(offset + 32)
	local leftTangent,rightTangent = nil,nil
	local rotKey = RotationCurveKey.new(t,cf,enum)
	if(enum == Enum.KeyInterpolationMode.Cubic) then
		ensureReadable(self,offset + 34,8)
		leftTangent = readf32(self.__buffer,offset + 34)
		rightTangent = readf32(self.__buffer,offset + 38)
		rotKey.LeftTangent = leftTangent
		rotKey.RightTangent = rightTangent
	end
	return rotKey
end

--[[
	Read a RotationCurveKey from the buffer using F32 CFrames.
	
	@Returns RotationCurveKey
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readRotationCurveKeyCFrameF32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,4)
	local t = readf32(self.__buffer,offset)
	local cf = self:readCFrameF32(offset + 4)
	local enum = self:readEnum(offset + 28)
	local leftTangent,rightTangent = nil,nil
	local rotKey = RotationCurveKey.new(t,cf,enum)
	if(enum == Enum.KeyInterpolationMode.Cubic) then
		ensureReadable(self,offset + 30,8)
		leftTangent = readf32(self.__buffer,offset + 30)
		rightTangent = readf32(self.__buffer,offset + 34)
		rotKey.LeftTangent = leftTangent
		rotKey.RightTangent = rightTangent
	end
	return rotKey
end

--[[
	Read a RotationCurveKey from the buffer using a Quantized CFrame.
	
	@Returns RotationCurveKey
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readRotationCurveKeyQuantized(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,4)
	local t = readf32(self.__buffer,offset)
	local cf = self:readCFrameQuantized(offset + 4)
	local enum = self:readEnum(offset + 16)
	local leftTangent,rightTangent = nil,nil
	local rotKey = RotationCurveKey.new(t,cf,enum)
	if(enum == Enum.KeyInterpolationMode.Cubic) then
		ensureReadable(self,offset + 18,8)
		leftTangent = readf32(self.__buffer,offset + 18)
		rightTangent = readf32(self.__buffer,offset + 22)
		rotKey.LeftTangent = leftTangent
		rotKey.RightTangent = rightTangent
	end
	return rotKey
end

--[[
	Read a FloatCurveKey from the buffer.
	
	@Returns FloatCurveKey
	
	@latest modification : v4.0
	@since v1.8
]]
function Bitstream.readFloatCurveKey(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,4)
	local t = readf32(self.__buffer,offset)
	local value = readf64(self.__buffer,offset + 4)
	local enum = self:readEnum(offset + 12)
	local leftTangent,rightTangent = nil,nil
	local floatKey = FloatCurveKey.new(t,value,enum)
	if(enum == Enum.KeyInterpolationMode.Cubic) then
		ensureReadable(self,offset + 14,8)
		leftTangent = readf32(self.__buffer,offset + 14)
		rightTangent = readf32(self.__buffer,offset + 18)
		floatKey.LeftTangent = leftTangent
		floatKey.RightTangent = rightTangent
	end
	return floatKey
end

--[[
	Read a FloatCurveKey from the buffer using F32.
	
	@Returns FloatCurveKey
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readFloatCurveKeyF32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,4)
	local t = readf32(self.__buffer,offset)
	local value = readf32(self.__buffer,offset + 4)
	local enum = self:readEnum(offset + 8)
	local leftTangent,rightTangent = nil,nil
	local floatKey = FloatCurveKey.new(t,value,enum)
	if(enum == Enum.KeyInterpolationMode.Cubic) then
		ensureReadable(self,offset + 10,8)
		leftTangent = readf32(self.__buffer,offset + 10)
		rightTangent = readf32(self.__buffer,offset + 14)
		floatKey.LeftTangent = leftTangent
		floatKey.RightTangent = rightTangent
	end
	return floatKey
end

--[[
	Read a FloatCurveKey from the buffer using F16.
	
	@Returns FloatCurveKey
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readFloatCurveKeyF16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,4)
	local t = readf32(self.__buffer,offset)
	local value = Extensions.decodeF16(self.__buffer,offset + 4)
	local enum = self:readEnum(offset + 6)
	local leftTangent,rightTangent = nil,nil
	local floatKey = FloatCurveKey.new(t,value,enum)
	if(enum == Enum.KeyInterpolationMode.Cubic) then
		ensureReadable(self,offset + 8,8)
		leftTangent = readf32(self.__buffer,offset + 8)
		rightTangent = readf32(self.__buffer,offset + 10)
		floatKey.LeftTangent = leftTangent
		floatKey.RightTangent = rightTangent
	end
	return floatKey
end

--[[
	Read a ColorSequence from the buffer.
	
	@Returns ColorSequence
	
	@latest modification : v4.0
	@since v1.8
]]
function Bitstream.readColorSequence(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,1)
	local length = self:readU8(offset)
	offset += 1
	local colorSequence = {}
	for i = 1,length do
		ensureReadable(self,offset,7)
		local t = readf32(self.__buffer,offset)
		local value = self:readColor3(offset + 4)
		colorSequence[i] = ColorSequenceKeypoint.new(t,value)
		offset += 7
	end
	return ColorSequence.new(colorSequence)
end

--[[
	Read a ColorSequence from the buffer using F32.
	
	@Returns ColorSequence
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readColorSequenceF32(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,1)
	local length = self:readU8(offset)
	offset += 1
	local colorSequence = {}
	for i = 1,length do
		ensureReadable(self,offset,16)
		local t = readf32(self.__buffer,offset)
		local value = self:readColor3F32(offset + 4)
		colorSequence[i] = ColorSequenceKeypoint.new(t,value)
		offset += 16
	end
	return ColorSequence.new(colorSequence)
end

--[[
	Read a ColorSequence from the buffer using F64.
	
	@Returns ColorSequence
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readColorSequenceF64(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,1)
	local length = self:readU8(offset)
	offset += 1
	local colorSequence = {}
	for i = 1,length do
		ensureReadable(self,offset,28)
		local t = readf32(self.__buffer,offset)
		local value = self:readColor3F64(offset + 4)
		colorSequence[i] = ColorSequenceKeypoint.new(t,value)
		offset += 28
	end
	return ColorSequence.new(colorSequence)
end

--[[
	Read a NumberRange from the buffer.
	
	@Returns NumberRange
	
	@latest modification : v4.0
	@since v1.8
]]
function Bitstream.readNumberRange(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local min = readf32(self.__buffer,offset)
		local max = readf32(self.__buffer,offset + 4)
		return NumberRange.new(min,max)
	end,offset)
end

--[[
	Read a NumberRange from the buffer using F16.
	
	@Returns NumberRange
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readNumberRangeF16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local min = Extensions.decodeF16(self.__buffer,offset)
		local max = Extensions.decodeF16(self.__buffer,offset + 2)
		return NumberRange.new(min,max)
	end,offset)
end

--[[
	Read a NumberRange from the buffer using F64.
	
	@Returns NumberRange
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readNumberRangeF64(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	return executeRead(self,function()
		local min = readf64(self.__buffer,offset)
		local max = readf64(self.__buffer,offset + 8)
		return NumberRange.new(min,max)
	end,offset)
end

--[[
	Read a NumberSequence from the buffer.
	
	@Returns NumberSequence
	
	@latest modification : v4.0
	@since v1.8
]]
function Bitstream.readNumberSequence(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,1)
	local length = readu8(self.__buffer,offset)
	offset += 1
	local numberSequence = {}
	for i = 1,length do
		ensureReadable(self,offset,12)
		local t = readf32(self.__buffer,offset)
		local value = readf32(self.__buffer,offset + 4)
		local envelope = readf32(self.__buffer,offset + 8)
		numberSequence[i] = NumberSequenceKeypoint.new(t,value,envelope)
		offset += 12
	end
	return NumberSequence.new(numberSequence)
end

--[[
	Read a NumberSequence from the buffer using F16.
	
	@Returns NumberSequence
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readNumberSequenceF16(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,1)
	local length = readu8(self.__buffer,offset)
	offset += 1
	local numberSequence = {}
	for i = 1,length do
		ensureReadable(self,offset,10)
		local t = readf32(self.__buffer,offset)
		local value = Extensions.decodeF16(self.__buffer,offset + 4)
		local envelope = readf32(self.__buffer,offset + 6)
		numberSequence[i] = NumberSequenceKeypoint.new(t,value,envelope)
		offset += 10
	end
	return NumberSequence.new(numberSequence)
end

--[[
	Read a NumberSequence from the buffer using F64.
	
	@Returns NumberSequence
	
	@latest modification : v4.0
	@since v4.0
]]
function Bitstream.readNumberSequenceF64(self : BitstreamComponent,offset : number?)
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	ensureReadable(self,offset,1)
	local length = readu8(self.__buffer,offset)
	offset += 1
	local numberSequence = {}
	for i = 1,length do
		ensureReadable(self,offset,16)
		local t = readf32(self.__buffer,offset)
		local value = readf64(self.__buffer,offset + 4)
		local envelope = readf32(self.__buffer,offset + 12)
		numberSequence[i] = NumberSequenceKeypoint.new(t,value,envelope)
		offset += 16
	end
	return NumberSequence.new(numberSequence)
end

--[[
	Read any target type from the buffer.
	
	@Generics T
	
	@param offset : number? 
		The offset to read from.
	@param as : string
		The type to read as. (Full list at ./Enumeration -> BitstreamTypesName)
	
	@returns T
		The read value.
	
	@latest modification : v4.0
	@since v2.8
]]
function Bitstream.readAs<T>(
	self : BitstreamComponent,
	offset : number?,
	readType : Enumeration.BitstreamTypes,
	extraData : any
) : T & number
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	local value = nil
	if(typeof(readType) == "table") then
		local typeName = readType.Type
		if(typeName == "Array") then
			value = {}
			local nestedArray = {}
			Resolver.resolveArray(readType.Types,function(targetType,typeCount,hasNestedFlag)
				for i = 1,typeCount do
					local element,elementOffset = self:readAs(offset,targetType)
					offset = elementOffset
					if(hasNestedFlag) then
						tblinsert(nestedArray,element)
					else
						tblinsert(value,element)
					end
				end
				if(hasNestedFlag) then
					tblinsert(value,tblclone(nestedArray))
				end
				tblclear(nestedArray)	
			end)
			return value :: T,offset
		elseif(typeName == "Struct") then
			value = Resolver.resolveStruct(readType.Fields,function(targetType)
				local element,elementOffset = self:readAs(offset,targetType)
				offset = elementOffset
				return element
			end)
			return value :: T,offset
		else
			local extra = readType.Length or readType.Option
			if(typeof(extra) ~= "number") then
				readType = readType .. extra
			end
			local element = self["read"..readType](self,offset) :: T
			return element,offset + Resolver.resolveBytesNeeded(readType,element)
		end
	else
		local element = self["read"..readType](self,offset) :: T
		return element,offset + Resolver.resolveBytesNeeded(readType,element)
	end
end

--[[
	Read an array from the buffer.
	
	@Generics T
	
	@param offset : number? 
		The offset to read from.
	@param types : {string}
		The types to read as. (Full list at ./Enumeration -> BitstreamTypesName)
	
	@returns {T}
		The read array.
	
	@latest modification : v4.0
	@since v2.9	
]]
function Bitstream.readArray<T>(self : BitstreamComponent,offset : number?,types : {Enumeration.BitstreamTypes})
	offset = (typeof(offset) == "number" and offset <= self.__offset) and offset or self.__offset
	local array : {T} = {}
	local nestedArray = {}
	Resolver.resolveArray(types,function(targetType,typeCount,hasNestedFlag)
		for i = 1,typeCount do
			local element,elementOffset = self:readAs(offset,targetType)
			offset = elementOffset
			if(hasNestedFlag) then
				tblinsert(nestedArray,element)
			else
				tblinsert(array,element)
			end
		end
		if(hasNestedFlag) then
			tblinsert(array,tblclone(nestedArray))
		end
		tblclear(nestedArray)	
	end)
	return array
end

--[[
	Read a struct from the buffer.
		
	@param offset : number? 
		The offset to read from.
		
	@returns : {[string] : any}
		The read struct.
	
	@latest modification : v4.0
	@since v3.2	
]]
function Bitstream.readStruct(
	self : BitstreamComponent,
	offset : number?,
	schema : Enumeration.StructSchema
)
	return Resolver.resolveStruct(schema.Fields,function(targetType)
		local element,elementOffset = self:readAs(offset,targetType)
		offset = elementOffset
		return element
	end)
end


--[[
	Read any data type from the buffer.
		
	@param offset : number? 
		The offset to read from.
		
	@returns : any
		The read value.
		
	@latest modification : v4.0
	@since v4.0
	
	TODO: Start the refactorized readAny
]]
function Bitstream.readAny(self : BitstreamComponent,offset : number?)

end

--[[
	Attach a callback and call it every time a value is written.
		
	@param callback : (newOffset : number) -> () 
		The callback to call.
	
	@returns : Connection<number>
		The connection to the offset changed event.

	@latest modification : v4.0
	@since v2.6
]]
function Bitstream.onOffsetChanged(self : BitstreamComponent,callback : (newOffset : number) -> ())
	Debugger.handleAssert(typeof(callback) == "function","Type-missmatch",{
		Debugger.getFunctionName(),
		"function"
	})
	return self.__offsetChanged:Connect(callback)
end

--[[
	Attach a callback and call it every time a new amount of space is allocated.
			
	@param callback : (newCapacity : number) -> () 
		The callback to call.
		
	@returns : Connection<number>
		The connection to the capacity changed event.
		
	@latest modification : v4.0
	@since v2.6
]]
function Bitstream.onCapacityChanged(self : BitstreamComponent,callback : (newCapacity : number) -> ())
	Debugger.handleAssert(typeof(callback) == "function","Type-missmatch",{
		Debugger.getFunctionName(),
		"function"
	})
	return self.__capacityChanged:Connect(callback)
end

--[[
	Compress the buffer of the actual component using the `EncodingService`
	
	@param: algorithm 
		The algorithm to use.
	
	@returns : buffer
		Will return the compressed buffer.
	
	@latest modification : v4.0
	@since v2.6
]]
function Bitstream.compress(self : BitstreamComponent,algorithm : Enum.CompressionAlgorithm)
	return EncodingService:CompressBuffer(self.__buffer,algorithm)
end

--[[
	Return the actual remaining space of the current buffer
	
	@returns : number
		Will return the remaining space.
	
	@latest modification : v4.0
	@since v1.7
]]
function Bitstream.getRemainingSpace(self : BitstreamComponent)
	return bufflen(self.__buffer) - self.__offset
end

--[[
	Return the actual size of the current buffer
	
	@returns : number
		Will return the size of the buffer.
	
	@latest modification : v4.0
	@since v1.2
]]
function Bitstream.getBufferSize(self : BitstreamComponent)
	return bufflen(self.__buffer)
end

--[[
	Clear the component (signals,buffer etc..)
	
	@latest modification : v4.0
	@since v2.4
]]
function Bitstream.clear(self : BitstreamComponent)
	tblclear(self.__instanceBuffer)
	self.__offsetChanged:DisconnectAll()
	self.__capacityChanged:DisconnectAll()
	return self
end

--[[
	Reset the buffer to the initial state.
	
	@latest modification : v4.0
	@since v2.4
]]
function Bitstream.clearBuffer(self : BitstreamComponent)
	self.__buffer = buffer.create(buffer.len(self.__buffer))
	self.__offset = 0
	self.__offsetChanged:Fire(0)
	return self
end

--[[
	Create a copy of the component.
	
	@returns : BitstreamComponent
		Will return a new component.
	
	@latest modification : v4.0
	@since v2.5
]]
function Bitstream.copy(self : BitstreamComponent)
	local new = BitstreamConstructor.new({
		Size = bufflen(self.__buffer),
		UseAutoAllocation = self.__useAutoAllocation,
	})
	new.__buffer = buffer.copy(new.__buffer,0,self.__buffer,0,bufflen(self.__buffer))
	new.__offset = self.__offset
	new.__offsetChanged:Fire(self.__offset)
	return new
end

--[[
	Disconnect all signals of the component.
	
	@latest modification : v4.0
	@since v2.6
]]
function Bitstream.disconnectAllSignals(self : BitstreamComponent)
	self.__offsetChanged:DisconnectAll()
	self.__capacityChanged:DisconnectAll()
	return self
end

--[[
	Enable the auto-allocation of the component.
	
	@latest modification : v4.0
	@since v3.0
]]
function Bitstream.enableAutoAllocate(self : BitstreamComponent)
	self.__useAutoAllocation = true
	return self
end

--[[
	Disable the auto-allocation of the component.
	
	@latest modification : v4.0
	@since v3.0
]]
function Bitstream.disableAutoAllocate(self : BitstreamComponent)
	self.__useAutoAllocation = false
	return self
end

function Bitstream.Destroy(self : BitstreamComponent)
	self:disconnectAllSignals()
	self:clear()
	setmetatable(self,nil)
	self = nil
end

return BitstreamConstructor
