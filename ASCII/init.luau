--[[
	ASCII Module - Binary and ASCII Conversion Utilities
	
	A utility module for converting between strings, ASCII values, and binary representations.
	Provides functions to encode/decode text and numbers using ASCII and binary formats.
	
	=== USAGE EXAMPLE ===
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ASCII = require(ReplicatedStorage:WaitForChild("ASCII"))
	
	-- String to ASCII conversion
	print(ASCII.StrASCII("Hello World!")) -- Output: {72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33}
	
	-- ASCII to String conversion
	print(ASCII.ASCIIStr({72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33})) -- Output: "Hello World!"
	
	-- Number to Binary conversion
	local binary = ASCII.BinaryNumber(10) -- Returns buffer containing binary representation
	
	-- Binary to Number conversion
	local number = ASCII.BinaryToNumber(binary) -- Output: 10
	
	=== API REFERENCE ===
	
	ASCII.StrASCII(str: string) -> {number}
		Converts a string into an array of ASCII values.
		
		Parameters:
			str - The input string to convert
			
		Returns:
			Array of numbers representing ASCII values of each character
			
		Example:
			ASCII.StrASCII("Hi") -> {72, 105}
	
	
	ASCII.ASCIIStr(num: number | {number}) -> string
		Converts ASCII value(s) back into a string.
		
		Parameters:
			num - Single ASCII value or array of ASCII values
			
		Returns:
			String representation of the ASCII values
			
		Examples:
			ASCII.ASCIIStr(72) -> "H"
			ASCII.ASCIIStr({72, 105}) -> "Hi"
	
	
	ASCII.BinaryNumber(num: number | {number}) -> buffer | {buffer}
		Converts number(s) into binary representation using buffers.
		
		Parameters:
			num - Single number or array of numbers to convert
			
		Returns:
			- If single number: buffer containing binary representation
			- If array: array of buffers, each containing binary representation
			
		Examples:
			ASCII.BinaryNumber(10) -> buffer (containing 1010)
			ASCII.BinaryNumber({10, 15}) -> {buffer, buffer}
	
	
	ASCII.BinaryToNumber(bits: buffer | {buffer}) -> number
		Converts binary representation back to decimal number.
		
		Parameters:
			bits - Buffer or array of buffers containing binary data
			
		Returns:
			Decimal number representation of the binary data
			
		Notes:
			- Single buffer: converts directly to number
			- Array of buffers: concatenates all binary data then converts
			
		Examples:
			ASCII.BinaryToNumber(buffer) -> 10
			ASCII.BinaryToNumber({buffer1, buffer2}) -> Combined decimal value
	
	=== IMPLEMENTATION NOTES ===
	
	- Uses UTF-8 encoding for string operations
	- Binary data is stored in Roblox buffer objects for efficiency
	- Supports both single value and batch operations
	- Automatically handles float to integer conversion
	- Task.wait() is used in loops to prevent script timeout on large datasets
--]]

-- Helper function to expand buffer size
-- @param b: Existing buffer to expand
-- @param size: Number of bytes to add
-- @return: New buffer with expanded size and copied data
local function allocate(b : buffer,size : number)
	if(not size) then return end
	if(not b) then return end
	local targetSize = buffer.len(b)+size
	local new_buffer = buffer.create(targetSize)
	buffer.copy(new_buffer,0,b,0,buffer.len(b))
	return new_buffer
end

-- Converts a string to an array of ASCII numbers
-- @param str: Input string to convert
-- @return: Array of ASCII values for each character
local function StrToASCIINums(str : string) : {number}
	assert(type(str) == "string","1st argument must be a string value")
	local _len = utf8.len(str)
	if(_len <= 0) then return {} end
	local nums = {}
	for i = 1,_len do
		local ascii_num = string.byte(str,i)
		table.insert(nums,ascii_num)
	end
	return nums
end

-- Converts ASCII number(s) to string representation
-- @param num: Single ASCII value or array of ASCII values
-- @return: String formed from the ASCII values
local function ASCIIToStr(num : number | {number}) : string
	assert(type(num) == "number" or type(num) == "table","1st argument must be a number or a an array of numbers")
	local str = ""
	if(type(num) == "number") then
		str = str .. string.char(num)
	elseif(type(num) == "table") then
		for i = 1,#num do
			if(type(num[i]) ~= "number") then continue end
			local extractFloat = math.modf(num[i])  -- Extract integer part
			str = str .. string.char(extractFloat)
		end
	end
	return str
