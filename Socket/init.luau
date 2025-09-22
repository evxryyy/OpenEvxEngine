--[[
	Author : evxry_ll

	-- Socket Module - Main networking framework entry point (Buffer networking)
	-- Provides a unified, type-safe API for client-server communication in Roblox
	-- Features buffer serialization for efficient network usage
]]

-- Import sub-modules
local SocketClient = require('@self/SocketClient')  -- Client-side networking APIs
local SocketServer = require('@self/SocketServer')  -- Server-side networking APIs
local Buffer = require('./Buffer')                  -- Buffer serialization system

-- Export type definitions for external use
export type BufferComponent = Buffer.BufferComponentClass  -- Buffer instance type
export type BufferSchema = Buffer.BufferSchema           -- Schema definition type
export type BufferSchemaValue = {                        -- Data structure type
	[string] : any
}

-- Create the main Socket namespace
local Socket = {}
Socket.__index = Socket

-- Expose the complete API surface
Socket.Buffer = Buffer          -- Direct access to buffer utilities
Socket.Client = SocketClient    -- Client-side networking (Find methods)
Socket.Server = SocketServer    -- Server-side networking (Create methods)

return Socket
