local love = love
local lg = love.graphics

local class = require "lib.class"
local Entity = require "class.Entity"
local polarPolygon = require "util.polarPolygon"

---@class Crawler: Entity
local Crawler = class(Entity)

---@param game Game
function Crawler:init(game)
  Entity.init(self, game)
  self.width = game.segmentAngle * (3 / 4)
  self.height = game.ringHeight * (3 / 4)

  self.polygon = polarPolygon(self.width, game.ringRadius, self.height, 2)

  self.moveSpeed = 0.4
  self.dx = self.moveSpeed
  self.dy = 0

  self.collideable = true
  self.hurt = true

  return self
end

function Crawler:update(dt)
  Entity.update(self, dt)
  if self.touchingLeft or (self.dx < 0 and not self.game:isSolid(self.x, self.y + self.height + 0.1)) then
    self.dx = self.moveSpeed
  elseif self.touchingRight or (self.dx > 0 and not self.game:isSolid(self.x + self.width, self.y + self.height + 0.1)) then
    self.dx = -self.moveSpeed
  end
end

function Crawler:draw()
  lg.setColor(0.9, 0.3, 0.2)
  lg.polygon("fill", self.polygon)
end

return Crawler
