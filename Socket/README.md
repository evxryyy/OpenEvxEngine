Socket Networking Framework for Roblox
A type-safe networking framework for Roblox that wraps RemoteEvent, RemoteFunction, and UnreliableRemoteEvent into a Buffer-based API with schemas for safer & faster communication.

🚀 Features:

✅ Socket.Server / Socket.Client unified API
✅ Buffer serialization → efficient networking
✅ Type schemas (String, Float64, I8, etc.)
✅ Reliable / Unreliable events support
✅ Request/Response functions
✅ Easy cleanup & type safety
📦 Installation
Put the OpenEvxEngine folder inside ReplicatedStorage.

Lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OpenEvxEngine = ReplicatedStorage:WaitForChild("OpenEvxEngine")

local Socket = require(OpenEvxEngine:WaitForChild("Socket"))
🧩 API Overview
Server-Side
Socket.Server.Remote.Create(name, schema) → 🔄 Reliable events
Socket.Server.UnreliableRemote.Create(name, schema) → ⚡ Fast, non-guaranteed events
Socket.Server.Function.Create(name, schema) → 📬 Request/Response
Client-Side
Socket.Client.Remote.Find(name, schema) → Reliable events
Socket.Client.UnreliableRemote.Find(name, schema) → Unreliable events
Socket.Client.Function.Find(name, schema) → Request/Response
Buffer Types
Common schema types:

"String", "String8", "String16"
"Float32", "Float64"
"I8", "I16", "I32", "U8", "U16", "U32"
"Boolean"
⚡ Examples
1️⃣ RemoteFunction (Request / Response)
Server
Lua

local Function = Socket.Server.Function.Create("TestFunc", {
    Message = "String8";
})

Function:InsertHandle(function(player, invokeValueSchema)
    local schema = { Value = "I8" }
    local value = { Value = 18 }
    return schema, value
end)
Client
Lua

local Remote = Socket.Client.Function.Find("TestFunc", {
    Message = "String8";
})

local result = Remote:Fire({Message = "Hello"}, {Value = "I8"})
print(result) -- {Value = 18}
2️⃣ RemoteEvent (Reliable One-Way)
Server
Lua

local Remote = Socket.Server.Remote.Create("Test", {
    Money = "Float64"
})

Remote:Connect(function(player, valueSchema)
    print(player.Name .. " sent:", valueSchema.Money)
end)
Client
Lua

local Remote = Socket.Client.Remote.Find("Test", {
    Money = "Float64"
})

Remote:Fire({
    Money = 15.155
})
3️⃣ UnreliableRemoteEvent (Non-Critical, High-Frequency)
⚠️ Max payload 1000 bytes, no guarantee of delivery/order.
Use for position, rotations, effects.

Server
Lua

local Remote = Socket.Server.UnreliableRemote.Create("Position", {
    X = "Float32";
    Y = "Float32";
})

Remote:Connect(function(player, data)
    print(player.Name .. " position:", data.X, data.Y)
end)
Client
Lua

local Remote = Socket.Client.UnreliableRemote.Find("Position", {
    X = "Float32";
    Y = "Float32";
})

-- Example: send updates every frame
game:GetService("RunService").Heartbeat:Connect(function()
    Remote:Fire({
        X = math.random(),
        Y = math.random()
    })
end)
