----

## Creating Component

To create a buffer, you will need to use these methods listed below:

```luau linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(size : number?)
```

This will create a buffer of X bytes.

!!! warning
    If the size is not set, the default value will be 0. You can
    always use `:allocate()` to increase the size.

----

### Advanced

There are other ways to create a buffer, for example:
with a string or simply with an existing buffer.

=== "from"

    ```luau linenums="1"
    local Buffer = require(somewhere.Buffer)
        
    local myBuffer = Buffer.from(b : buffer)
    ```

    !!! note
        Note that the buffer data is not lost, the offset is directly set to the buffer size. Please use `from` only when you know what you are doing.

=== "fromString"

    ```luau linenums="1"
    local Buffer = require(somewhere.Buffer)
        
    local myBuffer = Buffer.fromString(str : string)
    ```

    This will use the `.from` method once the buffer is converted to a buffer.

    !!! warning
        Please use this method only if you know what you are doing.

----

## Allocating space

When creating a buffer, you can later increase its size regardless of the method used.
Whether you use `from` or `fromString`, you can always expand the buffer size with `:allocate`.

```luau linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(0)

myBuffer:allocate(size : number)
```

## Others

Other useful methods are available in the component.

----

### Compress

```luau linenums="1"
local my_buffer = Buffer.create(1000)

local compressed_buffer = my_buffer:Compress(Enum.CompressionAlgorithm.Zstd)
print(compressed_buffer) --> buffer
```

Return a compressed buffer with the target Compression Algorithm

!!! info
	- This function use `EncodingService:CompressBuffer()`. Please see the Roblox API for more infos

!!! warning
    - Do not use this for buffers smaller than 30 bytes or in the 30–50 bytes range.

----

### Decompress (Constructor)

```luau linenums="1"
local my_buffer = Buffer.create(1000)

local compressed_buffer = my_buffer:Compress(Enum.CompressionAlgorithm.Zstd)
local decompressed_buffer = Buffer.Decompress(compressed_buffer,Enum.CompressionAlgorithm.Zstd)

print(decompressed_buffer)
```

Return the decompressed buffer as an `BufferComponentClass` with the target Compression Algorithm.

The buffer must be already compressed with the target Compression Algorithm.

!!! info
    - This function use <code>EncodingService:DecompressBuffer()</code>. Please see the Roblox API for more infos

!!! warning
    - Make sure you use the exact same Compression Algorithm as the compressed buffer.

----

### OnOffsetChanged

```luau linenums="1"
local my_buffer = Buffer.create(10)

my_buffer:OnOffsetChanged(function(oldOffset, newOffset)
	print(oldOffset,newOffset)
end)

my_buffer:writei8(127)
```

Connects a callback to the OffsetChanged signal.
The callback is called when the offset is changed.

Return : `SignalConnection`

----

### OnInstanceOffsetChanged

```luau linenums="1"
local my_buffer = Buffer.create(10)

my_buffer:OnInstanceOffsetChanged(function(oldOffset, newOffset)
	print(oldOffset,newOffset)
end)

my_buffer:WriteInstance(workspace.Baseplate)
```

Connects a callback to the InstanceOffsetChanged signal.
The callback is called when the instance offset is changed.

Return : `SignalConnection`

----

### OnCapacityChanged

```luau linenums="1"
local my_buffer = Buffer.create(10)

local connection = my_buffer:OnCapacityChanged(function(oldSize, newSize)
	print(oldSize,newSize)
end)

my_buffer += 5
my_buffer:allocate(5)
my_buffer *= 5

--later

connection:Disconnect()
```

Connects a callback to the CapacityChanged signal.
The callback is called when the capacity is changed.
	
!!! info
	- __mult can fire CapacityChanged same for __add
	- :allocate can fire CapacityChanged

Return : `SignalConnection`

----

### GetRemainingSpace

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(4)

print(myBuffer:GetRemainingSpace()) --> 4 cause we didn't write anything yet
```

return the actual remaining space of the current buffer

----

### GetOffset

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

print(myBuffer:GetOffset())
```

