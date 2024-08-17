local love = love
local lg = love.graphics

local Player = require "class.Player"
local ffi = require "ffi"
local polarPolygon = require "util.polarPolygon"
local Crawler = require "class.Crawler"

local tilesFilename = "map/tiles"
local entitiesFilename = "map/entities.lua"

local mapEntityColors = {
  playerStart = { 0.4, 0.7, 0.9, 0.4 },
  crawler = { 0.8, 0.4, 0.4, 0.4 }
}

local entityTypes = { "playerStart", "crawler" }

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
    if e.type == "playerStart" then
      self.player.x = e.x * self.segmentAngle
      self.player.y = e.y * self.ringHeight
    else
      self:processMapEntity(e)
    end
  end

  self.camera = { x = 0, y = 0 }
  self.followPlayer = true

  self.focalPoint = { x = lg.getWidth() / 2, y = lg.getHeight() / 2 + self.ringRadius }

  self.cursor = { x = 0, y = 0 }

  self.visibleRowsAbove = 6
  self.visibleRowsBelow = 24

  if IS_DEBUG then
    self.editorEntityType = entityTypes[1]
  end
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
  local new
  if e.type == "crawler" then
    new = Crawler:new():init(self)
    new.x = e.x * self.segmentAngle
    new.y = e.y * self.ringHeight
  else
    error("unknown entity type: " .. e.type)
  end
  new.id = tostring(e)
  table.insert(self.entities, new)
end

---Returns whether the given position is inside of a solid tile.
---@param x number
---@param y number
---@return boolean
function game:isSolid(x, y)
  x = x % (math.pi * 2)
  return self:mapGet(math.floor(x / self.segmentAngle), math.floor(y / self.ringHeight)) > 0
end

---@param dt number
function game:update(dt)
  for _, e in ipairs(self.entities) do
    e:update(dt)
  end

  if self.followPlayer then
    self.camera.x = self.player.x + self.player.width / 2
    self.camera.y = self.player.y + self.player.height / 2
  end

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

function game:keypressed(key)
  if IS_DEBUG then
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
  if IS_DEBUG and love.mouse.isDown(3) then
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

  if IS_DEBUG then
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

  if IS_DEBUG then
    local text = ([[Entity: %s]]):format(self.editorEntityType)
    local width, lines = lg.getFont():getWrap(text, 300)
    lg.setColor(0, 0, 0, 0.6)
    lg.rectangle("fill", 0, 0, width, #lines * lg.getFont():getHeight() * 1.2)
    lg.setColor(1, 1, 1)
    lg.print(text)
  end
end

return game
