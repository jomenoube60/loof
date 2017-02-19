objects = require('objects')
cfg = require('config')
ai = require('ai')

require('gameboard')

function dprint(txt)
    if cfg.DEBUG then
        print(txt)
    end
end

Game = objects.object:clone( {max_speed = 20000} )

function Game:new()
    local self = objects.object.clone(self)
    love.physics.setMeter(cfg.DISTANCE) --the height of a meter our worlds
    self.board = Board:new()
    self.score = {0, 0}
    return self
end

function Game:draw()
    self.board:draw()
    local y_offset = 0
    local lines = 10
    -- team 1 score
    for i=1,self.score[2] do
        y_offset = math.floor((i-1)/lines) 
        love.graphics.setColor( 50, 50, 50)
        love.graphics.rectangle('fill', 15*i-(y_offset*15*lines)+2, 35*y_offset+15+2, 10, 30)
        love.graphics.setColor( unpack(cfg.colors[1]) )
        love.graphics.rectangle('fill', 15*i - (y_offset*15*lines), 35*y_offset + 15, 10, 30)
    end
    -- team 2 score
    for i=1,self.score[1] do
        y_offset = math.floor((i-1)/lines) 
        love.graphics.setColor( 50, 50, 50)
        love.graphics.rectangle('fill', self.board.background.width - 15*i - 13 + (15*y_offset*lines), 35*y_offset+17, 10, 30)
        love.graphics.setColor( unpack(cfg.colors[2]) )
        love.graphics.rectangle('fill', self.board.background.width - 15*i - 15 + (15*y_offset*lines),  35*y_offset+15, 10, 30)
    end
end

function Game:update(dt)
    self.board:update(dt)
    ai.step(dt)
    for i, g in ipairs(self.board.opponents) do
        ai.manage(g)
    end
    local dude = self.board.guy
    -- ui keys
    if love.keyboard.isDown('escape') then
        love.event.quit()
        return
    end
    -- special keys
    if love.keyboard.isDown("space") then
        dude:boost()
        return
    end

    -- direction keys, special handling
    local sx, sy = dude.body:getLinearVelocity()
    local impulse = function(d, x, y)
        if d < 0 then
            dude:push(10*x, 10*y)
        else
            dude:push(x, y)
        end
    end

    local power = cfg.POWER
    if math.abs(sx)+math.abs(sy) < self.max_speed then
        --here we are going to create some keyboard events
        local num_directions = 0
        local direction_keys = {
            left   = function() impulse(-sx, -power, 0) end,
            right  = function() impulse(sx, power, 0) end,
            up     = function() impulse(-sy, 0, -power) end,
            down   = function() impulse(sy, 0, power) end,
        }
        local pressed = {} -- store pressed keys to avoid race conditions
        for x in pairs(direction_keys) do
            if love.keyboard.isDown(x) then
                num_directions = num_directions + 1
                table.insert(pressed, x)
            end
        end
        power = power / num_directions -- power is relative to the number of directions
        for i, x in ipairs(pressed) do
            direction_keys[x]()
        end
    end 
end

return {
    Game = Game
}
