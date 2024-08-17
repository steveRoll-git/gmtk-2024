local random = love.math.random

---@param min number
---@param max number
---@return number
return function(min, max)
  return min + (max - min) * random()
end
