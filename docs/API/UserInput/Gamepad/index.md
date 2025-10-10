## Getting Started

For gamepad buttons, you need to set `InputType` to `Gamepad`, then you can use all gamepad buttons.

## Gamepad Object

```luau linenums="1"
local UserInput = require(somewhere.UserInput)

local myKeyboardConfiguration = UserInput.new({
	InputType = "Gamepad",
	Keys = {}
})

--listening to key pressed
myKeyboardConfiguration:Pressed(function(key)
	print(key)
end)

myKeyboardConfiguration:AddKey(Enum.KeyCode.ButtonA) -- or you can do {Enum.KeyCode.ButtonA,...} or "ButtonA"
```

This creates a Gamepad Object. You can change the type with `ChangeInputType`.
