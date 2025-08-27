return {
	["buffer access out of bounds"] = "Happens when trying to read or write to a buffer position outside its allocated size",
	--[[
		Incorrect index calculations Off-by-one errors Not checking buffer size before access
		
		code example:
		local buf = buffer.create(10)
		buffer.writeu8(buf, 11, 42)
	]]
	
	["not a valid type"] = "%s is not a %s (Type mismatch: expected one type but got another)",
	--[[
		example:
		"string" is not a "number"
	]]
	
	["not enough space"] = "%d byte(s) is required to write a %s \n e.g (Buffer doesn't have enough space to write the requested data type)";
	--[[
		example:
		"1 byte(s) is required to write a Int8"
	]]
}
