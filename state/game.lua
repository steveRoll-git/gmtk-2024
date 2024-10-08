local love = love
local lg = love.graphics

local Player = require "class.Player"
local ffi = require "ffi"
local polarPolygon = require "util.polarPolygon"
local Crawler = require "class.Crawler"
local Checkpoint = require "class.Checkpoint"

---@class Timer
---@field time number
---@field action function

local tilesFilename = "map/tiles"
local entitiesFilename = "map/entities.lua"

local mapEntityColors = {
  playerStart = { 0.4, 0.7, 0.9, 0.4 },
  checkpoint = { 0.2, 0.7, 0.2, 0.4 },
  crawler = { 0.8, 0.4, 0.4, 0.4 },
}

local entityTypes = { "playerStart", "checkpoint", "crawler" }

---Returns whether two entities are colliding.
---@param e1 Entity
---@param e2 Entity
local function entitiesAABB(e1, e2)
  local x1, y1, w1, h1 = e1.x, e1.y, e1.width, e1.height
  local x2, y2, w2, h2 = e2.x, e2.y, e2.width, e2.height
  if x1 + w1 >= math.pi * 2 then
    x1 = x1 - math.pi * 2
  end
  if x2 + w2 >= math.pi * 2 then
    x2 = x2 - math.pi * 2
  end
  return
      x1 < x2 + w2 and
      x2 < x1 + w1 and
      y1 < y2 + h2 and
      y2 < y1 + h1
end

local function gamePath(path)
  return love.filesystem.getSource() .. "/" .. path
end

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

  self.tilePolygon = polarPolygon(self.segmentAngle, self.ringRadius, self.ringHeight, 3)

  self.mapHeight = 50
  self.map = ffi.new("uint8_t[?]", self.segmentsInRing * self.mapHeight)

  local mapData = love.filesystem.read(tilesFilename)
  if mapData then
    ffi.copy(self.map, mapData, ffi.sizeof(self.map) --[[@as integer]])
  end

  self.mapEntities = {}
  if love.filesystem.getInfo(entitiesFilename) then
    self.mapEntities = love.filesystem.load(entitiesFilename)()
  end

  self.gravity = 500

  self.player = Player:new():init(self)

  ---@type Entity[]
  self.entities = { self.player }
  for _, e in ipairs(self.mapEntities) do
    self:processMapEntity(e)
  end

  self.checkpointPos = { x = self.player.x, y = self.player.y }

  self.camera = { x = 0, y = 0 }
  self.followPlayer = true

  self.focalPoint = { x = lg.getWidth() / 2, y = lg.getHeight() / 2 + self.ringRadius }

  self.cursor = { x = 0, y = 0 }

  self.visibleRowsAbove = 6
  self.visibleRowsBelow = 24

  ---@type Timer[]
  self.timers = {}

  if IS_DEBUG then
    self.editorEntityType = entityTypes[1]
  end

  self.debug = IS_DEBUG
end

---Returns whether the given position is inside of the map.
---@param x number
---@param y number
---@return boolean
function game:inMap(x, y)
  return x >= 0 and x < self.segmentsInRing and y >= 0 and y < self.mapHeight
end

---Returns the tile at the given map position
---@param x number
---@param y number
---@return number
function game:mapGet(x, y)
  if not self:inMap(x, y) then
    return 0
  end
  return self.map[y * self.segmentsInRing + x]
end

---Returns the tile at the given map position
---@param x number
---@param y number
---@param v number
function game:mapSet(x, y, v)
  self.map[y * self.segmentsInRing + x] = v
end

