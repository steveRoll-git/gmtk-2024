local class = require "lib.class"

local tiny = 0.0001

---@class Entity: Base
---@field game Game The game that this entity belongs to.
---@field x number The angle position of the entity, in radians. Equivalent to X in cartesian coordinates.
---@field y number The "depth" position of the entity, in logarithmic pixels. Equivalent to Y in cartesian coordinates.
---@field width number The size of the entity along the X axis.
---@field height number The size of the entity along the Y axis.
---@field dx number The velocity along the X axis.
---@field dy number The velocity along the Y axis.
---@field onGround boolean Whether the entity is currently standing on ground.
---@field noclip boolean Whether gravity and collision are ignored.
local Entity = class()

---@param game Game
---@return Entity
function Entity:init(game)
  self.game = game
  self.dx = 0
  self.dy = 0
  return self
end

---@param dt number
function Entity:update(dt)
  if not self.noclip then
    self.dy = self.dy + self.game.gravity * dt
  end

  self.x = (self.x + self.dx * dt) % (math.pi * 2)

  if not self.noclip then
    if self.dx > 0 then
      if self.game:isSolid(self.x + self.width, self.y + tiny) or self.game:isSolid(self.x + self.width, self.y + self.height - tiny) then
        local edgeX = math.floor((self.x + self.width) / self.game.segmentAngle) * self.game.segmentAngle
        self.x = edgeX - self.width
        self.dx = 0
      end
    elseif self.dx < 0 then
      if self.game:isSolid(self.x, self.y + tiny) or self.game:isSolid(self.x, self.y + self.height - tiny) then
        self.x = math.ceil(self.x / self.game.segmentAngle) * self.game.segmentAngle
        self.dx = 0
      end
    end
  end

  self.y = self.y + self.dy * dt
  self.onGround = false

  if not self.noclip then
    if self.dy > 0 then
      if self.game:isSolid(self.x + tiny, self.y + self.height) or self.game:isSolid(self.x + self.width - tiny, self.y + self.height) then
        local edgeY = math.floor((self.y + self.height) / self.game.ringHeight) * self.game.ringHeight
        self.y = edgeY - self.height
        self.dy = 0
        self.onGround = true
      end
    elseif self.dy < 0 then
      if self.game:isSolid(self.x + tiny, self.y) or self.game:isSolid(self.x + self.width - tiny, self.y) then
        self.y = math.ceil(self.y / self.game.ringHeight) * self.game.ringHeight
        self.dy = 0
      end
    end
  end
end

function Entity:draw()
end

return Entity