return the actual offset of the buffer

----

### GetInstanceOffset

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

print(myBuffer:GetInstanceOffset())
```

return the actual instance offset of the buffer

----

### GetBuffer

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

print(myBuffer:GetBuffer())
```

return the current buffer

----

### GetInstanceBuffer

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

print(myBuffer:GetInstanceBuffer())
```

return the current instance buffer

### GetBufferSize

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

print(myBuffer:GetBufferSize())
```

return the actual buffer size (not the written data size)

----

### Copy

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

local copy_myBuffer = myBuffer:Copy()
print(buff == copy_myBuffer) --> false
```

Create and return a copy of the current BufferComponent

----

### Clear

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

myBuffer:Clear()
```

clear the instance_buffer and the buffer itself

both offset will be set to 0.

!!! note
    this return self allow you to chain method

----

### ClearInstances

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

myBuffer:ClearInstances()
```

Clear the instance_buffer.

instance_offset will be set to 0.

!!! note
    this return self allow you to chain method

----

### ClearBuffer

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

myBuffer:ClearBuffer()
```

Clear the buffer.

The buffer offset will be set to 0.

!!! note
    this return self allow you to chain method

----

### DisconnectAllSignals

```luau linenums="1"
my_buffer:DisconnectAllSignals()
```

Disconnect all signals `OnOffsetChanged`,`OnInstanceOffset`,`OnCapacityChanged`

----

### Destroy

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(0)

myBuffer:Destroy()
```

Destroy the actual BufferComponent.
You can't use the BufferComponent after this.

----

## Alias

Alias for the constructor and the component

```luau linenums="1"
--Constructor alias
BufferConstructor.new = BufferConstructor.create
BufferConstructor.New = BufferConstructor.create
BufferConstructor.From = BufferConstructor.from
BufferConstructor.FromString = BufferConstructor.fromString
BufferConstructor.Tostring = BufferConstructor.tostring
BufferConstructor.serialize = BufferConstructor.Serialize
BufferConstructor.deserialize = BufferConstructor.Deserialize
BufferConstructor.deserializeAll = BufferConstructor.DeserializeAll
BufferConstructor.serializeAll = BufferConstructor.SerializeAll
BufferConstructor.decompress = BufferConstructor.Decompress
BufferConstructor.serializeCompressed = BufferConstructor.SerializeCompressed
BufferConstructor.deserializeCompressed = BufferConstructor.DeserializeCompressed
BufferConstructor.serializeAllCompressed = BufferConstructor.SerializeAllCompressed
BufferConstructor.deserializeAllCompressed = BufferConstructor.DeserializeAllCompressed

--Component alias
BufferComponent.Allocate = BufferComponent.allocate

--[Writer] signed interger alias
BufferComponent.writeI1 = BufferComponent.WriteI1
BufferComponent.writei1 = BufferComponent.WriteI1
BufferComponent.writeI8 = BufferComponent.WriteI8
BufferComponent.writei8 = BufferComponent.WriteI8
BufferComponent.writeI16 = BufferComponent.WriteI16
BufferComponent.writei16 = BufferComponent.WriteI16
BufferComponent.writeI24 = BufferComponent.WriteI24
BufferComponent.writei24 = BufferComponent.WriteI24
BufferComponent.writeI32 = BufferComponent.WriteI32
BufferComponent.writei32 = BufferComponent.WriteI32
BufferComponent.writeI40 = BufferComponent.WriteI40
BufferComponent.writei40 = BufferComponent.WriteI40
BufferComponent.writeI48 = BufferComponent.WriteI48
BufferComponent.writei48 = BufferComponent.WriteI48
BufferComponent.writeI54 = BufferComponent.WriteI54
BufferComponent.writei54 = BufferComponent.WriteI54

