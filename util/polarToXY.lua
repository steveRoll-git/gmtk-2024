---Converts polar coordinates to cartesian coordinates.
---@param angle number
---@param distance number
---@return number x
---@return number y
return function(angle, distance)
  return math.cos(angle) * distance, math.sin(angle) * distance
end
