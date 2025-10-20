# Buffer

## What next

Buffer V1.9 (will take some time)
- adding `.__mult` to increase the size of the buffer
- fixing documentations and missing informations
- adding `:Deserialize` on the Component
- adding `.__call` to write types.

## Logs

Version : 1.8
- added support of :
  - `FloatCurveKey` 
  - `RotationCurveKey` 
  - `ColorSequence` 
  - `NumberRange`
  - `NumberSequence`
- added a table in the API so you can see all serializable types.
- added `@since v1.[update]` to function added in the recent version
- fixed a bug where `vector` from the luau library was causing issue with `.Serialize`

----

Version : 1.7.1
- Fixed a bug where serializing a `vector` was causing errors

----

### Version : 1.7

----

#### Fixes
- Fixed a bug where methods for the cursor/buffer was not returning the correct type.

----

#### Changes
- `clear` now return self this allow you to chain (e.g `myBuffer:clear():Destroy()`).
- Improved the capacity check when writing data it will now check the remaining space.
- `Utils.ConvertByte` the type `Gigabyte` is now renamed `Gigabytes` futures changes may occur.

----

#### News
- the type `vector` from the luau library is added, SEE THE API.
```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(24)

--the current vector library
local vect = vector.create(10,1,1)

myBuffer:WriteVector(vect) -- YOU CAN USE :WriteVector3() AS WELL
print(myBuffer:ReadVector(0)) -- return the actual vector.
```
- you can now write `Enum` inside the buffer, SEE THE API.
```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(4)

myBuffer:WriteEnum(Enum.KeyCode.A) -- or any enumItem you want
print(myBuffer:ReadEnum(0)) -- return the actual enum
```
- added `.GetRemainingSpace` this will return the remaining space in the buffer.
- added alias for `WriteVector` and `WriteEnum`.

----

Version : 1.6.9
- Added more alias.
 ```lua
BufferComponent.ReadVector2Int16 = BufferComponent.ReadVector2int16
BufferComponent.ReadVector3Int16 = BufferComponent.ReadVector3int16
BufferComponent.ReadRegion3Int16 = BufferComponent.ReadRegion3int16
 ```

Version : 1.6.8
- Fixed a bug where reading a Boolean1 was using ```offset``` instead of ```offset * 8```

Version : 1.6.7
- Fixed a bug where reading a Boolean1 set to false using Serialize and Deserialize was causing issues.

Version : 1.6.6
- Fixed a bug where WriteI8 and ReadRegion3 was showing values in the output.

Version : 1.6.5
- Changed ```type BufferSchemaValue``` to ```export type BufferSchemaValue```

Version : 1.6.4
- added __len and __add metamethod.
 ```lua
    myBuffer += 10 -- buffer size will be increased by 10
    local bufLen = #myBuffer -- return the size of the buffer
 ```
- Constants return table is now freeze.
- added Utils.ConvertByte(To : ConvertEnum, bytes : number) -> number
 ```lua
  --Converts bytes to a specified unit.
  type ConvertEnum = "Kilobytes" | "Megabytes" | "Gigabyte"
  bytes : number
  return : number
 ```

Version : 1.6.3
- Fixed a bug where Serializing a UDim or UDim2 was not working properly.

Version : 1.6.2
- Fixed a bug where Serializing a Bool1 with other type causing problem on Serialize and Deserialize.

Version : 1.6.1
- Fixed a bug where writting String8-64 with other type inside the schema cause problem on Deserialize.
- Fixed a bug where the Serialize function modify the ValueSchema instead of copying it.

### Version : 1.6 

#### Fixes
- Fixed a bug where writting some data-type with negative values doesn't work properly.

#### Changes
- In the file Constants MIN_FLOAT32-64 and MAX_FLOAT32-64 are disable this was causing problem when reading and writting the following type : Vectors , Regions , Udims, F32 , F64

#### News
- alias for Serialize and Deserialize
 ```lua
 BufferConstructor.serialize = BufferConstructor.Serialize
 BufferConstructor.deserialize = BufferConstructor.Deserialize
 ```

- added Serialization and Deserialization
 ```lua
  -- Recommend using Buffer.BufferSchema to get the list of all supported data types for serialization
  local TestSchema : Buffer.BufferSchema = {
      abc = "String16" --> allocates 16 bytes in the buffer
  }
  
  local ValueSchema = {
      abc = "Hello World"
  }
  
  -- Serialize the data according to the schema
  -- This returns a BufferComponentClass representing the serialized data
  local serialized = Buffer.Serialize(TestSchema, ValueSchema)
  
  -- Deserialize the buffer back into a Lua table using the same schema
  local deserialized = Buffer.Deserialize(TestSchema, serialized)
  
  print(serialized)   --> Shows BufferComponents and BufferSize: 16
  print(deserialized) --> {abc = "Hello World"}
  
  -- Example of complex serialization with nested schema
  local ComplexSchema : Buffer.BufferSchema = {
      message = {
          --[[
             THIS IS ONLY SUPPORTED FOR THE "String" TYPE AND NOT OTHER TYPES.
             Note: if the string length is below the defined length, a padding character (e.g., string.char(31)) will be added.
             On deserialization, these characters will be automatically removed.
          ]]
          Type = "String",
          Length = 11,   -- Allocate 11 bytes for the string
      },
      myAge = "I8",      -- 8-bit integer
  }
  
  local ComplexValueSchema = {
      message = "Hello World",
      myAge = 17,
  }
  
  -- Serialize complex data structure
  local serialized = Buffer.Serialize(ComplexSchema, ComplexValueSchema)
  
  -- Deserialize complex buffer back to Lua table
  local deserialized = Buffer.Deserialize(ComplexSchema, serialized)
  
  print(serialized)   --> BufferComponents, BufferSize: 12
  print(deserialized) --> {message = "Hello World", myAge = 17}
 ```

