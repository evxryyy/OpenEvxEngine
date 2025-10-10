## Getting Started

Option Module - Complete Function Reference

----

## Methods

----

### Option.Some (Constructor)

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World")
```

Creates a Some variant of Option containing a value

- @param SomeOption The value to wrap in Some
- @return An Option containing the provided value

----

### Option.None (Constructor)

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.None()
```

Creates a None variant of Option containing no value

- @return An empty Option

----

### Option.IsOption (Constructor)

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hell World")

print(Option.IsOption(optA)) --> true
```

Checks if a value is a valid Option instance

- @param option The value to check
- @return true if the value is an Option, false otherwise

----

### Option.Wrap (Constructor)

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Wrap("Hell World")
```
    
Wraps a nullable value in an Option

If the value is nil, returns None; otherwise returns Some(value)

- @param value The nullable value to wrap	
- @return Option<T> or Option<nil>

----

### Option.Deserialize (Constructor)

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Deserialize({
	Tag = "Some",
	Value = 10
})
```

Deserializes data back into an Option
Used to reconstruct Options from stored/transmitted data

- @param data Serialized Option data with Tag and Value fields
- @return The reconstructed Option

----

### Option:IsSome()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World")

print(optA:IsSome()) --> true
```

Checks if this Option contains a value (is Some variant)

- @return true if Option contains a value, false if None

----

### Option:IsNone()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World")

print(optA:IsNone()) --> false
```

Checks if this Option is empty (is None variant)

- @return true if Option is None, false if it contains a value

----

### Option:Match()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World")

local result = optA:Match({
	Some = function(abc)
		return #abc
	end,
	None = function()
		--code
	end,
})
```

Pattern matching for Option - executes different code based on variant

- @param Options Table with Some and None callbacks
- @return Result of the executed callback

----

### Option:Assert()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.None()

optA:Assert("A value is required.")
```

Asserts that the Option contains a value, throwing error if None

- @param error_message Custom error message to display if assertion fails

----

### Option:GetOr()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.None():GetOr(10)

print(optA) --> 10 causing Option is none by default
```

Returns the contained value or a default if None

- @param value Default value to return if Option is None	
- @return The contained value or the default

----

### Option:Map()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World !"):Map(function(value)
	return #value
end)

print(optA.Some) -- 13
print(optA.Tag) -- "Some"
```

Returns the contained value or a default if None

- @param value Default value to return if Option is None	
- @return The contained value or the default

----

### Option:Filter()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World !"):Filter(function(value)
	if (#value >= 13) then
		return true
	end
	return false
end)

print(optA.Some) --> 13 causing the string is equal to 13 characters or more
print(optA.Tag) --> Some
```

Filters the Option based on a predicate function

Returns None if the predicate returns false or if already None

- @param callback Predicate function to test the value	
- @return Self if predicate passes, None otherwise

----

### Option:GetOrElse()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.None():GetOrElse(function()
	return "Hello World"
end)

print(optA) --> "Hello World" -- (as optA is None, the function passed to GetOrElse is called and its result is returned)
```

Returns the contained value or computes a default using a callback

- @param callback Function to compute default value if None
- @return The contained value or computed default

----

### Option:XOR()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.None()
local optB = Option.Some("Hello World")
local result = optA:XOR(optB)

print(result.Some) --> Hello World (Option.Some)
print(result.Tag) --> Some
```

Exclusive OR operation between two Options

Returns Some if exactly one Option is Some, None if both are Some or both are None

- @param OptionB The other Option to XOR with
- @return Result of XOR operation

----

### Option:AndThen()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World"):AndThen(function(value)
	return Option.Some(#value)
end)

print(optA.Some) --> 11
```

Chains Option operations - applies callback only if Some
The callback must return another Option

- @param callback Function that takes the value and returns an Option
- @return Result of the callback or None

----

### Option.Expect()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.None()

optA:Expect("optA must be Option.Some().")
```

Unwraps the value with a custom panic message if None

- @param msg Error message to display if Option is None
- @return The contained value
- @error Throws if Option is None

----

### Option.ExpectNone()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World")

optA:ExpectNone("optA must be Option.None().")
```

Asserts that the Option is None, throwing error if Some

- @param msg Error message to display if Option contains a value
- @error Throws if Option is Some

----

### Option:UnWrap()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World"):UnWrap()

print(optA) --> "Hello World"
```

Unwraps the contained value, panicking with default message if None

- @return The contained value
- @error Throws "Called UnWrap() on None" if Option is None

----

### Option:UnWrapOr()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.None():UnWrapOr("Hello World")

print(optA) -- "Hello World"
```

Unwraps the value or returns a default if None; Alias for GetOr

- @param value Default value to return if None
- @return The contained value or default

----

### Option:UnWrapOrElse()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.None():UnWrapOrElse(function()
	return "Hello World"
end)

print(optA) -- "Hello World"
```

Unwraps the value or computes a default if None; Alias for GetOrElse

- @param callback Function to compute default if None
- @return The contained value or computed default

----

### Option:Contains()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World")
local containsNumber = optA:Contains(10)

print(containsNumber) --> false
```

Checks if the Option contains a specific value

- @param value The value to check for
- @return true if Option contains the exact value, false otherwise

----

### Option:Serialize()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World"):Serialize()

print(optA.Value) --> "Hello World"
print(optA.Tag) --> "Some"
```

Serializes the Option for storage or transmission

- @return Table with Tag and optional Value fields

----

## Metamethods

----

### __tostring()

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World")

print(optA) --> Option(Hello World)
```

String representation of the Option
- @return "Option(value)" for Some, "Option(None)" for None

----

### __eq

```luau linenums="1"
local Option = require(somewhere.Option)

local optA = Option.Some("Hello World")
local optB = Option.Some("Hello World")

print(optA == optB) --> true
```

Equality comparison between two Options

Two Options are equal if:

- Both are None, or
- Both are Some and contain equal values

---

- @param b The other Option to compare with
- @return true if Options are equal, false otherwise

## Alias

```luau linenums="1"
-- Lowercase aliases for methods (alternative naming convention)
-- These provide the same functionality with camelCase naming
OptionComponent.Unwrap = OptionComponent.UnWrap
OptionComponent.UnwrapOr = OptionComponent.UnWrapOr
OptionComponent.getOr = OptionComponent.GetOr
OptionComponent.getOrElse = OptionComponent.GetOrElse
OptionComponent.expectNone = OptionComponent.ExpectNone
OptionComponent.andThen = OptionComponent.AndThen
OptionComponent.map = OptionComponent.Map
OptionComponent.filter = OptionComponent.Filter
OptionComponent.assert = OptionComponent.Assert
OptionComponent.match = OptionComponent.Match
OptionComponent.contains = OptionComponent.Contains
OptionComponent.isNone = OptionComponent.IsNone
OptionComponent.isSome = OptionComponent.IsSome
OptionComponent.serialize = OptionComponent.Serialize

-- OptionConstructor lowercase aliases
OptionConstructor.isOption = OptionConstructor.IsOption
OptionConstructor.deserialize = OptionConstructor.Deserialize
```