--!strict

--[[
	Author : evxry_ll
	
	@Name: Types
	
	@Description:
	This module is part of `Bitstream` module. It contains some types used internally.
]]

--[[
	`ConstructorConfiguration` is used to configure the constructor of `Bitstream` module.
	You can use it to set the initial size of the buffer, the maximum allowed size and if you want to use auto allocation.
	Auto allocation is a feature that automatically allocates more memory when the current buffer is full.
	
	@Properties:
		- UseAutoAllocation : boolean
		- Size : number? (in bytes) @optional
		- MaximumAllowedSize : number? -- (in bytes) @optional
		- SourceBuffer : buffer? not optional you use `.fromBuffer`
]]
export type ConstructorConfiguration = {
	UseAutoAllocation : boolean,
	Size : number?,
	MaximumAllowedSize : number?,
	SourceBuffer : buffer?	
}

--[[
	`BytesData` is returned by `Utitilies.GetEquivalentBytesInfoFromNumber` function.
	You can use it to get the number of bytes and bits required to represent `n`.
	
	@Properties:
	- bits : number
	- bytes : number
	- isUnsigned : boolean
]]
export type BytesData = {
	bits : number,
	bytes : number,
	isUnsigned : boolean,
}

--[[
	`Quaternion` is a 4D numbers that represent a quaternion, 
	Used in `Extensions.quaternionToCFrame` and `Extensions.axisAngleToQuaternion`.
	
	@Properties:
	- x : number
	- y : number
	- z : number
	- w : number
]]
export type Quaternion = {
	x : number,
	y : number,
	z : number,
	w : number,
}

--[[
	`RotationCurveKeyOption` is used in `Constants.RotationCurveKey`
	Since multiples CFrame types exist, this option is here to choose which one you want.
	
	@union
]]
export type RotationCurveKeyOption = "Quaternion" | "Normal" | "Quantized" | "CFrameF32" | "CFrameF24"

--[[
	`FloatCurveKeyOption` is used in `Constants.FloatCurveKey`
	Multiples float types exist, this option is here to choose which one you want to use.
	
	@union
]]
export type FloatCurveKeyOption = "Normal" | "F32" | "F16" | "F24"

--[[
	`ColorSequenceOption` is used in `Constants.ColorSequence`
	Determine the way to write the [R,G,B] of the color inside the keypoint
	
	@union
]]
export type ColorSequenceOption = "Normal" | "F32" | "F64" | "F24"

--[[
	`NumberSequenceOption` is used in `Constants.NumberSequence`
	Determine the way to write the number inside the keypoint
	
	@union
]]
export type NumberSequenceOption = "Normal" | "F16" | "F64" | "F24"


return nil
