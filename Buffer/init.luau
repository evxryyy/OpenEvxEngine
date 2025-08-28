--!nonstrict

--[[
    Author: evxry_ll

    Buffer: A powerful library to write data with the "buffer" type.

    Supported Data Types:
    
    ================ INTEGER TYPES ================
    Signed Integers:
    - I1  (1-bit)   : -1 to 1
    - I8  (8-bit)   : -128 to 127
    - I16 (16-bit)  : -32,768 to 32,767
    - I24 (24-bit)  : -8,388,608 to 8,388,607
    - I32 (32-bit)  : -2,147,483,648 to 2,147,483,647
    - I40 (40-bit)  : -549,755,813,888 to 549,755,813,887
    - I48 (48-bit)  : -140,737,488,355,328 to 140,737,488,355,327
    - I54 (54-bit)  : -9,007,199,254,740,992 to 9,007,199,254,740,991
    
    Unsigned Integers:
    - U1  (1-bit)   : 0 to 1
    - U8  (8-bit)   : 0 to 255
    - U16 (16-bit)  : 0 to 65,535
    - U24 (24-bit)  : 0 to 16,777,215
    - U32 (32-bit)  : 0 to 4,294,967,295
    - U40 (40-bit)  : 0 to 1,099,511,627,775
    - U48 (48-bit)  : 0 to 281,474,976,710,655
    - U54 (54-bit)  : 0 to 18,014,398,509,481,984
    
    ================ FLOATING POINT TYPES ================
    - F16 (16-bit) : Half-precision float
    - F32 (32-bit) : Single-precision float
    - F64 (64-bit) : Double-precision float
    
    ================ OTHER DATA TYPES ================
    - Boolean (1-bit and 8-bit packed)
    - Strings (with various length limits: 8, 16, 32, 64 chars or unlimited)
    - Color3
    - Vector2, Vector3
    - Vector2int16, Vector3int16
    - CFrame (both regular and lossy compressed versions)
    - UDim, UDim2
    - Rect
    - Region3, Region3int16
    - Instances (stored in a separate instance buffer)

    You are free to edit this as you want, but if you want to publish it PLEASE READ THE LICENSE.

    For finer control over number and float precision, check Constants in this module or read the documentation.

    Note:
    The buffer can be encrypted for security purposes.

    Endianness:
    Multi-byte integers in this module are written in big-endian order (highest-order byte first).
--]]

-- Constants: centralizes numeric limits and precision settings (e.g., MIN/MAX for each type)
local Constants = require("@self/Constants")

-- Debug: string templates and helpers for warnings/errors (e.g., "not enough space")
local Debug = require("@self/Debug")

-- Constructor table: creates BufferComponent instances or wraps an existing buffer
local BufferConstructor = {}
BufferConstructor.__index = BufferConstructor

-- BufferComponent: instance methods for writing data and managing offsets
local BufferComponent = {}
BufferComponent.__index = BufferComponent

--[[
    Type definition for a BufferComponent instance.
    - offset: current write offset (in bytes) into `buffer`
    - instance_offset: current write offset for instance references (if used)
    - buffer: the underlying Roblox buffer
    - instance_buffer: a side-channel storage for Instances (if used elsewhere)
    - allocate: grows the buffer by the requested size (O(n) copy)
]]
export type BufferComponentClass = typeof(setmetatable({} :: {
	offset : number,
	instance_offset : number,
	buffer : buffer,
	instance_buffer : { Instance },
	allocate : (self : BufferComponentClass,size : number) -> (),
},BufferComponent))

--[[
	Type definition for the ReadBool8 function
]]
type Readbool8ReturnType = {
	value : {boolean},
	majority : () -> boolean,
}

--[[
    Create a new BufferComponent with a given initial size (in bytes).
    If size is nil or <= 0, defaults to 1 byte.

    Note: `offset` starts at 0 (first write will go at index 0).
]]
function BufferConstructor.create(size : number) : BufferComponentClass
	if(not size or (size) < 0) then size = 1 end
	local self = setmetatable({
		offset = 0,
		instance_offset = 1,
		buffer = buffer.create(size),
	},BufferComponent)
	return self
end

--[[
    Wrap an existing buffer into a BufferComponent instance so you can continue writing
    and later read from it with :Read[DataTypeName] methods (not shown here).

    Note:
    - This sets `offset` to the current buffer length, so subsequent writes append.
    - `instance_buffer` starts empty; adapt if you rely on instance serialization.
]]
function BufferConstructor.from(b : buffer) : BufferComponentClass
	if(not b or type(b) ~= "buffer") then
		error(Debug["not a valid type"]:format(type(b),"buffer"))
	end
	local self = setmetatable({
		offset = buffer.len(b),
		instance_offset = 0,
		instance_buffer = {},
		buffer = b,
	},BufferComponent)
	return self
end

--[[
    Convert the current BufferComponent.buffer to a string.
    Intended as a constructor utility rather than an instance method.
]]
function BufferConstructor.tostring(BufferComponent : BufferComponentClass)
	return buffer.tostring(BufferComponent.buffer)
end

--[[
    Create a BufferComponent from a string payload.
    Internally converts string -> buffer via buffer.fromstring.
]]
function BufferConstructor.fromString(str : string) : BufferComponentClass
	if(not str or type(str) ~= "string") then
		error(Debug["not a valid type"]:format(type(str),type("str")))
	end
	return BufferConstructor.from(buffer.fromstring(str))
end

--[[
    __tostring metamethod for debug/logging: shows current buffer size in bytes.
]]
function BufferComponent.__tostring(self : BufferComponentClass)
	return `BufferComponent(Size:{buffer.len(self.buffer)})`
end

--[[
    Allocate additional space by creating a new buffer with increased capacity,
    copying the existing content, and swapping references.
]]
function BufferComponent.allocate(self : BufferComponentClass,size : number) : ()
	local new_buffer = buffer.create(buffer.len(self.buffer)+size)
	buffer.copy(new_buffer,0,self.buffer,0,buffer.len(self.buffer))
	self.buffer = new_buffer
end

