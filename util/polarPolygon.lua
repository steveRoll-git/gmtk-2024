local polarToXY = require "util.polarToXY"

---Generates a quad in polar coordinates
---@param angle number
---@param radius number
---@param height number
---@param segments number
---@return number[]
return function(angle, radius, height, segments)
  local totalElements = (segments + 1) * 4
  local polygon = {}
  for i = 0, segments do
    local a = i / segments * angle
    local xTop, yTop = polarToXY(a, radius)
    local xBottom, yBottom = polarToXY(a, radius - height)
    polygon[i * 2 + 1], polygon[i * 2 + 2] = xTop, yTop
    polygon[totalElements - (i * 2) - 1], polygon[totalElements - (i * 2)] = xBottom, yBottom
  end
  return polygon
end
