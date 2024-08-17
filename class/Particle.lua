local love = love
local lg = love.graphics

local class = require "lib.class"
local Entity = require "class.Entity"

---@class Particle: Entity
local Particle = class(Entity)

---@param game Game
---@param x number
---@param y number
---@param dx number
---@param dy number
---@param radius number
---@param lifetime number
---@param color table
function Particle:init(game, x, y, dx, dy, radius, lifetime, color)
  self.game = game
  self.x = x
  self.y = y
  self.dx = dx
  self.dy = dy
  self.radius = radius
  self.life = 0
  self.lifetime = lifetime
  self.color = color

  return self
end

function Particle:update(dt)
  self.x = self.x + self.dx * dt
  self.y = self.y + self.dy * dt
  self.life = self.life + dt
  if self.life >= self.lifetime then
    self.remove = true
  end
end

function Particle:draw()
  local r, g, b = unpack(self.color)
  lg.setColor(r, g, b, 1 - self.life / self.lifetime)
  lg.circle("fill", self.game.ringRadius, 0, self.radius)
end

return Particle
