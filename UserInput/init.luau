--[[
	Author: evxry_ll
	
	UserInput Component Module
	
	A comprehensive input handling system that provides unified interface for keyboard,
	gamepad, and mouse input with dynamic switching capabilities.
	
	Features:
	- Multi-input support (Keyboard, Gamepad, Mouse)
	- Dynamic input type switching at runtime
	- Configurable key/button registration system
	- Signal-based event system for input detection
	- Input type observation for automatic switching detection
	- Memory-safe cleanup and destruction
]]

-- Type annotation for configuration object passed to UserInput.new()
export type UserInputConfiguration = {
	-- Array of KeyCodes or UserInputTypes that the component should respond to
	Keys: {Enum.KeyCode | Enum.UserInputType},
	-- Initial input type ("Gamepad", "Keyboard", or "Mouse")
	InputType: "Gamepad" | "Keyboard" | "Mouse",
}

-- Roblox service for handling user input events
local UserInputService = game:GetService("UserInputService")

-- Import required modules using path aliases
local Signal = require("@self/_Signal")
local Input = require("@self/_Input")

-- Extract specific input handlers from the Input module
local Keyboard = Input.Keyboard
local Gamepad = Input.Gamepad
local Mouse = Input.Mouse
local PreferredInput = Input.PreferredInput

-- Import type annotations for type safety and documentation
type SignalConnectionStruct = Signal.SignalConnection
type SignalStruct = Signal.Signal<...any>
type GamepadStruct = Input.GamepadType
type KeyboardStruct = Input.KeyboardType
type MouseStruct = Input.MouseType

--[[
	Validates the configuration object structure
	@param config: UserInputConfiguration object to validate
	@return: boolean - true if valid, false if invalid
]]
local function configGuard(config: UserInputConfiguration): boolean
	if not config then return false end
	if not config.Keys or not config.InputType then return false end
	return true
end

--[[
	Factory function that creates the appropriate input handler based on InputType
	@param config: Configuration object containing InputType
	@return: GamepadStruct | KeyboardStruct | MouseStruct - Appropriate input handler instance
]]
local function inputGuard(config: UserInputConfiguration)
	if config.InputType == "Gamepad" then return Gamepad.new() end
	if config.InputType == "Keyboard" then return Keyboard.new() end
	if config.InputType == "Mouse" then return Mouse.new() end
end

-- Main module table
local UserInput = {}
UserInput.__index = UserInput

-- Component metatable for instance methods
local Component = {}
Component.__index = Component

-- Type definition for the UserInput component instance
export type UserInputComponent = typeof(setmetatable({} :: {
	-- The underlying input handler (Gamepad, Keyboard, or Mouse structure)
	inputStruct: GamepadStruct | KeyboardStruct | MouseStruct,
	-- Array of registered KeyCodes or UserInputTypes that trigger events
	KeysRegistered: {Enum.KeyCode | Enum.UserInputType},
	-- Signal fired when any registered key/button is pressed
	KeyPressed: SignalStruct,
	-- Signal fired when any registered key/button is released
	KeyReleased: SignalStruct,
	-- Mouse-specific signals (only available when InputType is "Mouse")
	MiddlePressed: SignalStruct?,    -- Fired when middle mouse button is pressed
	MiddleReleased: SignalStruct?,   -- Fired when middle mouse button is released
	ScrolledSignal: SignalStruct?,   -- Fired when mouse wheel is scrolled
	MovedSignal: SignalStruct?,      -- Fired when mouse position changes
	-- Function reference for input type observer cleanup
	InputObserver: (() -> ())?,
}, Component))

--[[
	Constructor function - creates a new UserInput component instance
	@param config: UserInputConfiguration object specifying Keys and InputType
	@return: UserInputComponent - New component instance
	@throws: Assertion error if configuration is invalid
]]
function UserInput.new(config: UserInputConfiguration): UserInputComponent
	assert(configGuard(config), "Invalid configuration: Missing required fields (Keys, InputType)")
	-- Create component instance with initial properties
	local self = setmetatable({
		inputStruct = inputGuard(config),
		KeysRegistered = table.clone(config.Keys),
		KeyPressed = Signal.new(),
		KeyReleased = Signal.new(),
		InputObserver = false,
	}, Component)
	-- Initialize mouse-specific signals if InputType is Mouse
	if config.InputType == "Mouse" then
		self.MiddlePressed = Signal.new()
		self.MiddleReleased = Signal.new()
		self.ScrolledSignal = Signal.new()
		self.MovedSignal = Signal.new()
	end
	-- Set up event listeners for input detection
	self:__setUpInputStructKeyPressed()
	self:__setUpInputStructKeyReleased()
	return self
