## Getting Started

The `Constants` module in Buffer is used to know the minimum and maximum values of types,
for example signed and unsigned numbers, as well as strings.

!!! note
    This module is used in Buffer to reduce values if they exceed their expected value too much.

The `REQUIRED_BYTES` table allows you to know which type takes how many bytes.
For strings with an undefined length, the number of bytes will depend on their length.

The `BYTES_CODE` table associates each supported data type with a unique 1-byte identifier
(opcode). These codes are written into the buffer before the actual value,
allowing the reader to dynamically determine how to decode the following bytes. (This is only used for `WriteStruct`)

Design Goals:

- Compact representation (1 byte per type identifier)
- Fast lookup during read/write operations
- Extensible for custom or future types

You can also find the module version in the table.