--[[
    Write a signed 1-bit integer (-1 to 1).
    - The value is clamped to the allowed range and truncated to an integer.
    - Stored using buffer.writei8 (occupies 1 byte).
    - Endianness is irrelevant for single-byte writes.
]]
function BufferComponent.WriteI1(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT1,Constants.MAX_INT1)
	local bytes = 1
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	-- Using pcall to catch out-of-bounds; `outOfBounds` holds the error message if any.
	local success,outOfBounds = pcall(buffer.writei8,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 1
end

--[[
    Write a signed 8-bit integer (-128 to 127).
    - Clamped and truncated to integer.
    - 1 byte, big-endian N/A.
]]
function BufferComponent.WriteI8(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT8,Constants.MAX_INT8)
	local bytes = 1
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writei8,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 1
end

--[[
    Write a signed 16-bit integer (-32768 to 32767).
    - Clamped and truncated.
    - 2 bytes, big-endian via buffer.writei16.
]]
function BufferComponent.WriteI16(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT16,Constants.MAX_INT16)
	local bytes = 2
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writei16,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 2
end

--[[
    Write a signed 24-bit integer (-8,388,608 to 8,388,607).
    - Clamped and truncated.
    - 3 bytes, big-endian manual packing using bit32.extract.
]]
function BufferComponent.WriteI24(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.max(Constants.MIN_INT24,math.min(Constants.MAX_INT24,number))
	number = math.modf(number)
	local bytes = 3
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian: high byte first
		buffer.writeu8(self.buffer,self.offset + 0,bit32.extract(number,16,8))
		buffer.writeu8(self.buffer,self.offset + 1,bit32.extract(number,8,8))
		buffer.writeu8(self.buffer,self.offset + 2,bit32.extract(number,0,8))
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 3
end

--[[
    Write a signed 32-bit integer (-2,147,483,648 to 2,147,483,647).
    - Clamped and truncated.
    - 4 bytes, big-endian via buffer.writei32.
]]
function BufferComponent.WriteI32(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT32,Constants.MAX_INT32)
	local bytes = 4
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writei32,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 4
end

--[[
    Write a signed 40-bit integer (-549,755,813,888 to 549,755,813,887).
    - Clamped and truncated.
    - If negative, add 2^40 to represent as unsigned (two's complement style) before writing.
    - 5 bytes, big-endian manual packing.
]]
function BufferComponent.WriteI40(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT40,Constants.MAX_INT40)
	if(number < 0) then
		-- Convert negative to unsigned representation over 40 bits (two's complement range)
		number += 0x10000000000
	end
	local bytes = 5
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local succes,outOfBounds = pcall(function()
		-- Big-endian packing: 5 bytes from MSB to LSB
		buffer.writeu8(self.buffer,self.offset,math.floor(number / 0x100000000) % 0x100)
		buffer.writeu8(self.buffer,self.offset + 1,bit32.extract(number % 0x100000000, 24, 8))
		buffer.writeu8(self.buffer,self.offset + 2,bit32.extract(number % 0x100000000, 16, 8))
		buffer.writeu8(self.buffer,self.offset + 3,bit32.extract(number % 0x100000000, 8, 8))
		buffer.writeu8(self.buffer,self.offset + 4,bit32.extract(number % 0x100000000, 0, 8))
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 5
end

--[[
    Write a signed 48-bit integer (-140,737,488,355,328 to 140,737,488,355,327).
    - Clamped and truncated.
    - If negative, add 2^48 to represent as unsigned before writing.
    - 6 bytes, big-endian manual packing.
]]
function BufferComponent.WriteI48(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT48,Constants.MAX_INT48)
	if(number < 0) then
		-- Represent as 48-bit unsigned for storage
		number += 0x1000000000000 -- 2^48
	end
	local bytes = 6
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing: 6 bytes MSB -> LSB
		local byte6 = math.floor(number / 0x10000000000) % 0x100  -- Bits 40-47
		local byte5 = math.floor(number / 0x100000000) % 0x100    -- Bits 32-39
		local byte4 = bit32.extract(number % 0x100000000, 24, 8)  -- Bits 24-31
		local byte3 = bit32.extract(number % 0x100000000, 16, 8)  -- Bits 16-23
		local byte2 = bit32.extract(number % 0x100000000, 8, 8)   -- Bits 8-15
		local byte1 = bit32.extract(number % 0x100000000, 0, 8)   -- Bits 0-7
		buffer.writeu8(self.buffer,self.offset,byte6)
		buffer.writeu8(self.buffer,self.offset + 1,byte5)
		buffer.writeu8(self.buffer,self.offset + 2,byte4)
		buffer.writeu8(self.buffer,self.offset + 3,byte3)
		buffer.writeu8(self.buffer,self.offset + 4,byte2)
		buffer.writeu8(self.buffer,self.offset + 5,byte1)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 6
end

--[[
    Write a signed 54-bit integer (-9,007,199,254,740,992 to 9,007,199,254,740,991).
    - Clamped and truncated.
    - If negative, add 2^54 to represent as unsigned before writing.
    - 7 bytes, big-endian manual packing.
]]
function BufferComponent.WriteI54(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_INT54,Constants.MAX_INT54)
	if(number < 0) then
		-- Represent as 54-bit unsigned for storage
		number += Constants.MAX_UINT54
	end
	local bytes = 7
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing: 7 bytes MSB -> LSB
		local byte7 = math.floor(number / 0x1000000000000) % 0x100 -- Bits 48-53
		local byte6 = math.floor(number / 0x10000000000) % 0x100   -- Bits 40-47
		local byte5 = math.floor(number / 0x100000000) % 0x100     -- Bits 32-39
		local byte4 = bit32.extract(number % 0x100000000, 24, 8)   -- Bits 24-31
		local byte3 = bit32.extract(number % 0x100000000, 16, 8)   -- Bits 16-23
		local byte2 = bit32.extract(number % 0x100000000, 8, 8)    -- Bits 8-15
		local byte1 = bit32.extract(number % 0x100000000, 0, 8)    -- Bits 0-7
		buffer.writeu8(self.buffer, self.offset, byte7)
		buffer.writeu8(self.buffer, self.offset + 1, byte6)
		buffer.writeu8(self.buffer, self.offset + 2, byte5)
		buffer.writeu8(self.buffer, self.offset + 3, byte4)
		buffer.writeu8(self.buffer, self.offset + 4, byte3)
		buffer.writeu8(self.buffer, self.offset + 5, byte2)
		buffer.writeu8(self.buffer, self.offset + 6, byte1)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 7
end

--[[
    Write an unsigned 8-bit integer (0 to 255).
    - Clamped and truncated.
    - 1 byte.
]]
function BufferComponent.WriteU8(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT8)
	local bytes = 1
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writeu8,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 1
end

--[[
    Write an unsigned 16-bit integer (0 to 65,535).
    - Clamped and truncated.
    - 2 bytes, big-endian via buffer.writeu16.
]]
function BufferComponent.WriteU16(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT16)
	local bytes = 2
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writeu16,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 2
end

--[[
    Write an unsigned 24-bit integer (0 to 16,777,215).
    - Clamped and truncated.
    - 3 bytes, big-endian manual packing.
]]
function BufferComponent.WriteU24(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.max(Constants.MIN_UINT,math.min(Constants.MAX_UINT24,number))
	number = math.modf(number)
	local bytes = 3
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian manual packing
		buffer.writeu8(self.buffer,self.offset + 0,bit32.extract(number,16,8))
		buffer.writeu8(self.buffer,self.offset + 1,bit32.extract(number,8,8))
		buffer.writeu8(self.buffer,self.offset + 2,bit32.extract(number,0,8))
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 3
end

--[[
    Write an unsigned 32-bit integer (0 to 4,294,967,295).
    - Clamped and truncated.
    - 4 bytes, big-endian via buffer.writeu32.
]]
function BufferComponent.WriteU32(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT32)
	local bytes = 4
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writeu32,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 4
end

--[[
    Write an unsigned 40-bit integer (0 to 1,099,511,627,775).
    - Clamped.
    - 5 bytes, big-endian manual packing.
]]
function BufferComponent.WriteU40(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(number,Constants.MIN_UINT,Constants.MAX_UINT40)
	-- Precompute high part (top 8 bits) and low 32-bit remainder
	local byte5 = math.floor(number / 0x100000000) % 0x100 
	local remainder = number % 0x100000000
	local bytes = 5
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing
		buffer.writeu8(self.buffer, self.offset, byte5)
		buffer.writeu8(self.buffer, self.offset + 1, bit32.extract(remainder, 24, 8))
		buffer.writeu8(self.buffer, self.offset + 2, bit32.extract(remainder, 16, 8))
		buffer.writeu8(self.buffer, self.offset + 3, bit32.extract(remainder, 8, 8))
		buffer.writeu8(self.buffer, self.offset + 4, bit32.extract(remainder, 0, 8))
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 5
end

--[[
    Write an unsigned 48-bit integer (0 to 281,474,976,710,655).
    - Clamped and truncated.
    - 6 bytes, big-endian manual packing.
]]
function BufferComponent.WriteU48(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT48)
	local bytes = 6
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing: 6 bytes MSB -> LSB
		local byte6 = math.floor(number / 0x10000000000) % 0x100  -- Bits 40-47
		local byte5 = math.floor(number / 0x100000000) % 0x100    -- Bits 32-39
		local byte4 = bit32.extract(number % 0x100000000, 24, 8)  -- Bits 24-31
		local byte3 = bit32.extract(number % 0x100000000, 16, 8)  -- Bits 16-23
		local byte2 = bit32.extract(number % 0x100000000, 8, 8)   -- Bits 8-15
		local byte1 = bit32.extract(number % 0x100000000, 0, 8)   -- Bits 0-7
		buffer.writeu8(self.buffer,self.offset,byte6)
		buffer.writeu8(self.buffer,self.offset + 1,byte5)
		buffer.writeu8(self.buffer,self.offset + 2,byte4)
		buffer.writeu8(self.buffer,self.offset + 3,byte3)
		buffer.writeu8(self.buffer,self.offset + 4,byte2)
		buffer.writeu8(self.buffer,self.offset + 5,byte1)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 6
end

--[[
    Write an unsigned 54-bit integer (0 to 18,014,398,509,481,984).
    - Clamped and truncated.
    - 7 bytes, big-endian manual packing.
]]
function BufferComponent.WriteU54(self : BufferComponentClass,number : number) : ()
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT54)
	local bytes = 7
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		-- Big-endian packing: 7 bytes MSB -> LSB
		local byte7 = math.floor(number / 0x1000000000000) % 0x100 -- Bits 48-53
		local byte6 = math.floor(number / 0x10000000000) % 0x100   -- Bits 40-47
		local byte5 = math.floor(number / 0x100000000) % 0x100     -- Bits 32-39
		local byte4 = bit32.extract(number % 0x100000000, 24, 8)   -- Bits 24-31
		local byte3 = bit32.extract(number % 0x100000000, 16, 8)   -- Bits 16-23
		local byte2 = bit32.extract(number % 0x100000000, 8, 8)    -- Bits 8-15
		local byte1 = bit32.extract(number % 0x100000000, 0, 8)    -- Bits 0-7
		buffer.writeu8(self.buffer, self.offset, byte7)
		buffer.writeu8(self.buffer, self.offset + 1, byte6)
		buffer.writeu8(self.buffer, self.offset + 2, byte5)
		buffer.writeu8(self.buffer, self.offset + 3, byte4)
		buffer.writeu8(self.buffer, self.offset + 4, byte3)
		buffer.writeu8(self.buffer, self.offset + 5, byte2)
		buffer.writeu8(self.buffer, self.offset + 6, byte1)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 7
end

--[[
    Write a string clamped to max 8 characters.
    - `len` is the intended fixed length to write.
    - The input string is truncated to `len` (clamped to [MIN_STRING, MAX_STRING8]).
    - Important: this function writes a fixed number of bytes (len). The reader must know `len`.
]]
function BufferComponent.WriteString8(self : BufferComponentClass,value : string,len : number)
	assert(type(value) == "string" and type(len) == "number",`{type(value)} and {type(len)} is not valid please include a string and a number`)
	value = string.sub(value,1,math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING8))
	len = math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING8);
	if(buffer.len(self.buffer) < len) then
		warn(Debug["not enough space"]:format(len,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,len)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += len
end

--[[
    Write a string clamped to max 16 characters.
    See notes in WriteString8 regarding fixed-length writes and capacity check.
]]
function BufferComponent.WriteString16(self : BufferComponentClass,value : string,len : number)
	assert(type(value) == "string" and type(len) == "number",`{type(value)} and {type(len)} is not valid please include a string and a number`)
	value = string.sub(value,1,math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING16))
	len = math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING16);
	if(buffer.len(self.buffer) < len) then
		warn(Debug["not enough space"]:format(len,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,len)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += len
end

--[[
    Write a string clamped to max 32 characters.
    See notes in WriteString8 regarding fixed-length writes and capacity check.
]]
function BufferComponent.WriteString32(self : BufferComponentClass,value : string,len : number)
	assert(type(value) == "string" and type(len) == "number",`{type(value)} and {type(len)} is not valid please include a string and a number`)
	value = string.sub(value,1,math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING32))
	len = math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING32);
	if(buffer.len(self.buffer) < len) then
		warn(Debug["not enough space"]:format(len,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,len)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += len
end

--[[
    Write a string clamped to max 64 characters.
    See notes in WriteString8 regarding fixed-length writes and capacity check.
]]
function BufferComponent.WriteString64(self : BufferComponentClass,value : string,len : number)
	assert(type(value) == "string" and type(len) == "number",`{type(value)} and {type(len)} is not valid please include a string and a number`)
	value = string.sub(value,1,math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING64))
	len = math.clamp(len,Constants.MIN_STRING,Constants.MAX_STRING64);
	if(buffer.len(self.buffer) < len) then
		warn(Debug["not enough space"]:format(len,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,len)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += len
end

--[[
    Write a string without caring about length limits.
    - Writes exactly #value bytes.
    - Reader must know or infer the length (no prefix is written).
]]
function BufferComponent.WriteString(self : BufferComponentClass,value : string)
	assert(type(value) == "string","please insert a string to write")
	local bytes = #value
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writestring,self.buffer,self.offset,value,#value)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += #value
end

--[[
    Write a single boolean using 1 bit.
    - Document says "this takes 1 byte", but code writes only 1 bit.
    - nil/false -> 0, anything else -> 1
]]
function BufferComponent.WriteBool1(self : BufferComponentClass,value : any)
	local bytes = 1
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writebits,self.buffer,0,1,if(value) then 1 else 0)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 1
end

--[[
    Write 8 booleans packed into 1 byte.
    - Accepts an array-like table of up to 8 values.
    - Each truthy value sets the corresponding bit to 1.
]]
function BufferComponent.WriteBool8(self : BufferComponentClass,value : {any})
	assert(type(value) == "table","please insert an array")
	local bytes = 1
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		for i = 1,8 do
			buffer.writebits(self.buffer,self.offset * 8 + i-1,1,if(value[i]) then 1 else 0)
		end
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 1
end

--[[
    Write a 16-bit float (half-precision) to the buffer.
    - Lower precision than F32/F64; expect rounding.
    - NaN/Inf are handled; finite values are encoded with sign/exponent/mantissa.
]]
function BufferComponent.WriteF16(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	local bytes = 2
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		local uint16
		if number == 0 then
			uint16 = 0
		elseif number ~= number then  -- NaN
			uint16 = 0x7E00
		elseif number == math.huge then -- +inf
			uint16 = 0x7C00
		elseif number == -math.huge then -- -inf
			uint16 = 0xFC00
		else
			-- Determine sign
			local sign = 0
			if number < 0 then
				sign = 1
				number = -number
			end
			-- Binary scientific notation
			local exponent = math.floor(math.log(number, 2))
			local mantissa = number / (2 ^ exponent) - 1
			-- Bias exponent
			exponent = exponent + 15
			if exponent <= 0 then
				-- Denormalized
				mantissa = number / (2 ^ -14)
				exponent = 0
			elseif exponent >= 31 then
				-- Overflow -> Inf
				uint16 = bit32.bor(bit32.lshift(sign, 15), 0x7C00)
				buffer.writeu16(self.buffer, self.offset, uint16)
				return
			end
			-- Assemble the 16-bit value: [sign(1) | exponent(5) | mantissa(10)]
			uint16 = bit32.bor(
				bit32.lshift(sign, 15),
				bit32.lshift(exponent, 10),
				bit32.band(math.floor(mantissa * 1024), 0x3FF)
			)
		end
		-- Write as big-endian uint16
		buffer.writeu16(self.buffer, self.offset, uint16)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 2
end

--[[
    Write a 32-bit float to the buffer.
    - Clamped to [MIN_FLOAT32, MAX_FLOAT32].
    - 4 bytes, big-endian.
]]
function BufferComponent.WriteF32(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(number,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32)
	local bytes = 4
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writef32,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 4
end

--[[
    Write a 64-bit float to the buffer.
    - Clamped to [MIN_FLOAT64, MAX_FLOAT64].
    - 8 bytes, big-endian.
]]
function BufferComponent.WriteF64(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(number,Constants.MIN_FLOAT64,Constants.MAX_FLOAT64)
	local bytes = 8
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writef64,self.buffer,self.offset,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += 8
end

--[[
    Write a single unsigned bit (0 or 1).
    - Reserves 1 byte (by design)
]]
function BufferComponent.WriteU1(self : BufferComponentClass,number : number)
	if(not number or type(number) ~= "number") then
		error(Debug["not a valid type"]:format(type(number),type(10)))
	end
	number = math.clamp(math.modf(number),Constants.MIN_UINT,Constants.MAX_UINT1)
	local bytes = 1
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(buffer.writebits,self.buffer,self.offset * 8,1,number)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Store an Instance in the side `instance_buffer`.
    - Does not write anything to the raw byte buffer.
    - `instance_offset` is incremented to track count/index.
]]
function BufferComponent.WriteInstance(self : BufferComponentClass,Instance : Instance)
	if(not Instance or not Instance:IsA("Instance")) then warn(`{Instance} is not a Instance.`) return end
	table.insert(self.instance_buffer,Instance)
	self.instance_offset += 1
end

--[[
    Write a Vector2 as two f64 (x, y).
    - 16 bytes total.
    - Values are clamped to float64 range.
]]
function BufferComponent.WriteVector2(self : BufferComponentClass,vector2 : Vector2)
	assert(typeof(vector2) == "Vector2","vector2 must be a Vector2")
	local x = math.clamp(vector2.X,Constants.MIN_FLOAT64,Constants.MAX_FLOAT64)
	local y = math.clamp(vector2.Y,Constants.MIN_FLOAT64,Constants.MAX_FLOAT64)
	local bytes = 16
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef64(self.buffer,self.offset,x)
		buffer.writef64(self.buffer,self.offset + 8,y)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Write a Vector3 as three f64 (x, y, z).
    - 24 bytes total.
    - Values are clamped to float64 range.
]]
function BufferComponent.WriteVector3(self : BufferComponentClass,vector3 : Vector3)
	assert(typeof(vector3) == "Vector3","vector3 must be a Vector3")
	local x = math.clamp(vector3.X,Constants.MIN_FLOAT64,Constants.MAX_FLOAT64)
	local y = math.clamp(vector3.Y,Constants.MIN_FLOAT64,Constants.MAX_FLOAT64)
	local z = math.clamp(vector3.Z,Constants.MIN_FLOAT64,Constants.MAX_FLOAT64)
	local bytes = 24
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef64(self.buffer,self.offset,x)
		buffer.writef64(self.buffer,self.offset + 8,y)
		buffer.writef64(self.buffer,self.offset + 16,z)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Write a Vector2int16 as two i16 (x, y).
    - 4 bytes total.
    - Values clamped to int16 range.
]]
function BufferComponent.WriteVector2Int16(self : BufferComponentClass,vector2int16 : Vector2int16)
	assert(typeof(vector2int16) == "Vector2int16","vector2int16 must be a Vector2int16")
	local x = math.clamp(vector2int16.X,Constants.MIN_INT16,Constants.MAX_INT16)
	local y = math.clamp(vector2int16.Y,Constants.MIN_INT16,Constants.MAX_INT16)
	local bytes = 4
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writei16(self.buffer,self.offset,x)
		buffer.writei16(self.buffer,self.offset + 2,y)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Write a Vector3int16 as three i16 (x, y, z).
    - 6 bytes total.
    - Values clamped to int16 range.
]]
function BufferComponent.WriteVector3Int16(self : BufferComponentClass,vector3int16 : Vector3int16)
	assert(typeof(vector3int16) == "Vector3int16","vector3int16 must be a Vector3int16")
	local x = math.clamp(vector3int16.X,Constants.MIN_INT16,Constants.MAX_INT16)
	local y = math.clamp(vector3int16.Y,Constants.MIN_INT16,Constants.MAX_INT16)
	local z = math.clamp(vector3int16.Z,Constants.MIN_INT16,Constants.MAX_INT16)
	local bytes = 6
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writei16(self.buffer,self.offset,x)
		buffer.writei16(self.buffer,self.offset + 2,y)
		buffer.writei16(self.buffer,self.offset + 4,z)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Write a full-precision CFrame as 12 f64 components (position + rotation matrix).
    - 12 * 8 = 96 bytes total.

    Endianness: buffer.writef64 is big-endian.
]]
function BufferComponent.WriteCFrame(self : BufferComponentClass,CF : CFrame)
	assert(typeof(CF) == "CFrame","CF must be a CFrame")
	local bytes = 96 
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		local components = {CF:GetComponents()}
		for i = 0, 11 do
			buffer.writef64(self.buffer, self.offset + (i * 8), components[i + 1])
		end
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Write a lossy (compressed) CFrame as 12 f32 components.
    - 12 * 4 = 48 bytes total.
    - Less precision than WriteCFrame but smaller.
]]
function BufferComponent.WriteLossyCFrame(self : BufferComponentClass,CF : CFrame)
	assert(typeof(CF) == "CFrame","CF must be a CFrame")
	local bytes = 48
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		local components = {CF:GetComponents()}
		for i = 0, 11 do
			buffer.writef32(self.buffer, self.offset + (i * 4), components[i + 1])
		end
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Write a UDim as two f32 (Scale, Offset).
    - 8 bytes total.
]]
function BufferComponent.WriteUdim(self : BufferComponentClass,udim : UDim)
	assert(typeof(udim) == "UDim","Udim must be a Udim")
	local Scale = math.clamp(udim.Scale,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32)
	local Offset = math.clamp(udim.Offset,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32)
	local bytes = 8
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef32(self.buffer,self.offset,Scale)
		buffer.writei32(self.buffer,self.offset + 4,Offset)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Write a UDim2 as four f32 (X.Scale, Y.Scale, X.Offset, Y.Offset).
    - 16 bytes total.
]]
function BufferComponent.WriteUdim2(self : BufferComponentClass,udim2 : UDim2)
	assert(typeof(udim2) == "UDim2","Udim2 must be a Udim2")
	local ScaleX,ScaleY = math.clamp(udim2.X.Scale,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32),math.clamp(udim2.Y.Scale,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32)
	local OffsetX,OffsetY = math.clamp(udim2.X.Offset,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32),math.clamp(udim2.Y.Offset,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32)
	local bytes = 16
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef32(self.buffer,self.offset,ScaleX)
		buffer.writef32(self.buffer,self.offset + 4,ScaleY)
		buffer.writei32(self.buffer,self.offset + 8,OffsetX)
		buffer.writei32(self.buffer,self.offset + 12,OffsetY)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Write a Color3 as three f32 (r, g, b).
    - 12 bytes total.
    - Values clamped to float32 range [0,1] typically already valid.
]]
function BufferComponent.WriteColor3(self : BufferComponentClass,color : Color3)
	assert(typeof(color) == "Color3","color must be a Color3")
	local bytes = 12
	local r = math.clamp(color.R,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32)
	local g = math.clamp(color.G,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32)
	local b = math.clamp(color.B,Constants.MIN_FLOAT32,Constants.MAX_FLOAT32)
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local success,outOfBounds = pcall(function()
		buffer.writef32(self.buffer,self.offset,r)
		buffer.writef32(self.buffer,self.offset + 4,g)
		buffer.writef32(self.buffer,self.offset + 8,b)
	end)
	if(outOfBounds) then
		if(Debug[outOfBounds]) then
			warn(outOfBounds, "-" , Debug[outOfBounds])
		else
			warn(outOfBounds)
		end
		return
	end
	self.offset += bytes
