loof = require('game')
objects = require('objects')
cfg = require('config')
require('input')

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