end

--[[
	Internal method - Sets up key/button press detection based on input type
	Connects to appropriate events (KeyDown, ButtonDown, MouseButton events)
	@return: RBXScriptConnection | multiple connections for mouse input
]]
function Component.__setUpInputStructKeyPressed(self: UserInputComponent)
	-- Keyboard input handling
	if self.inputStruct.KeyDown then
		return self.inputStruct.KeyDown:Connect(function(key: Enum.KeyCode, wasProcessed: boolean)
			if wasProcessed then return end  -- Ignore GUI-processed input
			if not table.find(self.KeysRegistered, key) then return end
			self.KeyPressed:Fire(key)
		end)
		-- Gamepad input handling
	elseif self.inputStruct.ButtonDown then
		return self.inputStruct.ButtonDown:Connect(function(keycode: Enum.KeyCode, processed: boolean)
			if processed then return end  -- Ignore processed input
			if not table.find(self.KeysRegistered, keycode) then return end
			self.KeyPressed:Fire(keycode)
		end)
		-- Mouse input handling
	elseif self.inputStruct.LeftDown or self.inputStruct.RightDown then
		-- Left mouse button press
		local lDown = self.inputStruct.LeftDown:Connect(function()
			if not table.find(self.KeysRegistered, Enum.UserInputType.MouseButton1) then return end
			self.KeyPressed:Fire(Enum.UserInputType.MouseButton1)
		end)
		-- Right mouse button press
		local rDown = self.inputStruct.RightDown:Connect(function()
			if not table.find(self.KeysRegistered, Enum.UserInputType.MouseButton2) then return end
			self.KeyPressed:Fire(Enum.UserInputType.MouseButton2)
		end)
		-- Middle mouse button press
		local mDown = self.inputStruct.MiddleDown:Connect(function()
			if not table.find(self.KeysRegistered, Enum.UserInputType.MouseButton3) then return end
			if self.MiddlePressed then
				self.MiddlePressed:Fire(Enum.UserInputType.MouseButton3)
			end
		end)
		-- Mouse wheel scroll
		local scrolled = self.inputStruct.Scrolled:Connect(function(z: number)
			if self.ScrolledSignal then
				self.ScrolledSignal:Fire(z)
			end
		end)
		-- Mouse movement
		local moved = self.inputStruct.Moved:Connect(function(vector: Vector2)
			if self.MovedSignal then
				self.MovedSignal:Fire(vector)
			end
		end)
		return lDown, rDown, mDown, scrolled, moved
	end
end

--[[
	Internal method - Sets up key/button release detection based on input type
	Connects to appropriate events (KeyUp, ButtonUp, MouseButton events)
	@return: RBXScriptConnection | multiple connections for mouse input
]]
function Component.__setUpInputStructKeyReleased(self: UserInputComponent)
	-- Keyboard input handling
	if self.inputStruct.KeyUp then
		return self.inputStruct.KeyUp:Connect(function(key: Enum.KeyCode)
			if not table.find(self.KeysRegistered, key) then return end
			self.KeyReleased:Fire(key)
		end)
		-- Gamepad input handling
	elseif self.inputStruct.ButtonUp then
		return self.inputStruct.ButtonUp:Connect(function(keycode: Enum.KeyCode)
			if not table.find(self.KeysRegistered, keycode) then return end
			self.KeyReleased:Fire(keycode)
		end)
		-- Mouse input handling
	elseif self.inputStruct.LeftUp or self.inputStruct.RightUp then
		-- Left mouse button release
		local lUp = self.inputStruct.LeftUp:Connect(function()
			if not table.find(self.KeysRegistered, Enum.UserInputType.MouseButton1) then return end
			self.KeyReleased:Fire(Enum.UserInputType.MouseButton1)
		end)
		-- Right mouse button release
		local rUp = self.inputStruct.RightUp:Connect(function()
			if not table.find(self.KeysRegistered, Enum.UserInputType.MouseButton2) then return end
			self.KeyReleased:Fire(Enum.UserInputType.MouseButton2)
		end)
		-- Middle mouse button release
		local mUp = self.inputStruct.MiddleUp:Connect(function()
			if not table.find(self.KeysRegistered, Enum.UserInputType.MouseButton3) then return end
			if self.MiddleReleased then
				self.MiddleReleased:Fire(Enum.UserInputType.MouseButton3)
			end
		end)
		return lUp, rUp, mUp
	end