end

--[[
    Write a Rect as two Vector2 (Min, Max) using f64.
    - 32 bytes total (2 * 16).
    - Relies on WriteVector2 to do the actual writing and offset increments.
]]
function BufferComponent.WriteRect(self : BufferComponentClass,rect : Rect)
	assert(typeof(rect) == "Rect","rect must be a Rect")
	local bytes = 32
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	self:WriteVector2(rect.Min)
	self:WriteVector2(rect.Max)
end

--[[
    Write a Region3 as CFrame + Size.
    - Intended: CFrame (12 f64 = 96 bytes) + Vector3 (3 f64 = 24 bytes) = 120 bytes.
]]
function BufferComponent.WriteRegion3(self : BufferComponentClass,region3 : Region3)
	assert(typeof(region3) == "Region3","region3 must be a Region3")
	local bytes = 120
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local cframe = region3.CFrame
	local size = region3.Size
	self:WriteCFrame(cframe)
	self:WriteVector3(size)
end

--[[
    Write a Region3int16 as two Vector3int16 (Max then Min).
    - 12 bytes total (2 * 6).
]]
function BufferComponent.WriteRegion3int16(self : BufferComponentClass,region3int16 : Region3int16)
	assert(typeof(region3int16) == "Region3int16","region3int16 must be a Region3int16")
	local bytes = 12
	if(buffer.len(self.buffer) < bytes) then
		warn(Debug["not enough space"]:format(bytes,string.sub(debug.info(1,"n"),6)))
		return
	end
	local max = region3int16.Max
	local min = region3int16.Min
	self:WriteVector3Int16(max)
	self:WriteVector3Int16(min)
