# Bitstream (WIP)

This module provides a set of functions for reading and writing binary data.
It provides a convenient way to serialize and deserialize data.

Features:
- Supports all types of data
- Supports auto allocation
- Supports custom types

Todo :
- Begin implementing the deserialization system.
- Begin development of `Bitstream.ts`, the `roblox-ts` implementation of Bitstream.

Idea : 
1. Add a way to really write instance in a buffer and not inside a table.
2. Add `writeInt` and `writeFloat` similar to `writeUInt`.
3. Add `SerializeSchemaless` and `DeserializeSchemaless` to serialize and deserialize data dynamically without requiring a schema.
