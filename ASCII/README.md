## ASCII

## What next

## Logs

Version : 1.1
- ASCII Reworked
- In the older version each bit cost 1 byte now if you convert a number to a binary buffer it will not take more 
  ```lua
  --Older version
  local b = ASCII.NumberToBinary(10)
  -- buffer size will be 4

  --New version
  local b = ASCII.ConvertNumberToBinary(10)
  -- buffer size will be 2
  ```
- Now to convert a binary buffer to a number you will need to specify the ConvertType
  ```lua
  --Older version
  local num = ASCII.BinaryToNumber(ARRAY_OF_BUFFER)
  -- this will return the merged number between all buffer

  --New version
  local mergedNum = ASCII.ConvertBinaryToNumber(ARRAY_OF_BUFFER,"Merged")
  -- return the merged number between all buffer

  local eachNum = ASCII.ConvertBinaryToNumber(ARRAY_OF_BUFFER,"Single")
  -- return {
    [1] = number
    etc...
  }
  ```
- String convertion are still the same but method name is different
  ```lua
      .ConvertASCIIString -> convert the string into ASCII Number or Array
      .ConvertNumsToString -> convert ASCII number or array to a string
  ```

Version : 1.0
- Changed comments
- Re-uploaded the module.