--[Writer] unsigned interger alias
BufferComponent.writeU1 = BufferComponent.WriteU1
BufferComponent.writeu1 = BufferComponent.WriteU1
BufferComponent.writeU8 = BufferComponent.WriteU8
BufferComponent.writeu8 = BufferComponent.WriteU8
BufferComponent.writeU16 = BufferComponent.WriteU16
BufferComponent.writeu16 = BufferComponent.WriteU16
BufferComponent.writeU24 = BufferComponent.WriteU24
BufferComponent.writeu24 = BufferComponent.WriteU24
BufferComponent.writeU32 = BufferComponent.WriteU32
BufferComponent.writeu32 = BufferComponent.WriteU32
BufferComponent.writeU40 = BufferComponent.WriteU40
BufferComponent.writeu40 = BufferComponent.WriteU40
BufferComponent.writeU48 = BufferComponent.WriteU48
BufferComponent.writeu48 = BufferComponent.WriteU48
BufferComponent.writeU54 = BufferComponent.WriteU54
BufferComponent.writeu54 = BufferComponent.WriteU54

--[Writer] float interger alias
BufferComponent.writeF16 = BufferComponent.WriteF16
BufferComponent.writef16 = BufferComponent.WriteF16
BufferComponent.writeF32 = BufferComponent.WriteF32
BufferComponent.writef32 = BufferComponent.WriteF32
BufferComponent.writeF64 = BufferComponent.WriteF64
BufferComponent.writef64 = BufferComponent.WriteF64

--[Writer] string alias
BufferComponent.writeString8 = BufferComponent.WriteString8
BufferComponent.writestring8 = BufferComponent.WriteString8
BufferComponent.writeString16 = BufferComponent.WriteString16
BufferComponent.writestring16 = BufferComponent.WriteString16
BufferComponent.writeString32 = BufferComponent.WriteString32
BufferComponent.writestring32 = BufferComponent.WriteString32
BufferComponent.writeString64 = BufferComponent.WriteString64
BufferComponent.writestring64 = BufferComponent.WriteString64
BufferComponent.writeString = BufferComponent.WriteString
BufferComponent.writestring = BufferComponent.WriteString

--[Writer] boolean alias
BufferComponent.writeBool1 = BufferComponent.WriteBool1
BufferComponent.writebool1 = BufferComponent.WriteBool1
BufferComponent.writeBool8 = BufferComponent.WriteBool8
BufferComponent.writebool8 = BufferComponent.WriteBool8


--[Writer] instance alias
BufferComponent.writeInstance = BufferComponent.WriteInstance
BufferComponent.writeinstance = BufferComponent.WriteInstance

--[Writer] roblox type alias
BufferComponent.writeVector2 = BufferComponent.WriteVector2
BufferComponent.writevector2 = BufferComponent.WriteVector2
BufferComponent.writeVector2int16 = BufferComponent.WriteVector2Int16
BufferComponent.writevector2int16 = BufferComponent.WriteVector2Int16
BufferComponent.writeVector3 = BufferComponent.WriteVector3
BufferComponent.writevector3 = BufferComponent.WriteVector3
BufferComponent.writeVector3int16 = BufferComponent.WriteVector3Int16
BufferComponent.writevector3int16 = BufferComponent.WriteVector3Int16
BufferComponent.writeCFrame = BufferComponent.WriteCFrame
BufferComponent.writecframe = BufferComponent.WriteCFrame
BufferComponent.writeLossyCFrame = BufferComponent.WriteLossyCFrame
BufferComponent.writelossyCFrame = BufferComponent.WriteLossyCFrame
BufferComponent.writeUdim = BufferComponent.WriteUDim
BufferComponent.writeudim = BufferComponent.WriteUDim
BufferComponent.WriteUdim = BufferComponent.WriteUDim
BufferComponent.writeUdim2 = BufferComponent.WriteUDim2
BufferComponent.writeudim2 = BufferComponent.WriteUDim2
BufferComponent.WriteUdim2 = BufferComponent.WriteUDim2
BufferComponent.writeColor3 = BufferComponent.WriteColor3
BufferComponent.writecolor3 = BufferComponent.WriteColor3
BufferComponent.writeRect = BufferComponent.WriteRect
BufferComponent.writerect = BufferComponent.WriteRect
BufferComponent.writeRegion3 = BufferComponent.WriteRegion3
BufferComponent.writeregion3 = BufferComponent.WriteRegion3
BufferComponent.WriteRegion3Int16 = BufferComponent.WriteRegion3int16
BufferComponent.writeRegion3int16 = BufferComponent.WriteRegion3int16
BufferComponent.writeregion3int16 = BufferComponent.WriteRegion3int16
BufferComponent.writeVector = BufferComponent.WriteVector
BufferComponent.writevector = BufferComponent.WriteVector
BufferComponent.writeEnum = BufferComponent.WriteEnum
BufferComponent.writeenum = BufferComponent.WriteEnum

