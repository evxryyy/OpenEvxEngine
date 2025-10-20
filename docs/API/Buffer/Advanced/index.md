## Getting Started

The buffer module contains metamethods to facilitate debugging, etc.
Here are the buffer properties:

`.buffer` -> current buffer for writings

`.offset` -> current offset

`.instance_offset` -> current offset for the instance_buffer

`.instance_buffer` -> table containing the instances

----

## Metamethods

----

### __len

To get the buffer size more easily, you can use this:

````luau
local size = #bufferComponent
````

This will return the buffer size.

----

### __tostring

When you print the component, instead of displaying a table it will show:

```luau
print(bufferComponent) -> BufferComponent(Size : number)
```

----

### __add

__add metamethod for buffer resizing.

- Resizes the buffer by the specified number of bytes.
- Returns the updated BufferComponent instance.

```luau
--will increase the buffer size by 5
bufferComponent += 5
```

----

### __mul

Expands the underlying buffer by a numeric factor using the * operator.

- Allocates a new buffer of size modf(oldSize * value), float are not allowed.
- Copies the old contents into the new buffer (starting at offset 0).
- Keeps the same write offset.
- Returns the updated BufferComponent instance.
- Throws an error if the value is less than or equal to 1.

```luau
--will increase the buffer size by (current_size * 5)
bufferComponent *= 10
```

----

### __call

Dynamic writer dispatch via __call.

```luau
bufferComponent("U32", 10)
bufferComponent("String", "hello")
bufferComponent("Boolean1", true)
bufferComponent("Float32", 1.5)
bufferComponent("FloatCurveKey", key)
bufferComponent("RotationCurveKey", rKey)
bufferComponent("ColorSequence", cseq)
bufferComponent("NumberSequence", nseq)
bufferComponent("vector", v)
```