end

--[[
	Public method - Connects callback to key/button press events
	@param callback: Function to call when a registered key is pressed
	@return: SignalConnectionStruct - Connection object for disconnecting
]]
function Component.Pressed(self: UserInputComponent, callback: (key: Enum.KeyCode | Enum.UserInputType) -> ()): SignalConnectionStruct
	if self.inputStruct.LeftDown then
		return self.KeyPressed:Connect(callback :: (key: Enum.UserInputType) -> ())
	end
	return self.KeyPressed:Connect(callback :: (key: Enum.KeyCode) -> ())
end

--[[
	Public method - Connects callback to key/button release events
	@param callback: Function to call when a registered key is released
	@return: SignalConnectionStruct - Connection object for disconnecting
]]
function Component.Released(self: UserInputComponent, callback: (key: Enum.KeyCode | Enum.UserInputType) -> ()): SignalConnectionStruct
	if self.inputStruct.LeftUp then
		return self.KeyReleased:Connect(callback :: (key: Enum.UserInputType) -> ())
	end
	return self.KeyReleased:Connect(callback :: (key: Enum.KeyCode) -> ())
end

--[[
	Observes changes in the user's preferred input method
	@param callback: Function called when input type changes
	@return: () -> () - Cleanup function to stop observing
]]
function Component.Observe(self: UserInputComponent, callback: (InputType: "Gamepad" | "MouseKeyboard" | "Touch") -> ()): () -> ()
	self.InputObserver = PreferredInput.Observe(callback)
	return self.InputObserver :: () -> ()
end

--[[
	Dynamically changes the input type at runtime
	@param InputType: New input type ("Gamepad", "Keyboard", or "Mouse")
]]
function Component.ChangeInputType(self: UserInputComponent, InputType: "Gamepad" | "Keyboard" | "Mouse")
	-- Clear all registered keys
	self:ChangeKey({})
	-- Destroy current input handler
	self.inputStruct:Destroy()
	-- Create new input handler
	self.inputStruct = inputGuard({InputType = InputType, Keys = {}})
	-- Handle mouse-specific signal initialization/cleanup
	if InputType == "Mouse" then
		if not self.MiddlePressed or not self.MiddleReleased then
			self.MiddlePressed = Signal.new()
			self.MiddleReleased = Signal.new()
			self.ScrolledSignal = Signal.new()
			self.MovedSignal = Signal.new()
		end
	else
		-- Clean up mouse-specific signals if switching away from mouse
		if self.MiddlePressed and self.MiddleReleased then
			self.MiddlePressed:Destroy()
			self.MiddleReleased:Destroy()
			if self.ScrolledSignal then self.ScrolledSignal:Destroy() end
			if self.MovedSignal then self.MovedSignal:Destroy() end
			self.MiddlePressed = nil
			self.MiddleReleased = nil
			self.ScrolledSignal = nil
			self.MovedSignal = nil
		end
	end
	-- Reconnect event handlers
	self:__setUpInputStructKeyPressed()
	self:__setUpInputStructKeyReleased()
end

--[[
	Replaces all currently registered keys with a new set
	@param Keys: Array of KeyCodes to register
]]
function Component.ChangeKey(self: UserInputComponent, Keys: {Enum.KeyCode})
	if not Keys then return end
	table.clear(self.KeysRegistered)
	local keyChanged = table.clone(Keys)
	for _, key in pairs(keyChanged) do
		table.insert(self.KeysRegistered, key)
	end
end

--[[
	Adds new keys to the existing registered set
	@param Keys: Array of KeyCodes to add
]]
function Component.AddKey(self: UserInputComponent, Keys: {Enum.KeyCode})
	if not Keys then return end
	for _, key in pairs(Keys) do
		if not table.find(self.KeysRegistered, key) then
			table.insert(self.KeysRegistered, key)
		end
	end
end

--[[
	Removes specific keys from the registered set
	@param Keys: Array of KeyCodes to remove
]]
function Component.RemoveKey(self: UserInputComponent, Keys: {Enum.KeyCode})
	if not Keys then return end
	for _, key in pairs(Keys) do
		local index = table.find(self.KeysRegistered, key)
		if index then
			table.remove(self.KeysRegistered, index)
		end
	end
end

--[[
	MOUSE ONLY - Connects callback to middle mouse button press events
	@param callback: Function to call when middle mouse button is pressed
	@return: SignalConnectionStruct? - Connection object or nil if not mouse input
]]
function Component.MiddleDown(self: UserInputComponent, callback: (key: Enum.UserInputType) -> ()): SignalConnectionStruct?
	if self.inputStruct.MiddleDown and self.MiddlePressed then
		return self.MiddlePressed:Connect(callback) :: SignalConnectionStruct
	end
	return nil
