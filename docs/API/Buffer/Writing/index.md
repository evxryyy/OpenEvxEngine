### Writing Signed-int

----

To write signed numbers, you will need to use methods like
`:WriteI1`, etc.

#### Writing I1

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(1)
local num = 1

myBuffer:WriteI1(num)
```

Write a signed 1-bit integer (-1 to 1).
The value is clamped to the allowed range and truncated to an integer.

----

#### Writing I8

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(1)
local num = 127

myBuffer:WriteI8(num)
```

Write a signed 8-bit integer (-128 to 127). Clamped and truncated to integer.

----

#### Writing I16

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(2)
local num = 32_767

myBuffer:WriteI16(num)
```

Write a signed 16-bit integer (-32768 to 32767). Clamped and truncated.

----

#### Writing I24

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(3)
local num = 8_388_607

myBuffer:WriteI24(num)
```

Write a signed 24-bit integer (-8,388,608 to 8,388,607).
Clamped and truncated.

----

#### Writing I32

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(4)
local num = 2_147_483_647

myBuffer:WriteI32(num)
```

Write a signed 32-bit integer (-2,147,483,648 to 2,147,483,647).
- Clamped and truncated.

----

#### Writing I40

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(5)
local num = 549_755_813_887

myBuffer:WriteI40(num)
```

Write a signed 40-bit integer (-549,755,813,888 to 549,755,813,887).
Clamped and truncated.

