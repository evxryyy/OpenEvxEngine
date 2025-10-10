# OpenEvxEngine 

![GitHub Releases](https://img.shields.io/github/downloads/evxryyy/OpenEvxEngine/total)

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
  - ConnectionStore (Store RBXScriptConnection or threads)

## Description

### About This Engine

This project is not a plug-and-play framework or a collection of prebuilt gameplay mechanics.
Instead, it is designed as a low-level toolkit, providing developers with the fundamental building blocks required to build their own systems with maximum control and efficiency.

Whereas many Roblox libraries aim to be high-level (ready-to-use, quick setup, lots of abstraction), this engine takes the opposite approach:

It provides core primitives such as Buffer, Enum, Task, Option, UserInput, SyncSignal, and more.

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
