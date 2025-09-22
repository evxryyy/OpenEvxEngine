-- SocketClient Module - Client-side networking API aggregator
-- Provides unified access to all client-side Socket communication types
-- Usage: Socket.Client.Remote, Socket.Client.Function, Socket.Client.UnreliableRemote

-- Import client-side networking modules
local SocketUnreliableRemote = require('@self/SocketUnreliableRemote')  -- For unreliable, high-frequency events
local SocketFunction = require('@self/SocketFunction')                  -- For request-response communication
local SocketRemote = require('@self/SocketRemote')                      -- For reliable one-way events

-- Create the SocketClient namespace
local SocketClient = {}
SocketClient.__index = SocketClient

-- Expose client-side networking APIs
-- Each provides different communication patterns:
SocketClient.Remote = SocketRemote                      -- Reliable events (RemoteEvent wrapper)
SocketClient.UnreliableRemote = SocketUnreliableRemote -- Unreliable events (UnreliableRemoteEvent wrapper)
SocketClient.Function = SocketFunction                  -- Request-response (RemoteFunction wrapper)

return SocketClient
