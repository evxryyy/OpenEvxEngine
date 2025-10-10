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