end

-- Converts decimal number(s) to binary representation
-- @param num: Single number or array of numbers
-- @return: Buffer or array of buffers containing binary data
local function binaryNumber(num : number | {number}) : buffer | {buffer}
	assert(type(num) == "number" or type(num) == "table","1st argument must be a number or a an array of numbers")
	local bits = {}
	if(type(num) == "number") then
		-- Single number conversion
		local _bits = buffer.create(0)
		local _bits_offset = 0
		local rest = 0
		local extractFloat = math.modf(num)  -- Extract integer part
		-- Convert to binary using division method
		while extractFloat > 0 do
			rest = math.fmod(extractFloat,2)
			bits[#bits+1] = rest
			extractFloat = (extractFloat-rest) / 2
			task.wait()  -- Prevent timeout on large numbers
		end
		-- Reverse the bits (division method produces reversed binary)
		local concat = table.concat(bits,"")
		local reverse = string.reverse(concat)
		table.clear(bits)
		-- Write bits to buffer
		for k = 1,#reverse do
			_bits = allocate(_bits,1)
			buffer.writebits(_bits,_bits_offset,1,tonumber(string.sub(reverse,k,k)))
			_bits_offset += 1
		end
		return _bits
	else
		-- Array of numbers conversion
		for i = 1,#num do
			if(type(num[i]) ~= "number") then continue end
			local rest = 0
			local extractFloat = math.modf(num[i])
			table.insert(bits,{})
			-- Convert each number to binary
			while extractFloat > 0 do
				rest = math.fmod(extractFloat,2)
				bits[i][#bits[i]+1] = rest
				extractFloat = (extractFloat-rest) / 2
			end
			-- Process and store in buffer
			local concat = table.concat(bits[i],"")
			local reverse = string.reverse(concat)
			table.clear(bits[i])
			local stack = buffer.create(0)
			local stack_offset = 0
			for k = 1,#reverse do
				stack = allocate(stack,1)
				buffer.writebits(stack,stack_offset,1,tonumber(string.sub(reverse,k,k)))
				stack_offset += 1
			end
			bits[i] = stack
			task.wait()  -- Prevent timeout on large arrays
		end
	end
	return bits
end

-- Converts binary buffer(s) back to decimal number
-- @param bits: Buffer or array of buffers containing binary data
-- @return: Decimal representation of the binary data
local function binaryToNumber(bits : buffer | {buffer}) : number
	assert(type(bits) == "table" or type(bits) == "buffer","1st argument must be a table")
	local binaryString = ""
	-- Extract binary string from buffer(s)
	if(type(bits) == "table") then
		-- Multiple buffers - concatenate all binary data
		for i,binaryBuffer in ipairs(bits) do
			for k = 0,buffer.len(binaryBuffer)-1 do
				local extract_bit = math.modf(buffer.readbits(binaryBuffer,k,1))
				binaryString = binaryString .. tostring(extract_bit)
			end
		end
	elseif(type(bits) == "buffer") then
		-- Single buffer
		for k = 0,buffer.len(bits)-1 do
			local extract_bit = math.modf(buffer.readbits(bits,k,1))
			binaryString = binaryString .. tostring(extract_bit)
		end
	end
	-- Convert binary string to decimal
	local num = 0
	local sum = 0
	binaryString = string.reverse(binaryString)
	for i = 1,#binaryString do
		num = string.sub(binaryString,i,i) == "1" and 1 or 0
		sum = sum + num * math.pow(2,i-1)
	end
	return sum
end

-- Module definition
local Constructor = {}
Constructor.__index = Constructor

-- Public API
Constructor.StrASCII = StrToASCIINums;      -- String to ASCII array
Constructor.ASCIIStr = ASCIIToStr;          -- ASCII to String
Constructor.BinaryNumber = binaryNumber;     -- Number to Binary
Constructor.BinaryToNumber = binaryToNumber; -- Binary to Number

return Constructor