end


-->-----------------------READER-----------------------------<--

--[[
  Read a Signed 1-bit integer from the buffer.

  Range: -1 - 1
  
   Returns:
  - number on success
  - nil on failure (warns)
]]
function BufferComponent.ReadI1(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return buffer.readi8(self.buffer, offset)
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 8-bit integer from the buffer (byte-aligned).
  Returns number in [-128, 127] or nil on failure.
]]
function BufferComponent.ReadI8(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readi8, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 16-bit integer from the buffer (byte-aligned).
  Endianness is whatever buffer.readi16 uses in your environment.
  Returns number in [-32768, 32767] or nil on failure.
]]
function BufferComponent.ReadI16(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readi16, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 24-bit integer (big-endian) from the buffer.

  Returns:
  - number in [-2^23, 2^23-1] on success
  - nil on failure (warns)
]]
function BufferComponent.ReadI24(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local value = bit32.bor(
			bit32.lshift(b1, 16),
			bit32.lshift(b2, 8),
			b3
		)
		if b1 >= 0x80 then -- sign bit set (2^7 in the MSB)
			value = value - 0x1000000 -- subtract 2^24
		end
		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 32-bit integer from the buffer.
  Returns number in [-2^31, 2^31-1] or nil on failure.
]]
function BufferComponent.ReadI32(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readi32, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 40-bit integer (big-endian) from the buffer.

  Range:
  - -2^39 .. 2^39-1

  Returns:
  - number on success (exactly representable in double for 40-bit)
  - nil on failure (warns)
]]
function BufferComponent.ReadI40(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local b4 = buffer.readu8(self.buffer, offset + 3)
		local b5 = buffer.readu8(self.buffer, offset + 4)
		local value =
			b1 * 0x100000000 + -- 2^32
			b2 * 0x1000000   + -- 2^24
			b3 * 0x10000     + -- 2^16
			b4 * 0x100       + -- 2^8
			b5                -- 2^0
		if value >= 0x8000000000 then  -- 2^39
			value = value - 0x10000000000 -- 2^40
		end
		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end

--[[
  Read a Signed 48-bit integer (big-endian) from the buffer.

  Range:
    -2^47 .. 2^47-1  (i.e., -140737488355328 .. 140737488355327)

  Returns:
  - number on success (exactly representable in double for 48-bit)
  - nil on failure (warns)
]]
function BufferComponent.ReadI48(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local b4 = buffer.readu8(self.buffer, offset + 3)
		local b5 = buffer.readu8(self.buffer, offset + 4)
		local b6 = buffer.readu8(self.buffer, offset + 5)
		local value =
			b1 * 0x10000000000 + -- 2^40
			b2 * 0x100000000   + -- 2^32
			b3 * 0x1000000     + -- 2^24
			b4 * 0x10000       + -- 2^16
			b5 * 0x100         + -- 2^8
			b6                  -- 2^0
		-- Two's complement sign fix: if value >= 2^47, subtract 2^48
		if value >= 0x800000000000 then
			value = value - 0x1000000000000
		end
		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Signed 54-bit integer (big-endian) from the buffer.

  Range:
  -2^53 .. 2^53-1

  Returns:
  - number on success
  - nil on failure (warns)
]]
function BufferComponent.ReadI54(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local byte7 = buffer.readu8(self.buffer, offset + 0)
		local byte6 = buffer.readu8(self.buffer, offset + 1)
		local byte5 = buffer.readu8(self.buffer, offset + 2)
		local byte4 = buffer.readu8(self.buffer, offset + 3)
		local byte3 = buffer.readu8(self.buffer, offset + 4)
		local byte2 = buffer.readu8(self.buffer, offset + 5)
		local byte1 = buffer.readu8(self.buffer, offset + 6)
		-- Mask to 54 bits: keep only lower 6 bits of the MSB
		local msb54 = bit32.band(byte7, 0x3F)
		local value =
			msb54 * 0x1000000000000 + -- 2^48 (with only 6 bits in msb54, total width = 54 bits)
			byte6 * 0x10000000000   + -- 2^40
			byte5 * 0x100000000     + -- 2^32
			byte4 * 0x1000000       + -- 2^24
			byte3 * 0x10000         + -- 2^16
			byte2 * 0x100           + -- 2^8
			byte1                    -- 2^0

		-- Two's complement sign fix for 54-bit:
		-- If value >= 2^53, subtract 2^54
		if value >= 0x20000000000000 then
			value = value - 0x40000000000000
		end

		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read 1 unsigned bit from the buffer.

  Returns:
  - 0 or 1 on success
  - nil on failure (warns)
]]
function BufferComponent.ReadU1(self : BufferComponentClass, offset : number) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local bitOffset = offset * 8
	local success, valueORoutOfBounds = pcall(buffer.readbits, self.buffer, bitOffset, 1)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 8-bit integer (byte) from the buffer.
  Returns number in [0, 255] or nil on failure.
]]
function BufferComponent.ReadU8(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readu8, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 16-bit integer (big-endian) from the buffer.
  Returns number in [0, 65535] or nil on failure.
]]
function BufferComponent.ReadU16(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readu16, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 24-bit integer (big-endian) from the buffer.

  Returns:
  - number on success
  - nil on failure (warns)
]]
function BufferComponent.ReadU24(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset

	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local value = bit32.bor(bit32.lshift(b1, 16), bit32.lshift(b2, 8), b3)
		return value
	end)

	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 32-bit integer from the buffer.
  Returns number in [0, 2^32-1] (may lose precision above 2^24 in double, but Roblox API provides u32).
]]
function BufferComponent.ReadU32(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readu32, self.buffer, offset)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 40-bit integer (big-endian) from the buffer.

  Returns:
  - number on success (exact for 40-bit in double)
  - nil on failure (warns)
]]
function BufferComponent.ReadU40(self : BufferComponentClass, offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset

	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local b4 = buffer.readu8(self.buffer, offset + 3)
		local b5 = buffer.readu8(self.buffer, offset + 4)

		local value =
			b1 * 0x100000000 + -- 2^32
			b2 * 0x1000000   + -- 2^24
			b3 * 0x10000     + -- 2^16
			b4 * 0x100       + -- 2^8
			b5                -- 2^0
		return value
	end)
	if not success and valueORoutOfBounds then
		if Debug[valueORoutOfBounds] then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end

