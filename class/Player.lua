local love = love
local lg = love.graphics

local class = require "lib.class"
local Entity = require "class.Entity"
local polarPolygon = require "util.polarPolygon"
local Particle = require "class.Particle"
local randFloat = require "util.randFloat"

local noclipSpeedY = 300

---@class Player: Entity
local Player = class(Entity)

---@param game Game
function Player:init(game)
  Entity.init(self, game)
  self.width = game.segmentAngle * (3 / 4)
  self.height = game.ringHeight * (3 / 4)

  self.polygon = polarPolygon(self.width, game.ringRadius, self.height, 2)

  self.moveSpeed = 1
  self.jumpForce = 300

  self.solid = true

  self.color = { 0.4, 0.7, 0.9 }

  return self
end

function Player:die()
  self.remove = true
  for _ = 1, 30 do
    local x = randFloat(self.x, self.x + self.width)
    local y = randFloat(self.y, self.y + self.height)
    local p = Particle:new():init(
      self.game,
      x, y,
      (x - self:midX()) * 1.5,
      (y - self:midY()) * 1.5,
      randFloat(3, 6),
      randFloat(0.5, 1.5),
      self.color
    )
    self.game:addEntity(p)
  end
end

---@param dt number
function Player:update(dt)
  if love.keyboard.isDown("left") then
    self.dx = -self.moveSpeed
  elseif love.keyboard.isDown("right") then
    self.dx = self.moveSpeed
  else
    self.dx = 0
  end
  if self.noclip then
    if love.keyboard.isDown("up") then
      self.dy = -noclipSpeedY
    elseif love.keyboard.isDown("down") then
      self.dy = noclipSpeedY
    else
      self.dy = 0
    end
  end
  if love.keyboard.isDown("up") and self.onGround then
    self.dy = -self.jumpForce
  end
  Entity.update(self, dt)
end

---@param other Entity
function Player:onCollision(other)
  if other.hurt then
    self:die()
  end
end

function Player:draw()
  lg.setColor(self.color)
  lg.polygon("fill", self.polygon)
end

return Player
