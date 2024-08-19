local love = love
local lg = love.graphics

local class = require "lib.class"
local Entity = require "class.Entity"

---@class Checkpoint: Entity
local Checkpoint = class(Entity)

---@param game Game
function Checkpoint:init(game, x, y)
  Entity.init(self, game)

  self.x = x
  self.y = y
  self.width = self.game.segmentAngle
  self.height = self.game.ringHeight

  self.collideable = true

  return self
end

return Checkpoint