--[[
  Read an Unsigned 48-bit integer from the buffer (6 bytes, big-endian by default).

  Returns:
  - number in [0, 2^48 - 1] on success (exactly representable in double)
  - nil on failure (warns)
]]
function BufferComponent.ReadU48(self : BufferComponentClass,offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local b1 = buffer.readu8(self.buffer, offset + 0)
		local b2 = buffer.readu8(self.buffer, offset + 1)
		local b3 = buffer.readu8(self.buffer, offset + 2)
		local b4 = buffer.readu8(self.buffer, offset + 3)
		local b5 = buffer.readu8(self.buffer, offset + 4)
		local b6 = buffer.readu8(self.buffer, offset + 5)
		-- 0x10000000000 = 2^40,
		-- 0x100000000 = 2^32,
		-- 0x100 = 2^8
		local value =
			b1 * 0x10000000000 + -- 2^40
			b2 * 0x100000000   + -- 2^32
			b3 * 0x1000000     + -- 2^24
			b4 * 0x10000       + -- 2^16
			b5 * 0x100         + -- 2^8
			b6                  -- 2^0
		return value
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Unsigned 54-bit integer from the buffer.

  Returns:
  - number on success
  - nil on failure (warns)
]]
function BufferComponent.ReadU54(self : BufferComponentClass,offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local byte7 = buffer.readu8(self.buffer, offset + 0)
		local byte6 = buffer.readu8(self.buffer, offset + 1)
		local byte5 = buffer.readu8(self.buffer, offset + 2)
		local byte4 = buffer.readu8(self.buffer, offset + 3)
		local byte3 = buffer.readu8(self.buffer, offset + 4)
		local byte2 = buffer.readu8(self.buffer, offset + 5)
		local byte1 = buffer.readu8(self.buffer, offset + 6)
		-- 0x1000000000000 = 2^48, 0x10000000000 = 2^40, ..., 0x100 = 2^8
		local value =
			byte7 * 0x1000000000000 + -- 2^48
			byte6 * 0x10000000000   + -- 2^40
			byte5 * 0x100000000     + -- 2^32
			byte4 * 0x1000000       + -- 2^24
			byte3 * 0x10000         + -- 2^16
			byte2 * 0x100           + -- 2^8
			byte1                    -- 2^0
		return value
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a String from the buffer.

  Parameters:
  - len: number of bytes to read. If omitted, defaults to Constants.MIN_STRING.
  - offset (optional): byte offset to read from. If omitted/invalid, falls back to self.offset.

  Returns:
  - string on success
  - nil on failure (warns)
]]
function BufferComponent.ReadString(self : BufferComponentClass,len : number,offset : number?) : string | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	len = math.clamp(len,Constants.MIN_STRING,math.huge)
	local success, valueORoutOfBounds = pcall(buffer.readstring, self.buffer, offset, len)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a 1-bit boolean from the buffer at a given bit offset.

  Returns:
  - boolean on success
  - nil on failure (warns)
]]
function BufferComponent.ReadBool1(self : BufferComponentClass,offset : number?) : boolean | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return (buffer.readbits(self.buffer, offset * 8, 1) == 1) and true or false
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read 8 booleans (1 bit each) starting at a given bit offset.

  Returns:
  - A table:
      {
        value = {bool, bool, ..., bool}, -- the 8 bits in order
        majority = function(): boolean   -- true if more trues than falses
      }
]]
function BufferComponent.ReadBool8(self : BufferComponentClass,offset : number?) : Readbool8ReturnType | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local booleans = {}
		for i = 0, 7 do
			-- Each read advances 1 bit from the starting bit offset.
			local boolean_bits : boolean = (buffer.readbits(self.buffer, offset * 8 + i, 1) == 1) and true or false
			table.insert(booleans, boolean_bits)
		end
		return {
			value = booleans,
			majority = function() : boolean
				local teamTrue = 0
				local teamFalse = 0
				for _, bool in next, booleans do
					if bool == true then
						teamTrue += 1 -- If not supported, use: teamTrue = teamTrue + 1
					else
						teamFalse += 1 -- If not supported, use: teamFalse = teamFalse + 1
					end
				end
				return (teamTrue > teamFalse) and true or false
			end,
		}
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a 16-bit half-precision float (IEEE 754 binary16) from the buffer.

  Encoding:
  - 1 sign bit, 5 exponent bits (bias 15), 10 mantissa bits.

  Returns:
  - number on success (double-precision representation of the half)
  - nil on failure (warns)

  Notes on special cases:
  - Exponent == 0 and mantissa == 0 => +/- 0
  - Exponent == 0 and mantissa != 0 => denormalized number
  - Exponent == 31 (all ones):
      * mantissa == 0 => +/- infinity
      * mantissa != 0 => NaN
]]
function BufferComponent.ReadF16(self : BufferComponentClass,offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		-- Read the 16-bit word
		local uint16 = buffer.readu16(self.buffer, offset)
		-- Extract sign (1 bit), exponent (5 bits), mantissa (10 bits)
		local sign = bit32.rshift(uint16, 15)
		local exponent = bit32.band(bit32.rshift(uint16, 10), 0x1F)
		local mantissa = bit32.band(uint16, 0x3FF)
		-- Special cases
		if exponent == 0 then
			if mantissa == 0 then
				-- +/- 0
				return sign == 0 and 0 or -0
			else
				-- Denormalized number
				local value = (mantissa / 1024) * (2 ^ -14)
				return sign == 0 and value or -value
			end
		elseif exponent == 31 then
			if mantissa == 0 then
				-- +/- infinity
				return sign == 0 and math.huge or -math.huge
			else
				-- NaN
				return 0/0
			end
		end
		-- Normalized number
		local value = (1 + mantissa / 1024) * (2 ^ (exponent - 15))
		return sign == 0 and value or -value
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end

--[[
  Read a Float32 from the buffer at the given offset (or self.offset if not provided/valid).

  Returns:
  - number on success
  - nil on failure (warns)
]]
function BufferComponent.ReadF32(self : BufferComponentClass,offset : number?) : number | nil
	-- Choose the effective offset. Uses the provided "offset" only if it's <= self.offset.
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	-- Wrap in pcall: buffer.readf32 will throw on out-of-bounds or invalid use.
	local success, valueORoutOfBounds = pcall(buffer.readf32, self.buffer, offset)
	if (not success and valueORoutOfBounds) then
		-- Try to show a human-friendly message if available in Debug
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		-- On success, the second return value is the f32 read
		return valueORoutOfBounds
	end
end


--[[
  Read a Float64 from the buffer at the given offset (or self.offset if not provided/valid).

  Returns:
  - number on success
  - nil on failure (warns)
]]
function BufferComponent.ReadF64(self : BufferComponentClass,offset : number?) : number | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(buffer.readf64, self.buffer, offset)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read an Instance from self.instance_buffer at the given index (or self.instance_offset).

  Returns:
  - Instance or nil
]]
function BufferComponent.ReadInstance(self : BufferComponentClass,instance_offset : number?) : Instance | nil
	local instance_offset = (type(instance_offset) == "number" and instance_offset <= self.instance_offset) and instance_offset or self.instance_offset
	return self.instance_buffer[instance_offset]
