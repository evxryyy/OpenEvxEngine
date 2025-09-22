-- SocketServer Module - Server-side networking API aggregator
-- Provides unified access to all server-side Socket communication types
-- Usage: Socket.Server.Remote, Socket.Server.Function, Socket.Server.UnreliableRemote

-- Import server-side networking modules
local SocketUnreliableRemote = require('@self/SocketUnreliableRemote')  -- For unreliable, high-frequency events
local SocketFunction = require('@self/SocketFunction')                  -- For request-response communication
local SocketRemote = require('@self/SocketRemote')                      -- For reliable one-way events

-- Create the SocketServer namespace
local SocketServer = {}
SocketServer.__index = SocketServer

-- Expose server-side networking APIs
-- Each provides different communication patterns:
SocketServer.Remote = SocketRemote                      -- Reliable events (RemoteEvent wrapper)
SocketServer.UnreliableRemote = SocketUnreliableRemote -- Unreliable events (UnreliableRemoteEvent wrapper)
SocketServer.Function = SocketFunction                  -- Request-response (RemoteFunction wrapper)

return SocketServer
