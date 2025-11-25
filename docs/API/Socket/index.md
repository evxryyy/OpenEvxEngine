## Getting Started

Socket, Provides a unified, type-safe API for client-server communication in Roblox

Features 
- buffer serialization for efficient network usage

!!! Note
    This module uses the `Buffer` module, which means that with each update of it, `Socket` will be re-uploaded.

----

## Version

### [Socket V1.3](https://github.com/evxryyy/OpenEvxEngine/releases/tag/buffer-network)

----

## Important

### Using non-defined string length

For string data type that require more than 64 byte please use something like this :

```luau linenums="1"
local schema : Socket.BufferSchema = {
    Value = {
        Type = "String",
        Length = 1024
    } -- This will require 1024 bytes
}
```

----

### Padding characters if len is not respected

When you use a `String` type regardless of size (A custom or String[Len]), if the size is not respected, for example
if you use a `String8` and the string is less than 8 characters, special characters

```luau linenums="1"
string.char(31)
```

will be placed. Please note that these characters are automatically removed during buffer deserialization 
so your data will NOT be impacted unless you put this character in the string itself.

----