function game:saveMap()
  if love.filesystem.isFused() then
    return
  end

  do
    local file, err = io.open(gamePath(tilesFilename), "w+b")
    if not file then
      error(err)
    end
    file:write(ffi.string(self.map, ffi.sizeof(self.map)))
    file:close()
  end

  do
    local file, err = io.open(gamePath(entitiesFilename), "w+")
    if not file then
      error(err)
    end

    table.sort(self.mapEntities, function(a, b)
      if a.y == b.y then
        return a.x < b.x
      end
      return a.y < b.y
    end)

    file:write("return {\n")
    for _, e in ipairs(self.mapEntities) do
      file:write("  {\n")
      local keys = {}
      for k, v in pairs(e) do
        table.insert(keys, k)
      end
      table.sort(keys)
      for _, k in ipairs(keys) do
        local v = e[k]
        file:write(("    %s = %s,\n"):format(k, type(v) == "string" and ("%q"):format(v) or v))
      end
      file:write("  },\n")
    end
    file:write("}\n")
    file:close()
  end
end

function game:processMapEntity(e)
  local worldX, worldY = e.x * self.segmentAngle, e.y * self.ringHeight

  if e.type == "playerStart" then
    self.player.x = worldX
    self.player.y = worldY
    return
  end

  local new
  if e.type == "crawler" then
    new = Crawler:new():init(self)
    new.x = worldX
    new.y = worldY
  elseif e.type == "checkpoint" then
    new = Checkpoint:new():init(self, worldX, worldY)
  else
    error("unknown entity type: " .. e.type)
  end
  new.id = tostring(e)
  self:addEntity(new)
end

---@param e Entity
function game:addEntity(e)
  table.insert(self.entities, e)
end

---Returns whether the given position is inside of a solid tile.
---@param x number
---@param y number
---@return boolean
function game:isSolid(x, y)
  x = x % (math.pi * 2)
  return self:mapGet(math.floor(x / self.segmentAngle), math.floor(y / self.ringHeight)) > 0
end

---@param time number
---@param action function
function game:after(time, action)
  table.insert(self.timers, {
    action = action,
    time = time
  })
end

function game:respawnPlayer()
  self.player = Player:new():init(self)
  self.player.x = self.checkpointPos.x
  self.player.y = self.checkpointPos.y
  self:addEntity(self.player)
end