If negative, add 2^40 to represent as unsigned (two's complement style) before writing.

----

#### Writing I48

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(6)
local num = 140_737_488_355_327

myBuffer:WriteI48(num)
```

Write a signed 48-bit integer (-140,737,488,355,328 to 140,737,488,355,327).
Clamped and truncated.

If negative, add 2^48 to represent as unsigned before writing.

----

#### Writing I54

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(7)
local num = 9_007_199_254_740_991

myBuffer:WriteI54(num)
```

Write a signed 54-bit integer (-9,007,199,254,740,992 to 9,007,199,254,740,991).
Clamped and truncated.

If negative, add 2^54 to represent as unsigned before writing.

----

### Writing Unsigned-int

For unsigned numbers, you will need to use methods like `:WriteU`, etc.

----

#### Writing U1

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(1)
local num = 1

myBuffer:WriteU1(num)
```

Write a single unsigned bit (0 or 1).
Clamped and truncated.

----

#### Writing U8

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(1)
local num = 255

myBuffer:WriteU8(num)
```

Write an unsigned 8-bit integer (0 to 255).
Clamped and truncated.

----

#### Writing U16

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(2)
local num = 65_535

myBuffer:WriteU16(num)
```

Write an unsigned 16-bit integer (0 to 65,535).
Clamped and truncated.

----

#### Writing U24

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(3)
local num = 16_777_215

myBuffer:WriteU24(num)
```

Write an unsigned 24-bit integer (0 to 16,777,215).
Clamped and truncated.

----

#### Writing U32

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(4)
local num = 4_294_967_295

myBuffer:WriteU32(num)
```

Write an unsigned 32-bit integer (0 to 4,294,967,295).
Clamped and truncated.

----

#### Writing U40

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(4)
local num = 1_099_511_627_775

myBuffer:WriteU40(num)
```

Write an unsigned 40-bit integer (0 to 1,099,511,627,775).
Clamped.

----

#### Writing U48

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(4)
local num = 281_474_976_710_655

myBuffer:WriteU48(num)
```

Write an unsigned 48-bit integer (0 to 281,474,976,710,655).
Clamped and truncated.

----

#### Writing U54

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(4)
local num = 18_014_398_509_481_980

myBuffer:WriteU54(num)
```

Write an unsigned 54-bit integer (0 to 18,014,398,509,481,980).
Clamped and truncated.

!!! note
    The maximum value is 18,014,398,509,481,984 but i clamped it to 18,014,398,509,481,980 cause it was causing a bug.

----

### Writing Float

For floating-point numbers, you will need to use methods like `:WriteF`, etc.

----

#### Writing F16

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(2)
local num = 1.545

myBuffer:WriteF16(num)
```
Write a 16-bit float (half-precision) to the buffer.
Lower precision than F32/F64, expect rounding.

NaN/Inf are handled, finite values are encoded with sign/exponent/mantissa.

----

#### Writing F32

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(4)
local num = 100.999

myBuffer:WriteF32(num)
```

Write a 32-bit float to the buffer.

----

#### Writing F64

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(8)
local num = 100.9999999999

myBuffer:WriteF64(num)
```

Write a 64-bit float to the buffer.

----

### Writing Strings

For character strings, you must use methods like `:WriteString`, etc.

----

#### Writing String8

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(8)

myBuffer:WriteString8("Hello",5)
```

Write a string clamped to max 8 characters.

`len` is the intended fixed length to write.

The input string is truncated to `len` (clamped to [1, 8]).

----

#### Writing String16

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(16)

myBuffer:WriteString16("Hello World",11)
```

Write a string clamped to max 16 characters.

`len` is the intended fixed length to write.

The input string is truncated to `len` (clamped to [1, 16]).

----

#### Writing String32

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(32)

myBuffer:WriteString32("Hello World",11)
```

Write a string clamped to max 32 characters.

`len` is the intended fixed length to write.

The input string is truncated to `len` (clamped to [1, 32]).

----

#### Writing String64

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(64)

myBuffer:WriteString32("Hello World",11)
```

Write a string clamped to max 64 characters.

`len` is the intended fixed length to write.

The input string is truncated to `len` (clamped to [1, 64]).

----

#### Writing String

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(11)

myBuffer:WriteString("Hello World")
```

Write a string without caring about length limits.

Writes exactly #value bytes.

Reader must know or infer the length (no prefix is written).

----

### Writing Roblox Types

For other types like boolean, vector, etc. please use `:Write[TypeName]`, etc.

----

#### Writing Bool1

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(1)

myBuffer:WriteBool1(true)
```

Write a single boolean using 1 bit.
- nil/false -> 0, anything else -> 1

----

#### Writing Bool8

```luau linenums="1" linenums="1"
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
```

Write 8 booleans packed into 1 byte.

Accepts an array-like table of up to 8 values.
Each truthy value sets the corresponding bit to 1.

----

#### Writing Instance

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(0) --> byte are not required if you only write instance

myBuffer:WriteInstance(workspace.Baseplate)
```

Store an Instance in the side `instance_buffer`.
Does not write anything to the raw byte buffer.

`instance_offset` is incremented to track count/index.

----

#### Writing Vector2

```luau linenums="1" linenums="1"

local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(16) 

local pos = Vector2.new(10.5,5.945)

myBuffer:WriteVector2(pos)
```

Write a Vector2 as two f64 (x, y).

----

#### Writing Vector3

```luau linenums="1" linenums="1"

local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(24) 

local pos = workspace.Baseplate.Position

myBuffer:WriteVector3(pos)
```

Write a Vector3 as three f64 (x, y, z).

----

#### Writing Vector2Int16

```luau linenums="1" linenums="1"

local Buffer = require(somewhere.Buffer)
    
local myBuffer = Buffer.create(4) 

local pos = Vector2int16.new(10,5)

myBuffer:WriteVector2Int16(pos)
```

Write a Vector2int16 as two i16 (x, y).
Values clamped to int16 range.

----

#### Writing Vector3Int16

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(4)

local pos = Vector3int16.new(10,5,15)

myBuffer:WriteVector3Int16(pos)
```

Write a Vector3int16 as three i16 (x, y, z).
Values clamped to int16 range.

----

#### Writing CFrame

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(96)

local cf = workspace.Baseplate.CFrame

myBuffer:WriteCFrame(cf)
```

Write a full-precision CFrame as 12 f64 components (position + rotation matrix).

----

#### Writing LossyCFrame

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(48)

local cf = workspace.Baseplate.CFrame

myBuffer:WriteLossyCFrame(cf)
```

Write a lossy (compressed) CFrame as 12 f32 components.

----

#### Writing UDim

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(8)

local CornerRadius = YourGui.UICorner.CornerRadius -- This is a UDim

myBuffer:WriteUDim(CornerRadius)
```

Write a UDim as two f32 (Scale, Offset).

----

#### Writing UDim2

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(16)

local pos = YourGui.Position -- This is a UDim2

myBuffer:WriteUDim2(pos)
```

Write a UDim2 as four f32 (X.Scale, Y.Scale, X.Offset, Y.Offset).

----

#### Writing Color3

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(12)

local color = Color3.new(1,1,1)

myBuffer:WriteColor3(color)
```

Write a Color3 as three f32 (r, g, b).
Values clamped to float32 range [0f,1f] typically already valid.

----

#### Writing Rect

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(32)

local rect1 = Rect.new(Vector2.new(10, 10), Vector2.new(80, 80))

myBuffer:WriteRect(rect1)
```

Write a Rect as two Vector2 (Min, Max) using f64.

Relies on WriteVector2 to do the actual writing and offset increments.

----

#### Writing Region3

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(120)

local region = Region3.new(
    Vector3.new(0, 0, 0),
    Vector3.new(20, 20, 20)
)

myBuffer:WriteRegion3(region)
```

Write a Region3 as CFrame + Size.

Intended: CFrame (12 f64 = 96 bytes) + Vector3 (3 f64 = 24 bytes) = 120 bytes.

----

#### Writing Region3Int16

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(12)

local region = Region3int16.new(
    Vector3int16.new(0, 0, 0),
    Vector3int16.new(50, 100, 50)
)

myBuffer:WriteRegion3int16(region)
```

Write a Region3int16 as two Vector3int16 (Max then Min).

----

#### Writing Vector (luau library)

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(24)

--the current vector library
local vect = vector.create(10,1,1)

myBuffer:WriteVector(vect) -- YOU CAN USE :WriteVector3() AS WELL
```

Write a vector with the 'vector' luau linenums="1" library 

- 24 bytes total.

----

#### Writing Enum

```luau linenums="1" linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(4)

myBuffer:WriteEnum(Enum.KeyCode.A) -- or any enumItem you want
```

Writes an EnumItem to the buffer using a compact 4-byte format.
	
The enum is stored as:

- 2 bytes (U16): Enum type ID
- 2 bytes (U16): Enum item value

----

#### Writing RotationCurveKey

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(218)

local key = RotationCurveKey.new(1.5, CFrame.new(), Enum.KeyInterpolationMode.Linear)
myBuffer:WriteRotationCurveKey(key) -- Writes 104 bytes
	
local cubicKey = RotationCurveKey.new(2.0, CFrame.Angles(0, math.pi, 0), Enum.KeyInterpolationMode.Cubic)
myBuffer:WriteRotationCurveKey(cubicKey) -- Writes 112 bytes with tangents
```

Writes a RotationCurveKey to the buffer with variable size based on interpolation mode.

Total size:

- 104 bytes for Linear/Constant interpolation
- 112 bytes for Cubic interpolation (includes tangent data)

!!! info
    - Cubic interpolation requires additional storage for smooth curve tangents
    - The tangent values control the curve's shape between keyframes

----

#### Writing FloatCurveKey

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(40)

local key = FloatCurveKey.new(0.5, 1.25, Enum.KeyInterpolationMode.Linear)
myBuffer:WriteFloatCurveKey(key) -- Writes 16 bytes
	
local cubicKey = FloatCurveKey.new(1.0, 2.5, Enum.KeyInterpolationMode.Cubic)
cubicKey.LeftTangent = 0.5
cubicKey.RightTangent = 0.5
myBuffer:WriteFloatCurveKey(cubicKey) -- Writes 24 bytes with tangents
```

Write a FloatCurveKey to the buffer with variable size based on interpolation mode.

Total size:

- 16 bytes for Linear/Constant interpolation
- 24 bytes for Cubic interpolation (includes tangent data)

!!! info
    - Value is stored as F64 for maximum precision in animation curves
    - Tangents control the curve's acceleration/deceleration for smooth transitions

----

#### Writing ColorSequence

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(49)

local gradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),    -- Red at start
	ColorSequenceKeypoint.new(0.5, Color3.new(0, 1, 0)),  -- Green at middle
	ColorSequenceKeypoint.new(1, Color3.new(0, 0, 1))     -- Blue at end
})
myBuffer:WriteColorSequence(gradient) -- Writes 49 bytes (1 + 3*16)
```

Writes a ColorSequence to the buffer with all its keypoints.

Total size: 1 + (16 * keypoint_count) bytes

!!! info
    - Color values are converted from Roblox's 0-1 range to 0-255 for storage
    - Keypoints are written in their original order

!!! warning
    - Maximum 255 keypoints due to U8 count storage.

----

#### Writing NumberRange

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(8)

Buffer:WriteNumberRange(NumberRange.new(0, 10))
```

