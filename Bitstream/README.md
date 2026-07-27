# Bitstream (WIP)

This module provides a set of functions for reading and writing binary data.
It provides a convenient way to serialize and deserialize data.

Features:
- Supports all types of data
- Supports auto allocation
- Supports custom types

Todo :
- Begin implementing the deserialization system.
- Complete `writeAny` and `readAny` with proper flag support.
- Add `f8` and `f24` types directly from the C implementation.
- Begin development of `Bitstream.ts`, the `roblox-ts` implementation of Bitstream.

Idea : 
1. Add a way to really write instance in a buffer and not inside a table. (using `SerializationService`)
2. Add `writeInt` similar to `writeUInt`.
