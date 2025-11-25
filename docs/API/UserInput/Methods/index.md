## Getting Started

This page shows all the functions of UserInput as well as functions specifically for the mouse.

----

## Methods

----

### UserInput.new (Constructor)

`new(config: UserInputConfiguration): UserInputComponent`

Creates a new UserInput component instance.

Parameters config: Configuration object with the following properties:

`Keys: {Enum.KeyCode | Enum.UserInputType | string} - Array of keys to register`

`InputType: "Gamepad" | "Keyboard" | "Mouse" - Initial input type`

----

### UserInput:Pressed 

`Pressed(callback : (Enum.KeyCode | Enum.UserInputType)) -> SignalConnection`

Public method to connect a callback to the key pressed event

- @param callback: Function that will be called when a registered key is pressed
- @return: SignalConnection that can be used to disconnect the callback

----

### UserInput:Released 

`Released(callback : (Enum.KeyCode | Enum.UserInputType)) -> SignalConnection`

Public method to connect a callback to the key released event

- @param callback: Function that will be called when a registered key is released
- @return: SignalConnection that can be used to disconnect the callback

----

### UserInput:Observe 

`Observe(callback : ("Gamepad" | "MouseKeyboard" | "Touch")) -> () -> ()`

Observe changes in the user's preferred input method

- @param callback: Function called when input type changes (Gamepad, MouseKeyboard, or Touch)
- @return: Cleanup function to stop observing

----

### UserInput:GetInputType

`GetInputType() ->  "Gamepad" | "MouseKeyboard" | "Touch"`

Returns the current input type

- @return: "Gamepad" | "MouseKeyboard" | "Touch" - Current input type

----

### UserInput:ChangeInputType

`ChangeInputType("Gamepad" | "Keyboard" | "Mouse",Keys : {Enum.KeyCode | Enum.UserInputType | string}`

Dynamically change the input type between Gamepad and Keyboard or Mouse
This will clear all registered keys and recreate the input handlers

!!! Note
    - Pressed and Release connection don't need to be reconnected.
    
    - You dont need to pass an array of keys.

----

### UserInput:ChangeKey

`ChangeKey({Enum.KeyCode | Enum.UserInputType | string})`

Replace all currently registered keys with a new set

- @param Keys: Keys to register

----

### UserInput:AddKey

`AddKey({Enum.KeyCode | Enum.UserInputType | string})`

Add new keys to the existing registered set Duplicate keys are automatically ignored

- @param Keys: Keys to add

----

### UserInput:RemoveKey

`RemoveKey({Enum.KeyCode | Enum.UserInputType | string})`

Remove specific keys from the registered set

- @param Keys: Keys to remove

----

### UserInput:Disconnect

!!! Note
    Multiple Disconnect function exist you will find everything about disconnection here

----

#### DisconnectPressed

`DisconnectPressed`

Disconnect all callbacks connected to the KeyPressed signal 

----

#### DisconnectReleased

`DisconnectReleased`

Disconnect all callbacks connected to the KeyReleased signal 

----

#### DisconnectMiddleUp

`@MouseOnly - DisconnectMiddleUpSignal`

Disconnect the middle mouse button up signal

----

#### DisconnectMiddleDown

`@MouseOnly - DisconnectMiddleDownSignal`

Disconnect the middle mouse button down signal

----

#### DisconnectScrolled

`@MouseOnly - DisconnectScrolledSignal` 

Disconnect the scroll signal from the mouse

----

#### DisconnectMoved

`@MouseOnly - DisconnectMovedSignal`

Disconnect the signal when the mouse move

----

#### DisconnectAll

`DisconnectAll`

Disconnect all signals

----

### UserInput:Destroy()

`Destroy`

Complete cleanup of the UserInput component 
This should be called when the component is no longer needed

----

## Alias

```luau linenums="1"
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
Component.disconnectAll = Component.DisconnectAll
Component.disconnectall = Component.DisconnectAll
Component.observe = Component.Observe
Component.getInputType = Component.GetInputType
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