Writes a NumberRange to the buffer using a compact 8-byte layout.

!!! info
    - Values are written as provided; no clamping or reordering is performed
    - Uses F32 for both fields to keep the footprint small and consistent

----

#### Writing NumberSequence

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(37)

local seq = NumberSequence.new({
	NumberSequenceKeypoint.new(0.0, 0.0),
	NumberSequenceKeypoint.new(0.5, 1.0, 0.25),
	NumberSequenceKeypoint.new(1.0, 0.0),
})

myBuffer:WriteNumberSequence(seq)
```

Writes a NumberSequence to the buffer with all its keypoints.

Total size: 1 + (12 * keypoint_count) bytes

!!! info
    - Envelope is written for every keypoint (0 if not used)
    - Keypoints are written in their original order

!!! warning
    - Maximum of 255 keypoints due to U8 count storage.

----

### Custom Writing

----

#### WriteAs

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local myBuffer = Buffer.create(14)

--[[
    For all string type please define the length at the end
    or this will not work
]]
myBuffer:WriteAs("String","Hello World !!",14)
```

Write any target type to the buffer

!!! warning
    - Use specific Write functions when possible for better performance

Params :

- @param valueType: ValueType - Type of value to write
- @param value: T - Value to write
- @param __optionalParam: any? - Optional parameter (e.g. string length)

----

#### WriteArray

```luau linenums="1"
local Buffer = require(somewhere.Buffer)

local my_buffer = Buffer.create(145)

local schema = {
	{Type =  "String",Length = 8},
	"RotationCurveKey",
	"ColorSequence"
}

local value = {
	"Hello World !!", -- will be "Hello Wo" (limit to 8 characters)
	RotationCurveKey.new(0,workspace.Baseplate.CFrame,Enum.KeyInterpolationMode.Linear),
	ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
	})
}

my_buffer:WriteArray(schema,value)
```

Writes an array of typed values to the buffer.

- @param array {ValueType} - Array of value types (e.g., "U8", "Float32", "String16")
- @param value {T} - Array of corresponding values to write

!!! info
    For complex types (e.g String) please use the example above this function is different from `WriteAs`,

    for String8 etc... you can use the normal way this only apply for `undefined-string length`.

    Also note that the order is important.
