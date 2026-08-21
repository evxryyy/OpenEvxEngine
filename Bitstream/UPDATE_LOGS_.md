## Version 4.0.1 (08/21/2026) :
- Fixed a bug where in `Debugger` the Configuration table was missing the propertie `.VerifyVersion`
- Now you have to all modules for example :
  ```lua
  local Bitstream = require(Somewhere.Bitstream.init)

  -- you have access to all of these followings modules
  Bitstream.Bitflag
  Bitstream.Constants
  Bitstream.Debugger
  Bitstream.Enumeration
  Bitstream.Resolver
  Bitstream.Types
  Bitstream.Utilities
  Bitstream.Extensions  
  ```
- Added `changeMinimumAutoAllocationSize`
  - In general, when auto-allocation is triggered, the buffer grows by the size of the type being written. This can become inefficient when writing the same type many times in a short period,
    such as writing a `U8` 1000 times per second. `changeMinimumAutoAllocationSize` allows you to define a minimum allocation size.
    If the configured value is larger than the number of bytes required by the type being written, the buffer will allocate that minimum size instead.
    For example, a `U8` requires only 1 byte. If `changeMinimumAutoAllocationSize` is set to a value greater than 1, whenever additional space is needed,
    the buffer will grow by the configured minimum allocation size rather than allocating only 1 byte.
- Added `resetMinimumAutoAllocationSize`
  - Simply reset the configured minimum allocation size to 1
- Added `shrink`
  - Reduces the buffer size to match the amount of data that has actually been written.
      If the buffer is already fully utilized, no reallocation is performed.

## Version 4.0 :
- Buffer v3.3 -> Bitstream
  - This module is the Buffer v4.0 but instead its a complete rework.
