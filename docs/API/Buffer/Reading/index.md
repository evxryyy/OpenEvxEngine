# Reading

## Reading Signed-int

To read signed numbers, the methods to use will be `:ReadI`, etc.

----

### Reading I1

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(1)

myBuffer:WriteI1(1)

print(myBuffer:ReadI1(0)) -> this will return 1
```

Read a Signed 1-bit integer from the buffer.

Range: -1 - 1

Returns:

- number on success
- nil on failure (warns)

----

### Reading I8

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(1)

myBuffer:WriteI8(127)

print(myBuffer:ReadI8(0)) --> this will return 127
```

Read a Signed 8-bit integer from the buffer (byte-aligned).

Returns number in [-128, 127] or nil on failure.

----

### Reading I16

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(2)

myBuffer:WriteI16(32_767)

print(myBuffer:ReadI16(0)) --> this will return 32,767
```

Read a Signed 16-bit integer from the buffer (byte-aligned).

Returns number in [-32768, 32767] or nil on failure.

----

### Reading I24

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(3)

myBuffer:WriteI24(8_388_607)

print(myBuffer:ReadI24(0)) --> this will return 8,388,607
```

Read a Signed 24-bit integer (big-endian) from the buffer.

Returns:

- number in [-2^23, 2^23-1] on success
- nil on failure (warns)

----

### Reading I32

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(4)

myBuffer:WriteI32(2_147_483_647)

print(myBuffer:ReadI32(0)) --> this will return 2,147,483,647
```

Read a Signed 32-bit integer from the buffer.

Returns number in [-2^31, 2^31-1] or nil on failure.

----

### Reading I40

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(5)

myBuffer:WriteI40(549_755_813_887)

print(myBuffer:ReadI40(0)) --> this will return 549,755,813,887
```

Read a Signed 40-bit integer (big-endian) from the buffer.

Range:
- -2^39 .. 2^39-1

Returns:

- number on success (exactly representable in double for 40-bit)
- nil on failure (warns)

----

### Reading I48

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(6)

myBuffer:WriteI48(140_737_488_355_327)

print(myBuffer:ReadI48(0)) --> this will return 140,737,488,355,327
```

Read a Signed 48-bit integer (big-endian) from the buffer.

Range:
-2^47 .. 2^47-1  (i.e., -140,737,488,355,328 .. 140,737,488,355,327)

Returns:

- number on success (exactly representable in double for 48-bit)
- nil on failure (warns)

----

### Reading I54

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(7)

myBuffer:WriteI54(9_007_199_254_740_991)

print(myBuffer:ReadI54(0)) --> this will return 9,007,199,254,740,991
```

Read a Signed 54-bit integer (big-endian) from the buffer.

Range:
-2^53 .. 2^53-1

Returns:

- number on success
- nil on failure (warns)

----

## Reading Unsigned-int

To read unsigned numbers, the methods to use will be `:ReadU`, etc.

----

### Reading U1

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(1)

myBuffer:WriteU1(1)

print(myBuffer:ReadU1(0)) --> this will return 1
```

Read 1 unsigned bit from the buffer.

Returns:
- 0 or 1 on success
- nil on failure (warns)

----

### Reading U8

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(1)

myBuffer:WriteU8(255)

print(myBuffer:ReadU8(0)) --> this will return 255
```

Read an Unsigned 8-bit integer (byte) from the buffer.

Returns number in [0, 255] or nil on failure.

----

### Reading U16

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(2)

myBuffer:WriteU16(65_535)

print(myBuffer:ReadU16(0)) --> this will return 65,535
```

Read an Unsigned 16-bit integer (big-endian) from the buffer.

Returns number in [0, 65535] or nil on failure.

----

### Reading U24

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(3)

myBuffer:WriteU24(16_777_215)

print(myBuffer:ReadU24(0)) --> this will return 16,777,215
```

Read an Unsigned 24-bit integer (big-endian) from the buffer.

Returns:

- number on success
- nil on failure (warns)

----

### Reading U32

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(4)

myBuffer:WriteU32(4_294_967_295)

print(myBuffer:ReadU32(0)) --> this will return 4,294,967,295
```

Read an Unsigned 32-bit integer from the buffer.

Returns number in [0, 2^32-1]

----

### Reading U40

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(5)

myBuffer:WriteU40(1_099_511_627_775)

print(myBuffer:ReadU40(0)) --> this will return 1,099,511,627,775
```

