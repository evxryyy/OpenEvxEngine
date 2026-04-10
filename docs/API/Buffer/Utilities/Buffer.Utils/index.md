## Getting Started

The `Utils` component in Buffer serves to, for example, calculate the number of bytes required
or directly convert a number of bytes to Kilobytes, Megabytes, or Gigabytes.

----

## Methods

----

### Getting the required bytes

To get the specific number of bytes, you will need a Schema and a table containing the values.

!!! note
    This function is used in `Buffer.Serialize`.
    I recommend reading that page if you are lost.

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local Utils = Buffer.Utils

--[[
	I really recommend to put : Buffer.BufferSchema for type checking, but it's optional.
	
	For any other type exepct String you will just need to put for example :
	
	{
		MyMessage = "String8" --> 8 is the max length of the string
	}
	
	but for non-defined length you will need to put something like this:
	
	{
		MyMessage = {
			Type = "String",
			Length = number
		}
	}
	
	Please note that when you put a string padding characters (string.char(31)) will be added to fill the remaining spaces
	but for example when you will call : Buffer.Deserialize(YourSchema,BufferComponent)
	
	all added characters will be automaticly removed
]]
local Schema : Buffer.BufferSchema = {
	MyMessage = {
		Type = "String",
		Length = 14,
	}
}

--Simple values (type checking is optional)
local Values : Buffer.BufferSchemaValue = {
	MyMessage = "Hello World"
}

print(Utils.GetRequiredBytes(Schema,Values)) --> this will return 14
```

----

### Converting bytes

To convert bytes to Kilobytes, etc., the `ConvertTo` function would be used.

```luau

local Buffer = require(somewhere.Buffer)

local Utils = Buffer.Utils

--This will convert the current bytes to Kilobytes

print(Utils.ConvertByte("Kilobytes",1024)) --> this will return 1

--First argument is the convertion and second argument is the bytes
-- Supported convertions: Kilobytes, Megabytes, Gigabytes
```

----

### GetEquivalentBytesInfoFromNumber

Used in `Buffer.WriteAny`, this give the exact byte required depending on the number.

```luau linenums="1"
local b = Utils.GetEquivalentBytesInfoFromNumber(65535) -- this will return 2 cause it will required 2 bytes to write 65535
```
	
@return : {bits : number, bytes : number, @isUnsigned : boolean }

!!! info
    isUnsigned purpose is only for `Buffer.WriteAny` to detect signed numbers,
    you can still use it if you have to do some use case with u/i numbers