---@param dt number
function game:update(dt)
  local toRemove = {}

  for i, e in ipairs(self.entities) do
    e:update(dt)
    if e.onCollision then
      for _, e2 in ipairs(self.entities) do
        if e ~= e2 and e2.collideable and entitiesAABB(e, e2) then
          e:onCollision(e2)
        end
      end
    end
    if e.remove then
      table.insert(toRemove, i)
    end
  end

  for i = #toRemove, 1, -1 do
    local index = toRemove[i]
    self.entities[index], self.entities[#self.entities] = self.entities[#self.entities], nil
  end

  if self.followPlayer then
    self.camera.x = self.player:midX()
    self.camera.y = self.player:midY()
  end

  for i = #self.timers, 1, -1 do
    local t = self.timers[i]
    t.time = t.time - dt
    if t.time <= 0 then
      t.action()
      table.remove(self.timers, i)
    end
  end

  if self.debug then
    local mx = love.mouse.getX() - self.focalPoint.x
    local my = love.mouse.getY() - self.focalPoint.y

    local angle = math.atan2(my, mx) + math.pi / 2 + self.camera.x
    local distance = math.sqrt(mx ^ 2 + my ^ 2)

    self.cursor.x = math.floor((angle % (math.pi * 2)) / self.segmentAngle)
    self.cursor.y = math.floor(
      math.log(distance / self.ringRadius) / math.log(self.ringScaleFactor) + self.camera.y / self.ringHeight)

    if love.mouse.isDown(1, 2) and self:inMap(self.cursor.x, self.cursor.y) then
      self:mapSet(self.cursor.x, self.cursor.y, love.mouse.isDown(1) and 1 or 0)
    end
  end
end

function game:keypressed(key)
  if key == "f1" and IS_DEBUG then
    self.debug = not self.debug
  end
  if self.debug then
    if key == "f" then
      self.followPlayer = true
    elseif key == "n" then
      self.player.noclip = not self.player.noclip
    elseif key == "e" then
      local e = {
        x = self.cursor.x,
        y = self.cursor.y,
        type = self.editorEntityType
      }
      table.insert(self.mapEntities, e)
      self:processMapEntity(e)
    elseif key == "d" then
      for i, e in ipairs(self.mapEntities) do
        if e.x == self.cursor.x and e.y == self.cursor.y then
          table.remove(self.mapEntities, i)
          break
        end
      end
    elseif key >= "1" and key <= "9" then
      if tonumber(key) <= #entityTypes then
        self.editorEntityType = entityTypes[tonumber(key)]
      end
    end
  end
end

function game:mousemoved(x, y, dx, dy)
  if self.debug and love.mouse.isDown(3) then
    self.followPlayer = false
    self.camera.x = (self.camera.x - dx / 100) % (math.pi * 2)
    self.camera.y = self.camera.y - dy
  end
end

---@param x number
---@param y number
function game:transformPolar(x, y)
  lg.scale(self.ringScaleFactor ^ (y / self.ringHeight))
  lg.rotate(x)
end

function game:draw()
  lg.push()
  lg.translate(self.focalPoint.x, self.focalPoint.y)

  lg.rotate(-self.camera.x - math.pi / 2)
  for i = 0, self.segmentsInRing - 1 do
    lg.push()
    lg.rotate(i / self.segmentsInRing * math.pi * 2)
    lg.setColor(0, 0, 0, 0.07)
    lg.setLineWidth(1)
    lg.line(0, 0, self.ringRadius * 4, 0)
    lg.pop()
  end
  lg.scale(self.ringScaleFactor ^ (-self.camera.y / self.ringHeight))

  local cameraTopTile = math.floor(self.camera.y / self.ringHeight)
  for y = cameraTopTile - self.visibleRowsAbove, cameraTopTile + self.visibleRowsBelow - 1 do
    lg.push()

    lg.scale(self.ringScaleFactor ^ y)

    lg.setColor(0, 0, 0, 0.07)
    lg.setLineWidth(1)
    lg.circle("line", 0, 0, self.ringRadius)

    for x = 0, self.segmentsInRing - 1 do
      if self:mapGet(x, y) == 1 then
        lg.push()
        local angle = x * self.segmentAngle
        lg.rotate(angle)
        lg.setColor(0, 0, 0)
        lg.polygon("fill", self.tilePolygon)
        lg.pop()
      end
    end

    lg.pop()
  end

  if self.debug then
    lg.push()
    self:transformPolar(self.cursor.x * self.segmentAngle, self.cursor.y * self.ringHeight)
    lg.setColor(0.3, 0.6, 0.3, 0.5)
    lg.polygon("fill", self.tilePolygon)
    lg.setColor(0.3, 0.6, 0.3, 0.7)
    lg.setLineWidth(2)
    lg.polygon("line", self.tilePolygon)
    lg.pop()

    for _, e in ipairs(self.mapEntities) do
      lg.push()
      self:transformPolar(e.x * self.segmentAngle, e.y * self.ringHeight)
      lg.setColor(mapEntityColors[e.type])
      lg.polygon("fill", self.tilePolygon)
      lg.pop()
    end
  end

  for _, e in ipairs(self.entities) do
    lg.push()
    self:transformPolar(e.x, e.y)
    e:draw()
    lg.pop()
  end

  lg.pop()

  if self.debug then
    local text = ([[Entity: %s
%d]]):format(self.editorEntityType, #self.entities)
    local width, lines = lg.getFont():getWrap(text, 300)
    lg.setColor(0, 0, 0, 0.6)
    lg.rectangle("fill", 0, 0, width, #lines * lg.getFont():getHeight() * 1.2)
    lg.setColor(1, 1, 1)
    lg.print(text)
  end
end

return game
