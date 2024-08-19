---@class Base
---@field _mt table
local base = {}
base._mt = { class = base, __index = base }

---Returns a new instance of the given `class`.
---@generic T
---@param class T
---@return T
function base.new(class)
  ---@diagnostic disable-next-line: undefined-field
  return setmetatable({}, class._mt)
end

---Returns whether this instance is of the given class.
---@param class Base
---@return boolean
function base:is(class)
  local mt = getmetatable(self)
  return mt == class._mt
end

---Creates a new class.
---@param parent? Base A parent class to inherit
return function(parent)
  parent = parent or base
  local class = {}
  setmetatable(class, parent._mt)
  class._mt = { class = class, parent = parent, __index = class }
  return class
end
