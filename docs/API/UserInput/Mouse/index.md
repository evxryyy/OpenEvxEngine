## Getting Started

For mouse keys, you need to set `InputType` to `Mouse`, then you can use all mouse buttons.


## Mouse Object

```luau linenums="1"

local MouseTest = UserInput.new({InputType = "Mouse", Keys = {
	Enum.UserInputType.MouseButton3, -- Middle Mouse Button
	Enum.UserInputType.MouseButton1 -- Left Mouse Button
}})

MouseTest:Pressed(function(key)
	print(key)
end)

MouseTest:Released(function(key)
	print(key)
end)

--@MouseOnly
MouseTest:Scrolled(function(scrollAmount)
	print(scrollAmount)
end)

--@MouseOnly
MouseTest:MiddleUp(function(key)
	print(key)
end)

--@MouseOnly
MouseTest:MiddleDown(function(key)
	print(key)
end)

--@MouseOnly
MouseTest:Moved(function(pos)
	print(pos)
end)

--@MouseOnly
MouseTest:DisconnectScrolledSignal()
MouseTest:DisconnectMiddleUpSignal()
MouseTest:DisconnectMiddleDown()
MouseTest:DisconnectMovedSignal()
```

This creates a Mouse Object. You can change the type with `ChangeInputType`.