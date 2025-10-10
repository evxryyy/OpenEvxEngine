## Getting Started

All methods for the ASCII module will be here.

----

## Methods

-----

### Strings Convertion

For conversion with strings, methods such as `ConvertASCIIString` and
`ConvertNumsToString` will be used.

#### String to ASCII Numbers

```luau linenums="1"
local ASCII = require(somewhere.ASCII)

local str = "Hello World !"

print(ASCII.ConvertASCIIString(str)) --> ARRAY_OF_NUMBERS
```

This will convert the string into an array of numbers where each number represents a letter.

----

#### ASCII Numbers to String

```luau linenums="1"
local ASCII = require(somewhere.ASCII)

local nums = ASCII.ConvertASCIIString("Hello World !")

print(ASCII.ConvertNumsToString(nums)) --> ORIGINAL_STRING
```

This will return the original string, meaning "Hello World!".

----

### Binary Convertion

For converting numbers to binary, functions such as
`ConvertNumberToBinary` and `ConvertBinaryToNumber` will be used.

----

#### Number to Binary

=== "Number"

    ```luau linenums="1"
    local ASCII = require(somewhere.ASCII)
    
    local num = 10
    local b = ASCII.ConvertNumberToBinary(num)
    
    print(b) --> return a buffer
    ```

=== "Array of numbers"


    ```luau linenums="1"
    local ASCII = require(somewhere.ASCII)

    local nums = {10,5,1}
    local b = ASCII.ConvertNumberToBinary(nums)
    
    print(b) --> return an array of buffer
    ```

----


#### Binary to Number

=== "Buffer"

    ```luau linenums="1"
    local ASCII = require(somewhere.ASCII)

    local nums = 10
    local b = ASCII.ConvertNumberToBinary(nums)
    
    local backToNumbers = ASCII.ConvertBinaryToNumber(b)
    print(backToNumbers) --> will print the number back so 10
    ```

=== "Array of buffer"


    ```luau linenums="1"
    local ASCII = require(somewhere.ASCII)

    local nums = {10,5,1}
    local b = ASCII.ConvertNumberToBinary(nums)
    
    local backToNumbers = ASCII.ConvertBinaryToNumber(b)
    print(backToNumbers) --> will print the number back so {10,5,1}
    ```

=== "Array of Buffer 'Merge Option'"

    ```luau linenums="1"
    local ASCII = require(somewhere.ASCII)

    local nums = {10,5,1}
    local b = ASCII.ConvertNumberToBinary(nums)
    
    local backToNumbers = ASCII.ConvertBinaryToNumber(b,"Merge")
    print(backToNumbers) --> will print the number 171 cause all buffer (in order) will be merged
    ```
    
    !!! warning
        Option are optional but for 'Single' this will simply return a table of all numbers