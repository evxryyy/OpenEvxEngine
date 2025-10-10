## Getting Started

For enum creation, everything will happen here.

----

## Methods

### Creating new enums

```luau linenums="1"
-- Import the main Enum module that provides enum creation functionality
local EnumModule = require(somewhere.Enum.Enum)

-- Import the EnumType module that contains type definitions for enums
local EnumType = require(somewhere.Enum.EnumType)

--[[
	Creates a new enum called "Hello-World" with three values: A, B, and C
	
	The type casting :: {EnumType.HelloKeys} ensures type safety by specifying
	that the items array should match the HelloKeys type definition.
	
	The final type cast :: EnumType.HelloEnum<"Hello"> ensures the returned
	enum matches the expected HelloEnum type structure.
	
	This creates an enum where:
	- HelloEnum.A = {Value = 1, Name = "A", EnumType = "Hello-World"}
	- HelloEnum.B = {Value = 2, Name = "B", EnumType = "Hello-World"}
	- HelloEnum.C = {Value = 3, Name = "C", EnumType = "Hello-World"}
]]

local HelloEnum = EnumModule.new("Hello-World",{"A","B","C"} :: {EnumType.HelloKeys}) :: EnumType.HelloEnum<"Hello"> 
-- You can name "Hello" What ever you want it will not be The EnumType 
```

Creates a new enum with the given name and items.
	
If an enum with the same name already exists, returns the existing enum.
Otherwise, creates a new enum with auto-assigned numeric values.
	
- @param EnumName The unique name for this enum
- @param items Array of string keys for the enum values
- @return A frozen table mapping keys to EnumIndex objects

#### Creating Enum-Type definition

I recommend to put your Enum type definition inside EnumType this is where your gonna find the Enum type definition example.

```luau linenums="1"
-- Example enum type definitions
-- These demonstrate how to create type-safe enum definitions

-- HelloKeys defines the allowed string values for the Hello enum
-- Using a union type ensures only these specific strings can be used
export type HelloKeys = "A" | "B" | "C"

-- HelloEnum defines the structure of the Hello enum
-- It maps each key to an EnumIndex with the appropriate enum name
-- The generic parameter EnumName allows flexibility in the enum type name
export type HelloEnum<EnumName = string> = {
	A: EnumIndex<EnumName>,  -- Enum item A
	B: EnumIndex<EnumName>,  -- Enum item B
	C: EnumIndex<EnumName>,  -- Enum item C
}
```

----

### Enum.from()

```luau linenums="1"
-- Import the main Enum module that provides enum creation functionality
local EnumModule = require(somewhere.Enum.Enum)

-- Import the EnumType module that contains type definitions for enums
local EnumType = require(somewhere.Enum.EnumType)

local HelloEnum = EnumModule.new("Hello-World",{"A","B","C"} :: {EnumType.HelloKeys}) :: EnumType.HelloEnum<"Hello">

--later in your code

local HelloEnum = EnumModule.from("Hello-World") :: EnumType.HelloEnum<"Hello">
```

Retrieves an existing enum by name from the registry.
	
- @param EnumName The name of the enum to retrieve
- @return A frozen copy of the enum table
- @error Throws if the enum doesn't exist

----

### Enum.RemoveEnum()

```luau linenums="1"
-- Import the main Enum module that provides enum creation functionality
local EnumModule = require(somewhere.Enum.Enum)

-- Import the EnumType module that contains type definitions for enums
local EnumType = require(somewhere.Enum.EnumType)

local HelloEnum = EnumModule.new("Hello-World",{"A","B","C"} :: {EnumType.HelloKeys}) :: EnumType.HelloEnum<"Hello">

--later in your code

EnumModule.RemoveEnum("Hello-World")
```

Removes an enum from the registry.
	
This clears the enum table and removes it from the registry,
allowing a new enum with the same name to be created.
	
- @param EnumName The name of the enum to remove

----

## Alias

```luau linenums="1"
-- Alias for backward compatibility or alternative naming preference
-- GetEnumItems provides the same functionality as 'from'
EnumConstructor.GetEnumItems = EnumConstructor.from
```