--[[
	ASCII Conversion Module
	Author: evxry_ll
	Description: Provides utilities for converting between ASCII strings, numbers, and binary buffer representations.
	Features:
	- Convert strings to ASCII numbers and vice versa
	- Convert numbers to compressed binary buffers
	- Decompress binary buffers back to numbers
	- Support for single values and arrays
]]

type ConvertType = "Merge" | "Single"

--[[
	Allocates additional space to a buffer by creating a new buffer with increased size
	and copying the existing data.
	@param b: The original buffer
	@param size: Number of additional bytes to allocate
	@return: New buffer with increased capacity
]]
local function allocate(b: buffer, size: number)
	if not size then return end
	if not b then return end
	local targetSize = buffer.len(b) + size
	local new_buffer = buffer.create(targetSize)
	buffer.copy(new_buffer, 0, b, 0, buffer.len(b))
	return new_buffer
end

--[[
	Decompresses a merged buffer or table of buffers into a single number.
	Used when multiple binary buffers represent a single large number.
	@param b: Buffer or table of buffers containing merged binary data
	@return: Reconstructed number from all binary segments
]]
local function decompressMergedBuffer(b: buffer | {buffer}): number
	local binaryString = ""
	local num = 0
	local sum = 0

	if type(b) == "buffer" then
		-- Single buffer case
		local bitCount = buffer.readu8(b, 0)
		-- Read only the significant bits (skip padding)
		for k = 8, 8 + bitCount - 1 do
			local extract_bit = math.modf(buffer.readbits(b, k, 1))
			binaryString = binaryString .. tostring(extract_bit)
		end

		-- Convert binary string to decimal
		binaryString = string.reverse(binaryString)
		for i = 1, #binaryString do
			num = string.sub(binaryString, i, i) == "1" and 1 or 0
			sum = sum + num * math.pow(2, i - 1)
		end
		return sum

	elseif type(b) == "table" then
		-- Multiple buffers case (merged representation)
		for i, binaryBuffer in pairs(b) do
			local bitCount = buffer.readu8(binaryBuffer, 0)
			-- Read significant bits from each buffer and concatenate
			for k = 8, 8 + bitCount - 1 do
				local extract_bit = math.modf(buffer.readbits(binaryBuffer, k, 1))
				binaryString = binaryString .. tostring(extract_bit)
			end
		end

		-- Convert combined binary string to decimal
		binaryString = string.reverse(binaryString)
		for i = 1, #binaryString do
			num = string.sub(binaryString, i, i) == "1" and 1 or 0
			sum = sum + num * math.pow(2, i - 1)
		end
		return sum
	end

	return sum
end

--[[
	Decompresses a buffer or array of buffers back to numbers.
	Supports both single numbers and arrays of numbers.
	@param b: Buffer or table of buffers to decompress
	@return: Single number or table of numbers
]]
local function decompressBuffer(b: buffer | {buffer}): number | {number}
	if type(b) == "buffer" then
		-- Single buffer decompression
		local binaryString = ""
		local num = 0
		local sum = 0
		local bitCount = buffer.readu8(b, 0)

		-- Read significant bits
		for k = 8, 8 + bitCount - 1 do
			local extract_bit = math.modf(buffer.readbits(b, k, 1))
			binaryString = binaryString .. tostring(extract_bit)
		end

		-- Convert to decimal
		binaryString = string.reverse(binaryString)
		for i = 1, #binaryString do
			num = string.sub(binaryString, i, i) == "1" and 1 or 0
			sum = sum + num * math.pow(2, i - 1)
		end
		return sum
	end

	-- Multiple buffers decompression
	local nums = {}
	for i, binaryBuffer in ipairs(b) do
		local binaryString = ""
		local num = 0
		local sum = 0
		local bitCount = buffer.readu8(binaryBuffer, 0)

		-- Read significant bits from each buffer
		for k = 8, 8 + bitCount - 1 do
			local extract_bit = math.modf(buffer.readbits(binaryBuffer, k, 1))
			binaryString = binaryString .. tostring(extract_bit)
		end

		-- Convert to decimal
		binaryString = string.reverse(binaryString)
		for i = 1, #binaryString do
			num = string.sub(binaryString, i, i) == "1" and 1 or 0
			sum = sum + num * math.pow(2, i - 1)
		end
		table.insert(nums, sum)
	end
	return nums
end

-- Module table
local ASCII = {}
ASCII.__index = ASCII

