local love = love
local lg = love.graphics

---Converts polar coordiantes to cartesian coordinates.
---@param angle number
---@param distance number
---@return number x
---@return number y
local function polarToXY(angle, distance)
  return math.cos(angle) * distance, math.sin(angle) * distance
end

-- How many segments are in a ring.
local segmentsInRing = 32
-- The angular size of a single segment.
local segmentAngle = math.pi * 2 / segmentsInRing
-- The radius of a ring in pixels.
local ringRadius = 200
-- The width of a ring in pixels.
local ringWidth = 32
-- By how much each ring should be scaled to appear inside of the ring above it.
local ringScaleFactor = (ringRadius - ringWidth) / ringRadius

local tilePolygon = {}
tilePolygon[1], tilePolygon[2] = polarToXY(0, ringRadius)
tilePolygon[3], tilePolygon[4] = polarToXY(0, ringRadius - ringWidth)
tilePolygon[5], tilePolygon[6] = polarToXY(segmentAngle, ringRadius - ringWidth)
tilePolygon[7], tilePolygon[8] = polarToXY(segmentAngle, ringRadius)

local game = {}

function game:enter()
  self.rings = {}

  for _ = 1, 20 do
    local newRing = {}
    for _ = 1, segmentsInRing do
      table.insert(newRing, love.math.random() <= 0.5)
    end
    table.insert(self.rings, newRing)
  end
end

---@param ring boolean[]
---@param depth number
function game:drawRing(ring, depth)
  lg.push()
  lg.translate(lg.getWidth() / 2, lg.getHeight() / 2)

  local scale = ringScaleFactor ^ depth
  lg.scale(scale, scale)

  -- lg.setColor(1, 0, 0, 0.1)
  -- lg.setLineWidth(1)
  -- lg.circle("line", 0, 0, ringRadius)

  for i, v in ipairs(ring) do
    lg.setColor(0, 0, 0)
    if v then
      lg.push()
      local angle = (i - 1) * segmentAngle
      lg.rotate(angle)
      lg.polygon("fill", tilePolygon)
      -- lg.setColor(1, 1, 1)
      -- lg.print(i, x2, y2)
      lg.pop()
    end
  end

  lg.pop()
end

function game:draw()
  for i, r in ipairs(self.rings) do
    self:drawRing(r, i - 1)
  end
end

return game
