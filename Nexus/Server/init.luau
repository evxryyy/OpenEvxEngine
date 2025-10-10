local RunService = game:GetService("RunService")

-- Import server-side networking component modules
local UnreliableRemoteEvent = require('@self/UnreliableRemoteEvent')  -- Unreliable UDP-style communication for server
local RemoteFunction = require('@self/RemoteFunction')              -- Server-client function calls
local RemoteEvent = require('@self/RemoteEvent')                    -- Reliable event-based communication for server

-- Server networking interface table
local Server = {}
Server.__index = Server

-- Expose all networking components for server-side usage
Server.RemoteEvent = RemoteEvent           -- Reliable event broadcasting to clients
Server.RemoteFunction = RemoteFunction     -- Request-response pattern with clients
Server.UnreliableRemoteEvent = UnreliableRemoteEvent  -- Fast, unreliable messaging to clients

return Server