end


--[[
  Read a Vector2 (double-precision) from the buffer:
  - X at [offset + 0], Y at [offset + 8], both f64.

  Returns:
  - Vector2 on success
  - nil on failure (warns)
]]
function BufferComponent.ReadVector2(self : BufferComponentClass,offset : number?) : Vector2 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return Vector2.new(
			buffer.readf64(self.buffer, offset),
			buffer.readf64(self.buffer, offset + 8)
		)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Vector2int16 from the buffer:
  - X at [offset + 0], Y at [offset + 2], both i16.

  Returns:
  - Vector2int16 on success
  - nil on failure (warns)
]]
function BufferComponent.ReadVector2int16(self : BufferComponentClass,offset : number?) : Vector2int16 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return Vector2int16.new(
			buffer.readi16(self.buffer, offset),
			buffer.readi16(self.buffer, offset + 2)
		)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Vector3 (double-precision) from the buffer:
  - X at [offset + 0], Y at [offset + 8], Z at [offset + 16], all f64.

  Returns:
  - Vector3 on success
  - nil on failure (warns)
]]
function BufferComponent.ReadVector3(self : BufferComponentClass,offset : number?) : Vector3 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return Vector3.new(
			buffer.readf64(self.buffer, offset),
			buffer.readf64(self.buffer, offset + 8),
			buffer.readf64(self.buffer, offset + 16)
		)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Vector3int16 from the buffer:
  - X at [offset + 0], Y at [offset + 2], Z at [offset + 4], all i16.

  Returns:
  - Vector3int16 on success
  - nil on failure (warns)
]]
function BufferComponent.ReadVector3int16(self : BufferComponentClass,offset : number?) : Vector3int16 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		return Vector3int16.new(
			buffer.readi16(self.buffer, offset),
			buffer.readi16(self.buffer, offset + 2),
			buffer.readi16(self.buffer, offset + 4)
		)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a CFrame (double-precision) from the buffer:
  - Reads 12 f64s at [offset + i*8], i ∈ [0..11].
  - Constructs CFrame.new(...) from these 12 components.

  Returns:
  - CFrame on success
  - nil on failure (warns)
]]
function BufferComponent.ReadCFrame(self : BufferComponentClass,offset : number?) : CFrame | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local components = {}
		for i = 0, 11 do
			components[i + 1] = buffer.readf64(self.buffer, offset + (i * 8))
		end
		return CFrame.new(table.unpack(components))
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a "Lossy" CFrame (single-precision) from the buffer:
  - Reads 12 f32s at [offset + i*4], i ∈ [0..11].
  - Lower precision than ReadCFrame; saves space.

  Returns:
  - CFrame on success
  - nil on failure (warns)
]]
function BufferComponent.ReadLossyCFrame(self : BufferComponentClass,offset : number?) : CFrame | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local components = {}
		for i = 0, 11 do
			components[i + 1] = buffer.readf32(self.buffer, offset + (i * 4))
		end
		return CFrame.new(table.unpack(components))
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a UDim from the buffer:
  - scale (f32) then offset (f32 here) => UDim.new(scale, offset)

  Returns:
  - UDim on success
  - nil on failure (warns)
]]
function BufferComponent.ReadUDim(self : BufferComponentClass,offset : number?) : UDim | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local scale = buffer.readf32(self.buffer,offset)
		local Udim_offset = buffer.readi32(self.buffer,offset + 4)
		return UDim.new(scale, Udim_offset)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a UDim2 from the buffer:
  - scaleX (f32), scaleY (f32), offsetX (i32), offsetY (i32) in that order.
  - Returns UDim2.new(scaleX, offsetX, scaleY, offsetY)

  Returns:
  - UDim2 on success
  - nil on failure (warns)
]]
function BufferComponent.ReadUDim2(self : BufferComponentClass,offset : number?) : UDim2 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local scaleX, scaleY = buffer.readf32(self.buffer, offset), buffer.readf32(self.buffer, offset + 4)
		local offsetX, offsetY = buffer.readi32(self.buffer, offset + 8), buffer.readi32(self.buffer, offset + 12)
		return UDim2.new(scaleX, offsetX, scaleY, offsetY)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Color3 from the buffer:
  - r, g, b as f32s in [0, 1] (assumed), then scaled to [0, 255] for Color3.fromRGB.

  Returns:
  - Color3 on success
  - nil on failure (warns)
]]
function BufferComponent.ReadColor3(self : BufferComponentClass,offset : number?) : Color3 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local success, valueORoutOfBounds = pcall(function()
		local r = buffer.readf32(self.buffer, offset) * 255
		local g = buffer.readf32(self.buffer, offset + 4) * 255
		local b = buffer.readf32(self.buffer, offset + 8) * 255
		return Color3.fromRGB(r, g, b)
	end)
	if (not success and valueORoutOfBounds) then
		if (Debug[valueORoutOfBounds]) then
			warn(valueORoutOfBounds, "-", Debug[valueORoutOfBounds])
		else
			warn(valueORoutOfBounds)
		end
		return
	else
		return valueORoutOfBounds
	end
