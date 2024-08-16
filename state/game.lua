local love = love
local lg = love.graphics

local polarToXY = require "util.polarToXY"
local Player = require "class.Player"

---@class Game
local game = {}

function game:enter()
  -- How many segments are in a ring.
  self.segmentsInRing = 32
  -- The angular size of a single segment.
  self.segmentAngle = math.pi * 2 / self.segmentsInRing
  -- The radius of a ring in pixels.
  self.ringRadius = 200
  -- The height of a ring in pixels.
  self.ringHeight = 36
  -- By how much each ring should be scaled to appear inside of the ring above it.
  self.ringScaleFactor = (self.ringRadius - self.ringHeight) / self.ringRadius

  do
    self.tilePolygon = {}
    local tileSegments = 2
    local totalElements = (tileSegments + 1) * 4
    for i = 0, tileSegments do
      local angle = i / tileSegments * self.segmentAngle
      local xTop, yTop = polarToXY(angle, self.ringRadius)
      local xBottom, yBottom = polarToXY(angle, self.ringRadius - self.ringHeight)
      self.tilePolygon[i * 2 + 1], self.tilePolygon[i * 2 + 2] = xTop, yTop
      self.tilePolygon[totalElements - (i * 2) - 1], self.tilePolygon[totalElements - (i * 2)] = xBottom, yBottom
    end
  end

  ---@type boolean[][]
  self.rings = {}

  for _ = 1, 20 do
    local newRing = {}
    for _ = 1, self.segmentsInRing do
      table.insert(newRing, love.math.random() <= 0.5)
    end
    table.insert(self.rings, newRing)
  end

  self.gravity = 500

  ---@type Entity[]
  self.entities = { Player:new():init(self) }
end

---Returns whether the given position is inside of a solid tile.
---@param x number
---@param y number
---@return boolean
function game:isSolid(x, y)
  x = x % (math.pi * 2)
  local ring = self.rings[math.floor(y / self.ringHeight) + 1]
  if not ring then
    return false
  end
  return ring[math.floor(x / self.segmentAngle) + 1]
end

---@param ring boolean[]
---@param depth number
function game:drawRing(ring, depth)
  lg.push()

  lg.scale(self.ringScaleFactor ^ depth)

  lg.setColor(1, 0, 0, 0.1)
  lg.setLineWidth(1)
  lg.circle("line", 0, 0, self.ringRadius)

  for i, v in ipairs(ring) do
    lg.setColor(0, 0, 0)
    if v then
      lg.push()
      local angle = (i - 1) * self.segmentAngle
      lg.rotate(angle)
      lg.polygon("fill", self.tilePolygon)
      -- lg.setColor(1, 1, 1)
      -- lg.print(i, x2, y2)
      lg.pop()
    end
  end

  lg.pop()
end

---@param dt number
function game:update(dt)
  for _, e in ipairs(self.entities) do
    e:update(dt)
  end
end

function game:draw()
  lg.translate(lg.getWidth() / 2, lg.getHeight() / 2)
  for i, r in ipairs(self.rings) do
    self:drawRing(r, i - 1)
  end
  for _, e in ipairs(self.entities) do
    lg.push()
    lg.scale(self.ringScaleFactor ^ (e.y / self.ringHeight))
    lg.rotate(e.x)
    e:draw()
    lg.pop()
  end
end

return game