Read an Unsigned 40-bit integer (big-endian) from the buffer.

Returns:

- number on success (exact for 40-bit in double)
- nil on failure (warns)

----

### Reading U48

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(6)

myBuffer:WriteU48(281_474_976_710_655)

print(myBuffer:ReadU48(0)) --> this will return 281,474,976,710,655
```

Read an Unsigned 48-bit integer from the buffer (6 bytes, big-endian by default).

Returns:

- number in [0, 2^48 - 1] on success (exactly representable in double)
- nil on failure (warns)

----

### Reading U54

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(7)

myBuffer:WriteU54(18_014_398_509_481_980)

print(myBuffer:ReadU54(0)) --> this will return 18,014,398,509,481,980
```

Read an Unsigned 54-bit integer from the buffer.

Returns:

- number on success
- nil on failure (warns)

----

## Reading Float

For floats, methods like `:ReadF` will be used.

----

### Reading F16

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(2)

myBuffer:WriteF16(2.454)

print(myBuffer:ReadF16(0)) --> this will return 2.453125
```

Read a 16-bit half-precision float (IEEE 754 binary16) from the buffer.

Encoding:

- 1 sign bit, 5 exponent bits (bias 15), 10 mantissa bits.

Returns:

- number on success (double-precision representation of the half)
- nil on failure (warns)

Notes on special cases:

- Exponent == 0 and mantissa == 0 => +/- 0
- Exponent == 0 and mantissa != 0 => denormalized number
- Exponent == 31 (all ones):
    * mantissa == 0 => +/- infinity
    * mantissa != 0 => NaN

----

### Reading F32

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(4)

myBuffer:WriteF32(2.454)

print(myBuffer:ReadF32(0)) --> this will return 2.4539999961853027
```

Read a Float32 from the buffer at the given offset (or self.offset if not provided/valid).

Returns:

- number on success
- nil on failure (warns)

----

### Reading F64

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(8)

myBuffer:WriteF64(2.454)

print(myBuffer:ReadF64(0)) --> this will return 2.454
```

Read a Float64 from the buffer at the given offset (or self.offset if not provided/valid).

Returns:

- number on success
- nil on failure (warns)

----

## Reading Strings

For strings, only one method is available: `:ReadString`.

----

### Reading String

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(11)

myBuffer:WriteString("Hello World")
                            
--                       len|offset  
print(myBuffer:ReadString(11,0)) --> this will return Hello World
```

Read a String from the buffer.

Parameters:

- len: number of bytes to read. If omitted, defaults to Constants.MIN_STRING.
- offset (optional): byte offset to read from. If omitted/invalid, falls back to self.offset.

Returns:

- string on success
- nil on failure (warns)

----

## Reading Roblox Types

For reading Roblox types, the methods to use are `:Read[TypeName]`.

----

### Reading Bool1

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(1)

myBuffer:WriteBool1(true)
                            
print(myBuffer:ReadBool1(0)) --> this will return true
```

Read a 1-bit boolean from the buffer at a given bit offset.

Returns:

- boolean on success
- nil on failure (warns)

----

### Reading Bool8

```luau
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(1)

local arrayOfValues = {
    true,
    true,
    false,
    nil,
    1,
    true,
    "hello world",
    false
} 

myBuffer:WriteBool8(arrayOfValues)

print(myBuffer:ReadBool8(0))
--[[
      {
        value = {bool, bool, ..., bool}, -- the 8 bits in order
        majority = function(): boolean   -- true if more trues than falses
      }
]]
```

Read 8 booleans (1 bit each) starting at a given bit offset.

Returns:

A table:
{

   value = {bool, bool, ..., bool}, -- the 8 bits in order

   majority = function(): boolean   -- true if more trues than falses

}

----

### Reading Instance

```luau
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(0)

myBuffer:WriteInstance(workspace.Baseplate)

print(myBuffer:ReadInstance(1)) -- MUST BEGIN AT 1 NOT 0
```

Read an Instance from self.instance_buffer at the given index (or self.instance_offset).

Returns:

- Instance or nil

----

### Reading Vector2

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(16)

myBuffer:WriteVector2(Vector2.new(10,10))

print(myBuffer:ReadVector2(0)) --> this will return Vector2.new(10,10)
```

