--[[
	Bitstream Debugger + Version Control Module

	Author : evxry_ll

	This module provides:
	- Centralized error message handling
	- Runtime version verification against a remote source
	- Lightweight configuration system
	- Safe error retrieval API

	The goal is to ensure:
	- Consistent error formatting across Bitstream
	- Optional GitHub-based version validation
	- Reduced duplication of error strings
]]

const HttpService = game:WaitForChild("HttpService")

const rawUrl = "https://raw.githubusercontent.com/evxryyy/Rbxenv/refs/heads/main/Bitstream/VERSION.md"

type ErrorEnumeration = 
	"Type-missmatch"
	| "Doesn't have enough space"
	| "Out of bounds"

--[[
	Error message registry.
]]
const ErrorMessages = {
	["Type-missmatch"] = 
		"Bitstream.%s: Type missmatch this argument require a %s type.",

	["Doesn't have enough space"] = 
		"Bitstream.%s: Doesn't have enough space to write this type.",
	["Out of bounds"] = 
		"Bitstream.%s: Buffer read out of bounds (offset=%d, type_size=%d, buffer_size=%d)",

}

--[[
	Configuration system.
	Allows for the modification of the module's behavior.
]]
const Configuration = {
	VerifyVersion = true,
} :: {[ErrorEnumeration]: string}

--[[
	Version verification system.
	Checks the version of the Bitstream module against a remote source.
	Only runs if Configuration.VerifyVersion is true.
]]
const function verifiyVersion() : ()
	if Configuration.VerifyVersion == false then return end
	if (rawUrl == "") then return end
	if HttpService.HttpEnabled == false then
		warn("HttpService is not enabled, Bitstream version could not be evaluate.")
		return
	end
	const success, res = pcall(function()
		return HttpService:GetAsync(rawUrl)
	end)
	if not success then
		warn(res)
		return
	end
	const bitstreamSourceVersion = string.match(res, "[%d%.]+")
	const bitstreamActualVersion = script.Parent:GetAttribute("VERSION")
	if bitstreamSourceVersion ~= bitstreamActualVersion then
		warn(
			`Bitstream version missmatch, expected {bitstreamSourceVersion} got {bitstreamActualVersion}. Please go to github and install the lastest version.`
		)
	end
end

--[[
	Error retrieval function.
	@param errorType The type of error to retrieve.
	@return The error message string.
]]
const function catchError(errorType : ErrorEnumeration) : string
	const targetError = ErrorMessages[errorType]

	if not targetError then
		warn("Error not found")
	end

	return targetError
end

--[[
	Returns the name of the function that called this function.
	Used for error message formatting.
	
	@params level (number) : The level of the stack trace to get the function name from.
		2 by default
	
	@return : The name of the function that called this function.
]]
const function getFunctionName(level : number?)
	return debug.info(level or 2,"n")
end

--[[
	Handles assert statements for Bitstream methods.
	Formats error messages with the name of the function that called it.
	Throws an error if condition is false.
]]
const function handleAssert(condition : boolean,errorType : ErrorEnumeration,formatedErrorType : {string}) : ()
	if condition then return end
	error(ErrorMessages[errorType]:format(unpack(formatedErrorType)))
end

return table.freeze({

	catchError = catchError,
	verifyVersion = verifiyVersion,
	getFunctionName = getFunctionName,
	handleAssert = handleAssert,

})
