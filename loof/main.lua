--debugWorldDraw = require("debugWorldDraw")
loof = require('game')
objects = require('objects')
cfg = require('config')


function love.load()
    game = loof.Game:clone():init()
end

persisting = 0
function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
    if cfg.DEBUG and debugWorldDraw ~= nil then
        debugWorldDraw(game.board.world,0,0,game.board.size, game.board.size)
    end
end