end

--[[
	MOUSE ONLY - Connects callback to middle mouse button release events
	@param callback: Function to call when middle mouse button is released
	@return: SignalConnectionStruct? - Connection object or nil if not mouse input
]]
function Component.MiddleUp(self: UserInputComponent, callback: (key: Enum.UserInputType) -> ()): SignalConnectionStruct?
	if self.inputStruct.MiddleUp and self.MiddleReleased then
		return self.MiddleReleased:Connect(callback) :: SignalConnectionStruct
	end
	return nil
end

--[[
	MOUSE ONLY - Connects callback to mouse wheel scroll events
	@param callback: Function to call when mouse wheel is scrolled
	@return: SignalConnectionStruct? - Connection object or nil if not mouse input
]]
function Component.Scrolled(self: UserInputComponent, callback: (scrollAmount: number) -> ()): SignalConnectionStruct?
	if self.inputStruct.Scrolled and self.ScrolledSignal then
		return self.ScrolledSignal:Connect(callback) :: SignalConnectionStruct
	end
	return nil
end

--[[
	MOUSE ONLY - Connects callback to mouse movement events
	@param callback: Function to call when mouse position changes
	@return: SignalConnectionStruct? - Connection object or nil if not mouse input
]]
function Component.Moved(self: UserInputComponent, callback: (pos: Vector2) -> ()): SignalConnectionStruct?
	if self.inputStruct.Moved and self.MovedSignal then
		return self.MovedSignal:Connect(callback)
	end
	return nil
end

--[[
	MOUSE ONLY - Disconnects all middle mouse button release callbacks
]]
function Component.DisconnectMiddleUpSignal(self: UserInputComponent)
	if self.MiddleReleased then
		self.MiddleReleased:DisconnectAll()
	end
end

--[[
	MOUSE ONLY - Disconnects all middle mouse button press callbacks
]]
function Component.DisconnectMiddleDownSignal(self: UserInputComponent)
	if self.MiddlePressed then
		self.MiddlePressed:DisconnectAll()
	end
end

--[[
	MOUSE ONLY - Disconnects all mouse wheel scroll callbacks
]]
function Component.DisconnectScrolledSignal(self: UserInputComponent)
	if self.ScrolledSignal then
		self.ScrolledSignal:DisconnectAll()
	end
end

--[[
	MOUSE ONLY - Disconnects all mouse movement callbacks
]]
function Component.DisconnectMovedSignal(self: UserInputComponent)
	if self.MovedSignal then
		self.MovedSignal:DisconnectAll()
	end
end

--[[
	Disconnects all key press event callbacks
	Useful for temporarily disabling input detection
]]
function Component.DisconnectPressed(self: UserInputComponent)
	self.KeyPressed:DisconnectAll()
end

--[[
	Disconnects all key release event callbacks
	Useful for temporarily disabling input detection
]]
function Component.DisconnectReleased(self: UserInputComponent)
	self.KeyReleased:DisconnectAll()
end

--[[
	Complete cleanup and destruction of the UserInput component
	Releases all resources, disconnects all events, and prepares for garbage collection
]]
function Component.Destroy(self: UserInputComponent)
	-- Clean up input observer
	if self.InputObserver then
		self.InputObserver()
		self.InputObserver = nil
	end
	-- Destroy main signals
	self.KeyPressed:Destroy()
	self.KeyReleased:Destroy()
	-- Destroy mouse-specific signals if they exist
	if self.MiddlePressed then
		self.MiddlePressed:Destroy()
		self.MiddleReleased:Destroy()
		if self.ScrolledSignal then self.ScrolledSignal:Destroy() end
		if self.MovedSignal then self.MovedSignal:Destroy() end
		self.MiddlePressed = nil
		self.MiddleReleased = nil
		self.ScrolledSignal = nil
		self.MovedSignal = nil
	end
	-- Destroy input handler and clear keys
	self.inputStruct:Destroy()
	self:RemoveKey(self.KeysRegistered)
end

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
Component.discconectmiddledownSignal = Component.DisconnectMiddleDownSignal
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
Component.DisconnectMiddle = Component.DisconnectMiddleUpSignal
Component.DisconnectMiddleDown = Component.DisconnectMiddleDownSignal
Component.ObserveInput = Component.Observe
Component.cleanup = Component.Destroy


return UserInput
