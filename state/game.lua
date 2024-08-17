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

  self.player = Player:new():init(self)

  ---@type Entity[]
  self.entities = { self.player }

  self.camera = { x = 0, y = 0 }

  self.focalPoint = { x = lg.getWidth() / 2, y = lg.getHeight() / 2 + self.ringRadius }

  self.cursor = { x = 0, y = 0 }
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

---@param dt number
function game:update(dt)
  for _, e in ipairs(self.entities) do
    e:update(dt)
  end

  self.camera.x = self.player.x + self.player.width / 2
  self.camera.y = self.player.y + self.player.height / 2

  local mx = love.mouse.getX() - self.focalPoint.x
  local my = love.mouse.getY() - self.focalPoint.y

  local angle = math.atan2(my, mx) + math.pi / 2 + self.camera.x
  local distance = math.sqrt(mx ^ 2 + my ^ 2)

  self.cursor.x = math.floor((angle % (math.pi * 2)) / self.segmentAngle) + 1
  self.cursor.y = math.floor(
    math.log(distance / self.ringRadius) / math.log(self.ringScaleFactor) + self.camera.y / self.ringHeight) + 1
end

function game:draw()
  lg.push()
  lg.translate(self.focalPoint.x, self.focalPoint.y)

  lg.rotate(-self.camera.x - math.pi / 2)
  for i = 0, self.segmentsInRing - 1 do
    lg.push()
    lg.rotate(i / self.segmentsInRing * math.pi * 2)
    lg.setColor(0, 0, 0, 0.07)
    lg.line(0, 0, self.ringRadius * 2, 0)
    lg.pop()
  end
  lg.scale(self.ringScaleFactor ^ (-self.camera.y / self.ringHeight))

  for y, r in ipairs(self.rings) do
    lg.push()

    lg.scale(self.ringScaleFactor ^ (y - 1))

    lg.setColor(0, 0, 0, 0.07)
    lg.setLineWidth(1)
    lg.circle("line", 0, 0, self.ringRadius)

    for x, v in ipairs(r) do
      local hover = (x == self.cursor.x and y == self.cursor.y)
      if v or hover then
        lg.push()
        local angle = (x - 1) * self.segmentAngle
        lg.rotate(angle)
        if hover then
          lg.setColor(0.6, 0.3, 0)
        else
          lg.setColor(0, 0, 0)
        end
        lg.polygon("fill", self.tilePolygon)
        lg.pop()
      end
    end

    lg.pop()
  end

  for _, e in ipairs(self.entities) do
    lg.push()
    lg.scale(self.ringScaleFactor ^ (e.y / self.ringHeight))
    lg.rotate(e.x)
    e:draw()
    lg.pop()
  end

  lg.pop()
end

return game
