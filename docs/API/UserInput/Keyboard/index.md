## Getting Started

For keyboard keys, you need to set `InputType` to `Keyboard`, then you can use all keyboard keys.

----

## Keyboard Object

```luau linenums="1"
local UserInput = require(somewhere.UserInput)

--[[
	Using a empty configuration will resume to :
	{
		InputType = "Keyboard",
		Keys = {},
	}
]]
local myKeyboardConfiguration = UserInput.new()

--listening to key pressed
myKeyboardConfiguration:Pressed(function(key)
	print(key)
end)

myKeyboardConfiguration:AddKey(Enum.KeyCode.E) -- or you can do {Enum.KeyCode.E,...} or "E"
```

This creates a Keyboard Object. You can change the type with `ChangeInputType`.

----