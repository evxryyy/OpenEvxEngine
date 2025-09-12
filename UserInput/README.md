# UserInput

## What next

## Logs

### Version : 1.3

#### Changes

- Overhaul of all alias
  ```lua
  -- Constructor alias for convenience and consistency
  UserInput.New = UserInput.new

  -- Comprehensive method aliases for various naming conventions and case sensitivity
  Component.pressed = Component.Pressed
  Component.released = Component.Released
  Component.changeInputType = Component.ChangeInputType
  Component.changeInputtype = Component.ChangeInputType
  Component.addKey = Component.AddKey
  Component.addkey = Component.AddKey
  Component.removeKey = Component.RemoveKey
  Component.removekey = Component.RemoveKey
  Component.middleUp = Component.MiddleUp
  Component.middleup = Component.MiddleUp
  Component.middleDown = Component.MiddleDown
  Component.middledown = Component.MiddleDown
  Component.scrolled = Component.Scrolled
  Component.moved = Component.Moved
  Component.disconnectPressed = Component.DisconnectPressed
  Component.disconnectpressed = Component.DisconnectPressed
  Component.disconnectReleased = Component.DisconnectReleased
  Component.disconnectreleased = Component.DisconnectReleased
  Component.disconnectScrolledSignal = Component.DisconnectScrolledSignal
  Component.disconnectscrolledSignal = Component.DisconnectScrolledSignal
  Component.disconnectMovedSignal = Component.DisconnectMovedSignal
  Component.disconnectmovedSignal = Component.DisconnectMovedSignal
  Component.disconnectMiddleUpSignal = Component.DisconnectMiddleUpSignal
  Component.disconnectmiddleUpSignal = Component.DisconnectMiddleUpSignal
  Component.discconectmiddleupSignal = Component.DisconnectMiddleUpSignal
  Component.disconnectMiddleDownSignal = Component.DisconnectMiddleDownSignal
  Component.disconnectmiddleDownSignal = Component.DisconnectMiddleDownSignal
  Component.disconectmiddledownSignal = Component.DisconnectMiddleDownSignal
  Component.observe = Component.Observe
  Component.destroy = Component.Destroy
  
  -- Additional aliases for complete coverage
  Component.Changekey = Component.ChangeKey
  Component.ChangeKeys = Component.ChangeKey
  Component.changeKeys = Component.ChangeKey
  Component.Addkeys = Component.AddKey
  Component.addkeys = Component.AddKey
  Component.Removekeys = Component.RemoveKey
  Component.removekeys = Component.RemoveKey
  Component.Middleup = Component.MiddleUp
  Component.Middledown = Component.MiddleDown
  Component.Scroll = Component.Scrolled
  Component.DisconnectScroll = Component.DisconnectScrolledSignal
  Component.DisconnectMove = Component.DisconnectMovedSignal
  Component.DisconnectMiddleDown = Component.DisconnectMiddleDownSignal
  Component.ObserveInput = Component.Observe
  Component.cleanup = Component.Destroy
  ```

#### News
- Now the module can support the Mouse.
  ```lua
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
  
  MouseTest:DisconnectPressed()
  MouseTest:DisconnectReleased()
  MouseTest:DisconnectScrolledSignal()
  MouseTest:DisconnectMiddleUpSignal()
  MouseTest:DisconnectMiddleDown()
  MouseTest:DisconnectMovedSignal()
  ```

Version : 1.2.2
- UserInputComponent type is now changed to `typeof(setmetatable())`

Version : 1.2.1
- added alias for the constructor and the component

Version : 1.2
- fixed some issues with .KeyReleased
- updated comments
- updated api

Version : 1.1
- added .Observe(), track the current input type of the user.
- fixed type annotation bug

Version : 1.0
- Released the module
