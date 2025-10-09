## Collect

## What next

## Logs

Version : 1.2
- Fixed a bug where RBXScriptConnection causing error on calling :RemoveAll and :Remove
- Now on every :Remove function then `clean` argument is optional and is true by default. 

Version : 1.1
- Added :Merge()
  ```lua
  -- Merges another CollectComponent into this one, taking ownership of all its tracked items
  -- The source component is destroyed after merging
  -- @param self: Target CollectComponent that will receive the items
  -- @param CollectComponent: Source CollectComponent to merge from (will be destroyed)

  local test = Collect.new()
  local hello = Collect.new()
  
  --Add a instance in the collect "hello"
  hello:Add(workspace.Baseplate)
  
  --Merge all task(s) in "hello" and clean "hello" component without cleaning task(s).
  test:Merge(hello)

  --Alias
  Component.merge = Component.Merge
  ```


Version : 1.0
- Released the module.
