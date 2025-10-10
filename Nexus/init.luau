--[[
	Author : evxry_ll
	Version: 1.0.1

    Nexus Networking Module
    
    A simple networking solution for Roblox that provides basic
    client-server communication without complex buffer handling.
    
    Usage Example:
    --------------
    -- On server:
    local Nexus = require(path)
    local Remote = Nexus.Server.new("PlayerJoined")
    Remote:Fire(player, "PlayerJoined", playerData)
    
    -- On client:  
    local Nexus = require(path)
    local Remote = Nexus.Client.new("PlayerJoined") --> this will get the remote event created on the server
  	Remote:Connect("PlayerJoined", function(data)
        print("Player joined:", data)
    end)
    
    Features:
    - Separate client and server modules
    - Simple event-based communication
    - No complex serialization/buffer management
    - Easy-to-use API for basic networking needs
]]

local RunService = game:GetService("RunService")

-- Import client and server networking modules
local Client = require("@self/Client")  -- Handles client-side networking
local Server = require("@self/Server")  -- Handles server-side networking

-- Main networking module table
local Nexus = {}
Nexus.__index = Nexus

-- Expose client and server modules as properties
Nexus.Client = Client  -- Client-side networking interface
Nexus.Server = Server  -- Server-side networking interface

return Nexus
