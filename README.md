# OpenEvxEngine 

## Latest News

12/05/26
- The project overhaul should be release within 2 to 3 weeks and `Buffer v4.0` and `roblox-ts` version will also be released at the same time

08/05/26 : 
- More features/changes will be added for the `Buffer` Update:
    - `__call` will let you decide an `Action` to perform for example : 
      --- 
      ```luau
  	  buffer({
        Action = "Read", -- List of available option : "Serialize" , "Deserialize", "Write", "Clear"
        ActionParams, -- Will depend on what option you will use "wait for the update to see full details"
      })
      ```
      To continue if you dont want to use it that way a function named `BuildAction` will be here doing the same thing.
  - Fixings type-checking bugs & more [Almost done]
  - Current `Signals` will no longer fire olders values (i.e. first argument on the actual callback for each signals) [Done]
  - `ClearBuffer` and `ClearInstance` will fire `OnOffsetChanged` signal. [Done]

07/05/26 :
- After the release of the `roblox-ts` version, this repository will be renamed to `RbxEnv`.

05/05/26 :
- Working on `Buffer v3.3` here the following details on the upcoming features/changes : 
  - Serializing `Struct` will be possible. [Almost done]
  - Removing char limit for `WriteStruct` on keys and for string values.
  - CFrame will be more compressed (same method name exepct the original one will be called `WriteDefaultCFrame`) and CFrame will be a complex-type now.
  - I'm rewriting readers correctly i need to avoid `DRY` too much. [Done]
  - `Roblox-ts` version will contain an `enum` called `BufferEnum`. [Done]
  - Two utils function will be public : `Utils.ReadValue` (i.e. ReadAny) this function is not on Buffer itself cause it read the byte-code of the given value and `Buffer.WriteAny` does not write the byte-code. [Done]
      i will try still to implement `Buffer.ReadAny` but `Buffer.WriteAny` will write 1 more byte so i will see about that..
      The other function that will be public is `Utils.isValidBool8Table` for people who want to control anything as they want.
    
---

Changes and new features gonna take some time i'm kinda busy right now so sorry about that :3

## Releases

- [Latest release](https://github.com/evxryyy/OpenEvxEngine/releases/latest)
- [All releases](https://github.com/evxryyy/OpenEvxEngine/releases)

## Engine Documentation
  - [Docs](https://evxryyy.github.io/OpenEvxEngine)

## Engine API
  - Buffer (A powerful library to write, serialize/deserialize,read data with the "buffer" type)
  - UserInput (A input handling system for keyboard,gamepad, and mouse input with dynamic switching)
  - ASCII (Binary and ASCII Conversion Utilities)
  - Nexus (Networking library)
  - Socket (Buffer-Networking library)
  - Task (Old garbage collection/cleanup utility module)
  - Collect (Improved garbage collection/cleanup utility module)
  - Enum (System for creating and managing enums)
  - Option (Implements the Option type pattern)

## Description

### About This Engine

This project is not a plug-and-play framework or a collection of prebuilt gameplay mechanics.
Instead, it is designed as a low-level toolkit, providing developers with the fundamental building blocks required to build their own systems with maximum control and efficiency.

Whereas many Roblox libraries aim to be high-level (ready-to-use, quick setup, lots of abstraction), this engine takes the opposite approach:

It provides core primitives such as Buffer, Enum, Task, Option, UserInput, and more.

Each module is designed to be minimal, explicit, and predictable, with a focus on safety and clarity rather than convenience.

By keeping the design low-level, developers are free to compose these tools however they need, without being locked into one rigid architecture.

###  Why Low-Level?

High-level abstractions can be useful for prototyping, but they often come with hidden complexity, performance overhead, or limited flexibility. In large-scale systems, this can lead to:

Difficulty debugging or extending functionality.

Unexpected behavior caused by hidden listeners or implicit state.

Memory leaks and race conditions due to weak cleanup guarantees.

This engine avoids those pitfalls by focusing on synchronization, type-safety, and memory safety. Each component behaves in a clear, deterministic way, so you always know what’s happening under the hood.

### Who Is This For?

This library is aimed at developers who:

Want complete control over how their systems are structured.

Prefer to work with primitives rather than black-box frameworks.

Care about predictable performance and robust event handling.

Are building systems like networking layers, state machines, task managers, or custom pipelines.

If you are looking for a ready-to-use framework where you just drop in code and everything works automatically, this library is not for you. If you want a solid foundation to build your own framework on top of, this library is for you.