end


--[[
  Read a Rect from the buffer:
  - Two Vector2 (double-precision) values back-to-back: typically min then max (or vice versa).
  - This implementation reads:
      max = ReadVector2(offset)
      min = ReadVector2(offset + 16)
    and returns Rect.new(min, max).

  Returns:
  - Rect on success
  - nil on failure (if nested reads fail)
]]
function BufferComponent.ReadRect(self : BufferComponentClass,offset : number?) : Rect | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local max = self:ReadVector2(offset)
	local min = self:ReadVector2(offset + 16)
	return Rect.new(min, max)
end


--[[
  Read a Region3 from the buffer:
  - Interprets data as: CFrame (f64 x12, 96 bytes) followed by a Vector3 size (f64 x3, 24 bytes).
  - Constructs an AABB-aligned Region3 centered at cframe.Position with extents 'size'.

  Returns:
  - Region3 on success
  - nil on failure (if nested reads fail)
]]
function BufferComponent.ReadRegion3(self : BufferComponentClass,offset : number?) : Region3 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local cframe = self:ReadCFrame(offset)
	local size = self:ReadVector3(offset + 96)
	local halfSize = size * 0.5
	local min = cframe.Position - halfSize
	local max = cframe.Position + halfSize
	return Region3.new(min, max)
end


--[[
  Read a Region3int16 from the buffer:
  - Two Vector3int16 in sequence: min then max (or vice versa).
  - This implementation reads:
      max = ReadVector3int16(offset)
      min = ReadVector3int16(offset + 6)
    and returns Region3int16.new(min, max).

  Returns:
  - Region3int16 on success
  - nil on failure (if nested reads fail)
]]
function BufferComponent.ReadRegion3int16(self : BufferComponentClass,offset : number?) : Region3int16 | nil
	local offset = (type(offset) == "number" and offset <= self.offset) and offset or self.offset
	local max = self:ReadVector3int16(offset)
	local min = self:ReadVector3int16(offset + 6)
	return Region3int16.new(min, max)
end


-->-----------------------Cursor/Buffer-----------------------------<--

--[[
	return the actual offset of the buffer
]]
function BufferComponent.GetOffset(self : BufferComponentClass)
	return self.offset
end

--[[
	return the actual instance offset of the buffer
]]
function BufferComponent.GetInstanceOffset(self : BufferComponentClass)
	return self.instance_offset
end

--[[
	return the current buffer
]]
function BufferComponent.GetBuffer(self : BufferComponentClass)
	return self.buffer
end

--[[
	return the current instance buffer
]]
function BufferComponent.GetInstanceBuffer(self : BufferComponentClass)
	return self.instance_buffer
end

--[[
	return the actual buffer size (not the written data size)
]]
function BufferComponent.GetBufferSize(self : BufferComponentClass)
	return buffer.len(self.buffer)
end

--[[
	clear the buffer to a new one with the same size
	the offset is also set to 0.
]]
function BufferComponent.clear(self : BufferComponentClass)
	local buffer_blank = buffer.create(buffer.len(self.buffer))
	self.buffer = buffer_blank
	self.offset = 0
end

--[[
	Destroy the actual BufferComponent.
	You can't use the BufferComponent after this.
]]
function BufferComponent.Destroy(self : BufferComponentClass)
	self.buffer = nil :: any
	self.instance_buffer = nil :: any
	self.instance_offset = nil :: any
	self.offset = nil :: any
	table.clear(self :: any)
	self = nil :: any
end

--Constructor alias
BufferConstructor.new = BufferConstructor.create
BufferConstructor.New = BufferConstructor.create
BufferConstructor.From = BufferConstructor.from
BufferConstructor.FromString = BufferConstructor.fromString
BufferConstructor.Tostring = BufferConstructor.tostring

--Component alias
BufferComponent.Allocate = BufferComponent.allocate

--[Writer] signed interger alias
BufferComponent.writeI1 = BufferComponent.WriteI1
BufferComponent.writei1 = BufferComponent.WriteI1
BufferComponent.writeI8 = BufferComponent.WriteI8
BufferComponent.writei8 = BufferComponent.WriteI8
BufferComponent.writeI16 = BufferComponent.WriteI16
BufferComponent.writei16 = BufferComponent.WriteI16
BufferComponent.writeI24 = BufferComponent.WriteI24
BufferComponent.writei24 = BufferComponent.WriteI24
BufferComponent.writeI32 = BufferComponent.WriteI32
BufferComponent.writei32 = BufferComponent.WriteI32
BufferComponent.writeI40 = BufferComponent.WriteI40
BufferComponent.writei40 = BufferComponent.WriteI40
BufferComponent.writeI48 = BufferComponent.WriteI48
BufferComponent.writei48 = BufferComponent.WriteI48
BufferComponent.writeI54 = BufferComponent.WriteI54
BufferComponent.writei54 = BufferComponent.WriteI54

--[Writer] unsigned interger alias
BufferComponent.writeU1 = BufferComponent.WriteU1
BufferComponent.writeu1 = BufferComponent.WriteU1
BufferComponent.writeU8 = BufferComponent.WriteU8
BufferComponent.writeu8 = BufferComponent.WriteU8
BufferComponent.writeU16 = BufferComponent.WriteU16
BufferComponent.writeu16 = BufferComponent.WriteU16
BufferComponent.writeU24 = BufferComponent.WriteU24
BufferComponent.writeu24 = BufferComponent.WriteU24
BufferComponent.writeU32 = BufferComponent.WriteU32
BufferComponent.writeu32 = BufferComponent.WriteU32
BufferComponent.writeU40 = BufferComponent.WriteU40
BufferComponent.writeu40 = BufferComponent.WriteU40
BufferComponent.writeU48 = BufferComponent.WriteU48
BufferComponent.writeu48 = BufferComponent.WriteU48
BufferComponent.writeU54 = BufferComponent.WriteU54
BufferComponent.writeu54 = BufferComponent.WriteU54

--[Writer] float interger alias
BufferComponent.writeF16 = BufferComponent.WriteF16
BufferComponent.writef16 = BufferComponent.WriteF16
BufferComponent.writeF32 = BufferComponent.WriteF32
BufferComponent.writef32 = BufferComponent.WriteF32
BufferComponent.writeF64 = BufferComponent.WriteF64
BufferComponent.writef64 = BufferComponent.WriteF64

--[Writer] string alias
BufferComponent.writeString8 = BufferComponent.WriteString8
BufferComponent.writestring8 = BufferComponent.WriteString8
BufferComponent.writeString16 = BufferComponent.WriteString16
BufferComponent.writestring16 = BufferComponent.WriteString16
BufferComponent.writeString32 = BufferComponent.WriteString32
BufferComponent.writestring32 = BufferComponent.WriteString32
BufferComponent.writeString64 = BufferComponent.WriteString64
BufferComponent.writestring64 = BufferComponent.WriteString64
BufferComponent.writeString = BufferComponent.WriteString
BufferComponent.writestring = BufferComponent.WriteString

