local RunService = game:GetService("RunService")

-- Import networking component modules
local UnreliableRemoteEvent = require('@self/UnreliableRemoteEvent')  -- Unreliable UDP-style communication
local RemoteFunction = require('@self/RemoteFunction')              -- Client-server function calls
local RemoteEvent = require('@self/RemoteEvent')                    -- Reliable event-based communication

-- Client networking interface table
local Client = {}
Client.__index = Client

-- Expose all networking components for client-side usage
Client.RemoteEvent = RemoteEvent           -- Reliable event broadcasting
Client.RemoteFunction = RemoteFunction     -- Request-response pattern
Client.UnreliableRemoteEvent = UnreliableRemoteEvent  -- Fast, unreliable messaging

return Client