Read a Vector2 (double-precision) from the buffer

Returns:

- Vector2 on success
- nil on failure (warns)

----

### Reading Vector3

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(24)

myBuffer:WriteVector3(Vector3.new(10,10,5))

print(myBuffer:ReadVector3(0)) --> this will return Vector3.new(10,10,5)
```

Read a Vector3 (double-precision) from the buffer

Returns:

- Vector3 on success
- nil on failure (warns)

----

### Reading Vector2Int16

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(4)

myBuffer:WriteVector2Int16(Vector2int16.new(10,10))

print(myBuffer:ReadVector2int16(0)) --> this will return Vector2int16.new(10,10)
```

Read a Vector2int16 from the buffer

Returns:

- Vector2int16 on success
- nil on failure (warns)

----

### Reading Vector3Int16

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(6)

myBuffer:WriteVector3Int16(Vector3int16.new(10,10,10))

print(myBuffer:ReadVector3int16(0)) --> this will return Vector3int16.new(10,10)
```

Read a Vector3int16 from the buffer

Returns:

- Vector3int16 on success
- nil on failure (warns)

----

### Reading CFrame

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(96)

myBuffer:WriteCFrame(workspace.Baseplate.CFrame)

print(myBuffer:ReadCFrame(0)) --> return the cframe of the baseplate
```

Read a CFrame (double-precision) from the buffer

- Constructs CFrame.new(...) from these 12 components.

Returns:

- CFrame on success
- nil on failure (warns)

----

### Reading LossyCFrame

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(48)

myBuffer:WriteLossyCFrame(workspace.Baseplate.CFrame)

print(myBuffer:ReadLossyCFrame(0)) --> return the lossy cframe of the baseplate
```

Read a "Lossy" CFrame (single-precision) from the buffer

- Lower precision than ReadCFrame; saves space.

Returns:

- CFrame on success
- nil on failure (warns)

----

### Reading UDim

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(8)

local CornerRadius = YourGui.UICorner.CornerRadius -- This is a UDim

myBuffer:WriteUDim(CornerRadius)

print(myBuffer:ReadUDim(0)) --> return your UDim
```

Read a UDim from the buffer

Returns:

- UDim on success
- nil on failure (warns)

----

### Reading UDim2

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(16)

local pos = YourGui.Position -- This is a UDim2

myBuffer:WriteUDim2(pos)

print(myBuffer:ReadUDim(0)) --> return your position
```

Read a UDim2 from the buffer:

- Returns UDim2.new(scaleX, offsetX, scaleY, offsetY)

Returns:

- UDim2 on success
- nil on failure (warns)

----

### Reading Color3

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(12)

local color = Color3.new(1,1,1)

myBuffer:WriteColor3(color)

print(myBuffer:ReadColor3(0)) --> return the color3
```

Read a Color3 from the buffer:

Returns:

- Color3 on success
- nil on failure (warns)

----

### Reading Rect

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(32)

local rect1 = Rect.new(Vector2.new(10, 10), Vector2.new(80, 80))

myBuffer:WriteRect(rect1)

print(myBuffer:ReadRect(0)) --> return the rect
```

Read a Rect from the buffer:

- Two Vector2 (double-precision) values back-to-back: typically min then max (or vice versa).
- This implementation reads:
  max = ReadVector2(offset)
  min = ReadVector2(offset + 16)
  and returns Rect.new(min, max).

Returns:

- Rect on success
- nil on failure (if nested reads fail)

----

### Reading Region3

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(120)

local region = Region3.new(
    Vector3.new(0, 0, 0),
    Vector3.new(20, 20, 20)
)

myBuffer:WriteRegion3(region)

print(myBuffer:ReadRegion3(0)) --> return the region3
```

Read a Region3 from the buffer

Returns:

- Region3 on success
- nil on failure (if nested reads fail)

----

### Reading Region3Int16

```luau
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(12)

local region = Region3int16.new(
    Vector3int16.new(0, 0, 0),
    Vector3int16.new(50, 100, 50)
)

myBuffer:WriteRegion3int16(region)

print(myBuffer:ReadRegion3int16(0)) --> return the region3int16
```

Read a Region3int16 from the buffer

Returns:

- Region3int16 on success
- nil on failure (if nested reads fail)