- Constants does now have a REQUIRED_BYTES list for all types
 ```lua
 REQUIRED_BYTES = {
 		I1 = 1,
 		I8 = 1,
 		I16 = 2,
 		I24 = 3,
 		I32 = 4,
 		I40 = 5,
 		I48 = 6,
 		I54 = 7,
 		U1 = 1,
 		U8 = 1,
 		U16 = 2,
 		U24 = 3,
 		U32 = 4,
 		U40 = 5,
 		U48 = 6,
 		U54 = 7,
 		F16 = 2,
 		F32 = 4,
 		F64 = 8,
 		String = function(str) : number
 			return #str	
 		end,
 		String8 = 8,
 		String16 = 16,
 		String32 = 32,
 		String64 = 64,
 		Bool1 = 1,
 		Bool8 = 1,
 		Color3 = 12,
 		Vector2 = 16,
 		Vector2int16 = 4,
 		Vector3 = 24,
 		Vector3int16 = 6,
 		CFrame = 96,
 		LossyCFrame = 48,
 		Rect = 32,
 		Region3 = 120,
 		Region3int16 = 12,
 		UDim = 8,
 		UDim2 = 16,
 	},
 ```

- Buffer now has a property called Enum, which refers to the list of all data types in the Buffer module.
- Buffer now has a property called Constants, which refers to the Constants module containg all minimum and maximum values of data-type including REQUIRED_BYTES list.
- Buffer now has a property callled Utils, which refers to the new Utils files containing functions.

### Version : 1.5

#### Fixes

#### Changes

#### News
- The buffer module now includes an enum list covering all supported data types. (See : BufferType)

Version : 1.4.3.1
- Updated comments
- Buffer documentation updated

### Version : 1.4.3

#### Fixes
- Fixed multiple bugs in write functions where invalid types produced incorrect debug output.

#### Changes
- Renamed ReadUdim and ReadUdim2 to ReadUDim and ReadUDim2 (old names remain supported for backward compatibility).
- All read functions now return their respective target type, or nil if the operation fails.

Version : 1.4.2
- .dev file is now removed.

Version : 1.4.1
- !native is now removed.

### Version : 1.4
 
#### Fixes
- Fixed multiple bugs related to reading integers and Roblox types.

#### Changes
- Each failed function call now outputs a clearer, more readable error message.
- Max value of UINT54 is now 18 014 398 509 481 980.
- ReadString now requires a length value.
- Offsets for UDim and UDim2 are now stored as SignedInt32 instead of Float32.

#### News
- SignedInt1 -> (-1 - 1).
- Introduced a debug file for extending or customizing debug methods.

Version : 1.3.1
- added more alias for the component
  ```lua
  --[Writer] boolean alias
  BufferComponent.writeBool1 = BufferComponent.WriteBool1
  BufferComponent.writebool1 = BufferComponent.WriteBool1
  BufferComponent.writeBool8 = BufferComponent.WriteBool8
  BufferComponent.writebool8 = BufferComponent.WriteBool8
  --[Reader] boolean alias
  BufferComponent.readBool1 = BufferComponent.ReadBool1
  BufferComponent.readbool1 = BufferComponent.ReadBool1
  BufferComponent.readBool8 = BufferComponent.ReadBool8
  BufferComponent.readbool8 = BufferComponent.ReadBool8
  ```

Version : 1.3
- fixed a bug where ReadU1 was not available on the current version
- change type annotation to 
  ```lua
   export type BufferComponentClass = typeof(setmetatable({} :: {
  	offset : number,
  	instance_offset : number,
  	buffer : buffer,
  	instance_buffer : { Instance },
  	allocate : (self : BufferComponentClass,size : number) -> (),
   },BufferComponent))
  ```
