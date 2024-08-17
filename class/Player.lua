local love = love
local lg = love.graphics

local class = require "lib.class"
local Entity = require "class.Entity"
local polarPolygon = require "util.polarPolygon"

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

  return self
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

function Player:draw()
  lg.setColor(0.4, 0.7, 0.9)
  lg.polygon("fill", self.polygon)
end

return Player