--[Writer] boolean alias
BufferComponent.writeBool1 = BufferComponent.WriteBool1
BufferComponent.writebool1 = BufferComponent.WriteBool1
BufferComponent.writeBool8 = BufferComponent.WriteBool8
BufferComponent.writebool8 = BufferComponent.WriteBool8


--[Writer] instance alias
BufferComponent.writeInstance = BufferComponent.WriteInstance
BufferComponent.writeinstance = BufferComponent.WriteInstance

--[Writer] roblox type alias
BufferComponent.writeVector2 = BufferComponent.WriteVector2
BufferComponent.writevector2 = BufferComponent.WriteVector2
BufferComponent.writeVector2int16 = BufferComponent.WriteVector2Int16
BufferComponent.writevector2int16 = BufferComponent.WriteVector2Int16
BufferComponent.writeVector3 = BufferComponent.WriteVector3
BufferComponent.writevector3 = BufferComponent.WriteVector3
BufferComponent.writeVector3int16 = BufferComponent.WriteVector3Int16
BufferComponent.writevector3int16 = BufferComponent.WriteVector3Int16
BufferComponent.writeCFrame = BufferComponent.WriteCFrame
BufferComponent.writecframe = BufferComponent.WriteCFrame
BufferComponent.writeLossyCFrame = BufferComponent.WriteLossyCFrame
BufferComponent.writelossyCFrame = BufferComponent.WriteLossyCFrame
BufferComponent.writeUdim = BufferComponent.WriteUdim
BufferComponent.writeudim = BufferComponent.WriteUdim
BufferComponent.writeUdim2 = BufferComponent.WriteUdim2
BufferComponent.writeudim2 = BufferComponent.WriteUdim2
BufferComponent.writeColor3 = BufferComponent.WriteColor3
BufferComponent.writecolor3 = BufferComponent.WriteColor3
BufferComponent.writeRect = BufferComponent.WriteRect
BufferComponent.writerect = BufferComponent.WriteRect
BufferComponent.writeRegion3 = BufferComponent.WriteRegion3
BufferComponent.writeregion3 = BufferComponent.WriteRegion3
BufferComponent.writeRegion3int16 = BufferComponent.WriteRegion3int16
BufferComponent.writeregion3int16 = BufferComponent.WriteRegion3int16

--[Reader] signed interger alias
BufferComponent.readI1 = BufferComponent.ReadI1
BufferComponent.readi1 = BufferComponent.ReadI1
BufferComponent.readI8 = BufferComponent.ReadI8
BufferComponent.readi8 = BufferComponent.ReadI8
BufferComponent.readI16 = BufferComponent.ReadI16
BufferComponent.readi16 = BufferComponent.ReadI16
BufferComponent.readI24 = BufferComponent.ReadI24
BufferComponent.readi24 = BufferComponent.ReadI24
BufferComponent.readI32 = BufferComponent.ReadI32
BufferComponent.readi32 = BufferComponent.ReadI32
BufferComponent.readI40 = BufferComponent.ReadI40
BufferComponent.readi40 = BufferComponent.ReadI40
BufferComponent.readI48 = BufferComponent.ReadI48
BufferComponent.readi48 = BufferComponent.ReadI48
BufferComponent.readI54 = BufferComponent.ReadI54
BufferComponent.readi54 = BufferComponent.ReadI54

--[Reader] unsigned interger alias
BufferComponent.readU1 = BufferComponent.ReadU1
BufferComponent.readu1 = BufferComponent.ReadU1
BufferComponent.readU8 = BufferComponent.ReadU8
BufferComponent.readu8 = BufferComponent.ReadU8
BufferComponent.readU16 = BufferComponent.ReadU16
BufferComponent.readu16 = BufferComponent.ReadU16
BufferComponent.readU24 = BufferComponent.ReadU24
BufferComponent.readu24 = BufferComponent.ReadU24
BufferComponent.readU32 = BufferComponent.ReadU32
BufferComponent.readu32 = BufferComponent.ReadU32
BufferComponent.readU40 = BufferComponent.ReadU40
BufferComponent.readu40 = BufferComponent.ReadU40
BufferComponent.readU48 = BufferComponent.ReadU48
BufferComponent.readu48 = BufferComponent.ReadU48
BufferComponent.readU54 = BufferComponent.ReadU54
BufferComponent.readu54 = BufferComponent.ReadU54

--[Reader] float interger alias
BufferComponent.readF16 = BufferComponent.ReadF16
BufferComponent.readf16 = BufferComponent.ReadF16
BufferComponent.readF32 = BufferComponent.ReadF32
BufferComponent.readf32 = BufferComponent.ReadF32
BufferComponent.readF64 = BufferComponent.ReadF64
BufferComponent.readf64 = BufferComponent.ReadF64

--[Reader] boolean alias
BufferComponent.readBool1 = BufferComponent.ReadBool1
BufferComponent.readbool1 = BufferComponent.ReadBool1
BufferComponent.readBool8 = BufferComponent.ReadBool8
BufferComponent.readbool8 = BufferComponent.ReadBool8


--[Reader] string alias
BufferComponent.readString = BufferComponent.ReadString
BufferComponent.readstring = BufferComponent.ReadString

--[Reader] instance alias
BufferComponent.readInstance = BufferComponent.ReadInstance
BufferComponent.readinstance = BufferComponent.ReadInstance

--[Reader] roblox type alias
BufferComponent.readVector2 = BufferComponent.ReadVector2
BufferComponent.readvector2 = BufferComponent.ReadVector2
BufferComponent.readVector2int16 = BufferComponent.ReadVector2int16
BufferComponent.readvector2int16 = BufferComponent.ReadVector2int16
BufferComponent.readVector3 = BufferComponent.ReadVector3
BufferComponent.readvector3 = BufferComponent.ReadVector3
BufferComponent.readVector3int16 = BufferComponent.ReadVector3int16
BufferComponent.readvector3int16 = BufferComponent.ReadVector3int16
BufferComponent.readCFrame = BufferComponent.ReadCFrame
BufferComponent.readcframe = BufferComponent.ReadCFrame
BufferComponent.readLossyCFrame = BufferComponent.ReadLossyCFrame
BufferComponent.readlossyCFrame = BufferComponent.ReadLossyCFrame
BufferComponent.readUdim = BufferComponent.ReadUDim
BufferComponent.readudim = BufferComponent.ReadUDim
BufferComponent.ReadUdim = BufferComponent.ReadUDim
BufferComponent.readUdim2 = BufferComponent.ReadUDim2
BufferComponent.readudim2 = BufferComponent.ReadUDim2
BufferComponent.ReadUdim2 = BufferComponent.ReadUDim2
BufferComponent.readColor3 = BufferComponent.ReadColor3
BufferComponent.readcolor3 = BufferComponent.ReadColor3
BufferComponent.readRect = BufferComponent.ReadRect
BufferComponent.readrect = BufferComponent.ReadRect
BufferComponent.readRegion3 = BufferComponent.ReadRegion3
BufferComponent.readregion3 = BufferComponent.ReadRegion3
BufferComponent.readRegion3int16 = BufferComponent.ReadRegion3int16
BufferComponent.readregion3int16 = BufferComponent.ReadRegion3int16

--[Cursor] alias
BufferComponent.getOffset = BufferComponent.GetOffset
BufferComponent.getoffset = BufferComponent.GetOffset
BufferComponent.getInstanceOffset = BufferComponent.GetInstanceOffset
BufferComponent.getinstanceoffset = BufferComponent.GetInstanceOffset

--[Buffer] alias
BufferComponent.getBuffer = BufferComponent.GetBuffer
BufferComponent.getbuffer = BufferComponent.GetBuffer
BufferComponent.getInstanceBuffer = BufferComponent.GetInstanceBuffer
BufferComponent.getinstancebuffer = BufferComponent.GetInstanceBuffer
BufferComponent.getBufferSize = BufferComponent.GetBufferSize
BufferComponent.getbuffersize = BufferComponent.GetBufferSize

--[Lifecycle] alias
BufferComponent.Clear = BufferComponent.clear
BufferComponent.Destroy = BufferComponent.Destroy

return BufferConstructor