- added alot of alias for the buffer component and the constructor
  ```lua
  --Constructor alias
  BufferConstructor.new = BufferConstructor.create
  BufferConstructor.New = BufferConstructor.create
  BufferConstructor.From = BufferConstructor.from
  BufferConstructor.FromString = BufferConstructor.fromString
  BufferConstructor.Tostring = BufferConstructor.tostring
  
  --Component alias
  BufferComponent.Allocate = BufferComponent.allocate
  
  --[Writer] signed interger alias
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
  BufferComponent.writeUdim = BufferComponent.WriteUdim
  BufferComponent.writeudim = BufferComponent.WriteUdim
  BufferComponent.writeUdim2 = BufferComponent.WriteUdim2
  BufferComponent.writeudim2 = BufferComponent.WriteUdim2
  BufferComponent.writeColor3 = BufferComponent.WriteColor3
  BufferComponent.writecolor3 = BufferComponent.WriteColor3
  BufferComponent.writeRect = BufferComponent.WriteRect
  BufferComponent.writerect = BufferComponent.WriteRect
  BufferComponent.writeRegion3 = BufferComponent.WriteRegion3
  BufferComponent.writeregion3 = BufferComponent.WriteRegion3
  BufferComponent.writeRegion3int16 = BufferComponent.WriteRegion3int16
  BufferComponent.writeregion3int16 = BufferComponent.WriteRegion3int16
  
  --[Reader] signed interger alias
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
  
  --[Reader] string alias
  BufferComponent.readString = BufferComponent.ReadString
  BufferComponent.readstring = BufferComponent.ReadString
  
  --[Reader] instance alias
  BufferComponent.readInstance = BufferComponent.ReadInstance
  BufferComponent.readinstance = BufferComponent.ReadInstance
  
  --[Reader] roblox type alias
  BufferComponent.readVector2 = BufferComponent.ReadVector2
  BufferComponent.readvector2 = BufferComponent.ReadVector2
  BufferComponent.readVector2int16 = BufferComponent.ReadVector2int16
  BufferComponent.readvector2int16 = BufferComponent.ReadVector2int16
  BufferComponent.readVector3 = BufferComponent.ReadVector3
  BufferComponent.readvector3 = BufferComponent.ReadVector3
  BufferComponent.readVector3int16 = BufferComponent.ReadVector3int16
  BufferComponent.readvector3int16 = BufferComponent.ReadVector3int16
  BufferComponent.readCFrame = BufferComponent.ReadCFrame
  BufferComponent.readcframe = BufferComponent.ReadCFrame
  BufferComponent.readLossyCFrame = BufferComponent.ReadLossyCFrame
  BufferComponent.readlossyCFrame = BufferComponent.ReadLossyCFrame
  BufferComponent.readUdim = BufferComponent.ReadUdim
  BufferComponent.readudim = BufferComponent.ReadUdim
  BufferComponent.readUdim2 = BufferComponent.ReadUdim2
  BufferComponent.readudim2 = BufferComponent.ReadUdim2
  BufferComponent.readColor3 = BufferComponent.ReadColor3
  BufferComponent.readcolor3 = BufferComponent.ReadColor3
  BufferComponent.readRect = BufferComponent.ReadRect
  BufferComponent.readrect = BufferComponent.ReadRect
  BufferComponent.readRegion3 = BufferComponent.ReadRegion3
  BufferComponent.readregion3 = BufferComponent.ReadRegion3
  BufferComponent.readRegion3int16 = BufferComponent.ReadRegion3int16
  BufferComponent.readregion3int16 = BufferComponent.ReadRegion3int16
  
  --[Cursor] alias
  BufferComponent.getOffset = BufferComponent.GetOffset
  BufferComponent.getoffset = BufferComponent.GetOffset
  BufferComponent.getInstanceOffset = BufferComponent.GetInstanceOffset
  BufferComponent.getinstanceoffset = BufferComponent.GetInstanceOffset
  
  --[Buffer] alias
  BufferComponent.getBuffer = BufferComponent.GetBuffer
  BufferComponent.getbuffer = BufferComponent.GetBuffer
  BufferComponent.getInstanceBuffer = BufferComponent.GetInstanceBuffer
  BufferComponent.getinstancebuffer = BufferComponent.GetInstanceBuffer
  BufferComponent.getBufferSize = BufferComponent.GetBufferSize
  BufferComponent.getbuffersize = BufferComponent.GetBufferSize
  
  --[Lifecycle] alias
  BufferComponent.Clear = BufferComponent.clear
  BufferComponent.Destroy = BufferComponent.Destroy
  ```

Version : 1.2.2
- updated comments.

Version : 1.2.1
- fixed Buffer.init.spec

Version : 1.2
- added GetOffset() : number, get the current offset of the buffer
- added GetInstanceOffset() : number,get the current instance offset of the instance buffer
- added GetBuffer() : buffer,get the actual buffer
- added GetInstanceBuffer() : { Instance }, get the actual instance buffer
- added GetBufferSize() : number,get the buffer size (not the written data size)
- added clear(), clear the current buffer and the offset too
- added Destroy(), destroy the current BufferComponent

Version : 1.1.1
- fixed Buffer.init.spec

Version : 1.1
- added .__tostring(), for BufferComponent when "print" is called
- added .fromString(), create a BufferComponent with the given string (data are not lost)
- added .tostring(), convert the BufferComponent to a string .fromString (data are not lost) can be called to transform the string back to a BufferComponent

Version : 1.0
- Released the module
