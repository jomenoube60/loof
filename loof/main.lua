loof = require('game')
objects = require('objects')
cfg = require('config')

joysticks = objects.object:new()

function love.load()
    game = loof.Game:new()
end

persisting = 0
function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.joystickadded(joystick)
    p1joystick = joystick
    joysticks:insert(p1joystick)
end

function love.keypressed(key)
  if game.active_keymanager then
      game.active_keymanager:keypressed(key)
  end
  game:key_press(key)
end

--[[
function love.mousepressed(x, y)
    print("mouse",x,y)
    game:mousepressed(x, y)
end
]]

function love.touchpressed(id, x, y, dx, dy, pressure)
    game:mousepressed(x, y)
end

function love.keyreleased(key)
  if game.active_keymanager then
    game.active_keymanager:keyreleased(key)
    end
end