--[Reader] signed interger alias
BufferComponent.readI1 = BufferComponent.ReadI1
BufferComponent.readi1 = BufferComponent.ReadI1
BufferComponent.readI8 = BufferComponent.ReadI8
BufferComponent.readi8 = BufferComponent.ReadI8
BufferComponent.readI16 = BufferComponent.ReadI16
BufferComponent.readi16 = BufferComponent.ReadI16
BufferComponent.readI24 = BufferComponent.ReadI24
BufferComponent.readi24 = BufferComponent.ReadI24
BufferComponent.readI32 = BufferComponent.ReadI32
BufferComponent.readi32 = BufferComponent.ReadI32
BufferComponent.readI40 = BufferComponent.ReadI40
BufferComponent.readi40 = BufferComponent.ReadI40
BufferComponent.readI48 = BufferComponent.ReadI48
BufferComponent.readi48 = BufferComponent.ReadI48
BufferComponent.readI54 = BufferComponent.ReadI54
BufferComponent.readi54 = BufferComponent.ReadI54

--[Reader] unsigned interger alias
BufferComponent.readU1 = BufferComponent.ReadU1
BufferComponent.readu1 = BufferComponent.ReadU1
BufferComponent.readU8 = BufferComponent.ReadU8
BufferComponent.readu8 = BufferComponent.ReadU8
BufferComponent.readU16 = BufferComponent.ReadU16
BufferComponent.readu16 = BufferComponent.ReadU16
BufferComponent.readU24 = BufferComponent.ReadU24
BufferComponent.readu24 = BufferComponent.ReadU24
BufferComponent.readU32 = BufferComponent.ReadU32
BufferComponent.readu32 = BufferComponent.ReadU32
BufferComponent.readU40 = BufferComponent.ReadU40
BufferComponent.readu40 = BufferComponent.ReadU40
BufferComponent.readU48 = BufferComponent.ReadU48
BufferComponent.readu48 = BufferComponent.ReadU48
BufferComponent.readU54 = BufferComponent.ReadU54
BufferComponent.readu54 = BufferComponent.ReadU54

--[Reader] float interger alias
BufferComponent.readF16 = BufferComponent.ReadF16
BufferComponent.readf16 = BufferComponent.ReadF16
BufferComponent.readF32 = BufferComponent.ReadF32
BufferComponent.readf32 = BufferComponent.ReadF32
BufferComponent.readF64 = BufferComponent.ReadF64
BufferComponent.readf64 = BufferComponent.ReadF64

--[Reader] boolean alias
BufferComponent.readBool1 = BufferComponent.ReadBool1
BufferComponent.readbool1 = BufferComponent.ReadBool1
BufferComponent.readBool8 = BufferComponent.ReadBool8
BufferComponent.readbool8 = BufferComponent.ReadBool8


--[Reader] string alias
BufferComponent.readString = BufferComponent.ReadString
BufferComponent.readstring = BufferComponent.ReadString

--[Reader] instance alias
BufferComponent.readInstance = BufferComponent.ReadInstance
BufferComponent.readinstance = BufferComponent.ReadInstance

