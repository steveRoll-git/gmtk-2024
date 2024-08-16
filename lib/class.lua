---@class Base
---@field _mt table
local base = {}

---Returns a new instance of the given `class`.
---@generic T
---@param class T
---@return T
function base.new(class)
  ---@diagnostic disable-next-line: undefined-field
  return setmetatable({}, class._mt)
end

---Creates a new class.
---@param parent? Base A parent class to inherit
return function(parent)
  local class = {}
  if parent then
    setmetatable(class, parent._mt)
  end
  class._mt = { __index = class }
  class.new = base.new
  return class
end