--[[
	Converts a string to an array of ASCII numbers.
	@param str: Input string to convert
	@return: Table of ASCII numbers representing each character
]]
function ASCII.ConvertASCIIString(str: string): {number}
	assert(type(str) == "string", "1st argument must be a string value")
	local _len = utf8.len(str)
	if _len <= 0 then return {} end

	local nums = {}
	for i = 1, _len do
		local ascii_num = string.byte(str, i)
		table.insert(nums, ascii_num)
	end
	return nums
end

--[[
	Converts numbers or arrays of numbers back to a string.
	@param num: Single number or table of ASCII numbers
	@return: String reconstructed from ASCII numbers
]]
function ASCII.ConvertNumsToString(num: number | {number}): string
	assert(type(num) == "number" or type(num) == "table", "1st argument must be a number or an array of numbers")
	local str = ""

	if type(num) == "number" then
		-- Single number to character
		str = str .. string.char(num)
	elseif type(num) == "table" then
		-- Array of numbers to string
		for i = 1, #num do
			if type(num[i]) ~= "number" then continue end
			local extractFloat = math.modf(num[i])
			str = str .. string.char(extractFloat)
		end
	end
	return str
end

--[[
	Converts numbers to compressed binary buffer representation.
	Stores the actual bit count to avoid padding issues.
	@param num: Single number or table of numbers to convert
	@return: Buffer or table of buffers containing binary representation
]]
function ASCII.ConvertNumberToBinary(num: number | {number}): buffer | {buffer}
	assert(type(num) == "number" or type(num) == "table", "1st argument must be a number or an array of numbers")
	local bits = {}

	if type(num) == "number" then
		-- Single number conversion
		local _bits = buffer.create(1)
		local _bits_offset = 0
		local rest = 0
		local extractFloat = math.modf(num)

		-- Convert number to binary digits
		while extractFloat > 0 do
			rest = math.fmod(extractFloat, 2)
			bits[#bits + 1] = rest
			extractFloat = (extractFloat - rest) / 2
			task.wait()  -- Yield to prevent timeout on large numbers
		end

		-- Reverse binary digits (division method produces reversed result)
		local concat = table.concat(bits, "")
		local reverse = string.reverse(concat)

		-- Store actual bit count in first byte
		buffer.writeu8(_bits, 0, #reverse)
		_bits_offset = 8  -- Start writing bits after the count byte

		table.clear(bits)

		-- Write significant bits to buffer
		for k = 1, #reverse do
			-- Allocate more space if needed
			if _bits_offset % 8 == 0 then 
				_bits = allocate(_bits, 1) 
			end
			buffer.writebits(_bits, _bits_offset, 1, tonumber(string.sub(reverse, k, k)))
			_bits_offset += 1
		end
		return _bits
	else
		-- Array of numbers conversion
		for i = 1, #num do
			if type(num[i]) ~= "number" then continue end

			local rest = 0
			local extractFloat = math.modf(num[i])
			table.insert(bits, {})

			-- Convert each number to binary digits
			while extractFloat > 0 do
				rest = math.fmod(extractFloat, 2)
				bits[i][#bits[i] + 1] = rest
				extractFloat = (extractFloat - rest) / 2
			end

			-- Reverse binary digits
			local concat = table.concat(bits[i], "")
			local reverse = string.reverse(concat)
			table.clear(bits[i])

			-- Create buffer for this number
			local stack = buffer.create(1)
			local stack_offset = 0
			buffer.writeu8(stack, 0, #reverse)  -- Store bit count
			stack_offset = 8

			-- Write bits to buffer
			for k = 1, #reverse do
				if stack_offset % 8 == 0 then 
					stack = allocate(stack, 1) 
				end
				buffer.writebits(stack, stack_offset, 1, tonumber(string.sub(reverse, k, k)))
				stack_offset += 1
			end

			bits[i] = stack
			task.wait()  -- Yield between conversions
		end
	end
	return bits
end

--[[
	Converts binary buffers back to numbers.
	@param b: Buffer or table of buffers to convert
	@param convertType: "Merge" for combined buffers, "Single" for individual (default)
	@return: Number or table of numbers
]]
function ASCII.ConvertBinaryToNumber(b: buffer | {buffer}, convertType: ConvertType?)
	assert(type(b) == "buffer" or type(b) == "table", "1st argument must be a buffer or an array of buffers")
	if convertType == "Merge" then
		return decompressMergedBuffer(b)
	end
	return decompressBuffer(b)
end

return ASCII
