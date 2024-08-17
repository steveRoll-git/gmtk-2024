io.stdout:setvbuf("no")

love.graphics.setDefaultFilter("nearest", "nearest")

local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
  require("lldebugger").start()

  function love.errorhandler(msg)
    error(msg, 2)
  end
end

local manager = require "lib.roomy".new()

local game = require "state.game"

love.graphics.setBackgroundColor(1, 1, 1)

function love.load(arg)
  manager:hook()
  manager:enter(game)
end

function love.quit()
  if IS_DEBUG then
    game:saveMap()
  end
end