--[Reader] roblox type alias
BufferComponent.readVector2 = BufferComponent.ReadVector2
BufferComponent.readvector2 = BufferComponent.ReadVector2
BufferComponent.ReadVector2Int16 = BufferComponent.ReadVector2int16
BufferComponent.readVector2int16 = BufferComponent.ReadVector2int16
BufferComponent.readvector2int16 = BufferComponent.ReadVector2int16
BufferComponent.readVector3 = BufferComponent.ReadVector3
BufferComponent.readvector3 = BufferComponent.ReadVector3
BufferComponent.readVector3int16 = BufferComponent.ReadVector3int16
BufferComponent.readvector3int16 = BufferComponent.ReadVector3int16
BufferComponent.ReadVector3Int16 = BufferComponent.ReadVector3int16
BufferComponent.readCFrame = BufferComponent.ReadCFrame
BufferComponent.readcframe = BufferComponent.ReadCFrame
BufferComponent.readLossyCFrame = BufferComponent.ReadLossyCFrame
BufferComponent.readlossyCFrame = BufferComponent.ReadLossyCFrame
BufferComponent.readUdim = BufferComponent.ReadUDim
BufferComponent.readudim = BufferComponent.ReadUDim
BufferComponent.ReadUdim = BufferComponent.ReadUDim
BufferComponent.readUdim2 = BufferComponent.ReadUDim2
BufferComponent.readudim2 = BufferComponent.ReadUDim2
BufferComponent.ReadUdim2 = BufferComponent.ReadUDim2
BufferComponent.readColor3 = BufferComponent.ReadColor3
BufferComponent.readcolor3 = BufferComponent.ReadColor3
BufferComponent.readRect = BufferComponent.ReadRect
BufferComponent.readrect = BufferComponent.ReadRect
BufferComponent.readRegion3 = BufferComponent.ReadRegion3
BufferComponent.readregion3 = BufferComponent.ReadRegion3
BufferComponent.ReadRegion3Int16 = BufferComponent.ReadRegion3int16
BufferComponent.readRegion3int16 = BufferComponent.ReadRegion3int16
BufferComponent.readregion3int16 = BufferComponent.ReadRegion3int16
BufferComponent.readVector = BufferComponent.ReadVector
BufferComponent.readvector = BufferComponent.ReadVector
BufferComponent.readEnum = BufferComponent.ReadEnum
BufferComponent.readenum = BufferComponent.ReadEnum

--[Signals] alias
BufferComponent.onOffsetChanged = BufferComponent.OnOffsetChanged
BufferComponent.onCapacityChanged = BufferComponent.OnCapacityChanged
BufferComponent.onInstanceOffsetChanged = BufferComponent.OnInstanceOffsetChanged
BufferComponent.disconnectAllSignals = BufferComponent.DisconnectAllSignals

--[Cursor] alias
BufferComponent.getOffset = BufferComponent.GetOffset
BufferComponent.getoffset = BufferComponent.GetOffset
BufferComponent.getInstanceOffset = BufferComponent.GetInstanceOffset
BufferComponent.getinstanceoffset = BufferComponent.GetInstanceOffset
BufferComponent.getRemainingSpace = BufferComponent.GetRemainingSpace

--[Buffer] alias
BufferComponent.compress = BufferComponent.Compress
BufferComponent.getBuffer = BufferComponent.GetBuffer
BufferComponent.getbuffer = BufferComponent.GetBuffer
BufferComponent.getInstanceBuffer = BufferComponent.GetInstanceBuffer
BufferComponent.getinstancebuffer = BufferComponent.GetInstanceBuffer
BufferComponent.getBufferSize = BufferComponent.GetBufferSize
BufferComponent.getbuffersize = BufferComponent.GetBufferSize
BufferComponent.Copy = BufferComponent.copy

--[Lifecycle] alias
BufferComponent.Clear = BufferComponent.clear
BufferComponent.ClearInstances = BufferComponent.clearInstances
BufferComponent.ClearBuffer = BufferComponent.clearBuffer
BufferComponent.Destroy = BufferComponent.Destroy
```
