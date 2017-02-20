objects = require('objects')
cfg = require('config')
ai = require('ai')
ok, see = pcall(function() return require('inspect').inspect end)
if not ok then
    function see(...)
        print(arg)
    end
end

require('gameboard')

function dprint(txt)
    if cfg.DEBUG then
        print(txt)
    end
end

Game = objects.object:clone()

local keymanager = {
    keys_by_name = {},
    keys = {},
    ts = 0,
}
function keymanager:register(key, callable, min_delay)
    local d = {name=key, fn=callable, interval=min_delay}
    self.keys_by_name[key] = d
    table.insert(self.keys, d)
end

function keymanager:is_active(key)
    local k = self.keys_by_name[key]
    return k.ts ~= nil and k.ts + k.interval > self.ts
end

function keymanager:manage(dt)
    self.ts = self.ts + dt
    for i, k in ipairs(self.keys) do
        if love.keyboard.isDown(k.name) then
            if not self:is_active(k.name) then
                if k.interval ~= nil then -- if interval defined, store ts
                    k.ts = self.ts
                end
                k.fn(dt)
            end
        end
    end
end

function Game:new()
    local self = objects.object.new(self)
    love.physics.setMeter(cfg.DISTANCE) --the height of a meter our worlds
    self.board = Board:new()
    self.score = {0, 0}
    -- register keys
    keymanager:register('escape', love.event.quit, 1.0)
    keymanager:register('space', function(dt) self.board.guy:boost(dt) end)
    keymanager:register('r', function(dt)
        self.board = Board:new()
        self.score = {0, 0}
    end, 3.0)
    keymanager:register('left', function(dt)
        self.board.guy:push(-cfg.POWER*dt, 0)
    end)
    keymanager:register('right', function(dt)
        self.board.guy:push(cfg.POWER*dt, 0)
    end)
    keymanager:register('up', function(dt)
        self.board.guy:push(0, -cfg.POWER*dt)
    end)
    keymanager:register('down', function(dt)
        self.board.guy:push(0, cfg.POWER*dt)
    end)
    keymanager:register('p', function(dt)
        self.board:add_opponent()
    end, 1.0)
    keymanager:register('o', function(dt)
        self.board:remove_opponent()
    end, 1.0)
    return self
end

function Game:update(dt)
    self.board:update(dt)
    -- update opponents
    ai.step(dt)
    for i, g in ipairs(self.board.opponents) do
        ai.manage(g, dt)
    end
    -- manage user keys
    keymanager:manage(dt)
end

function Game:draw()
    self.board:draw()
    -- SCORE display
    local y_offset = 0
    local lines = 10
    local w = 10 -- width
    local h = 30 -- height
    local m = 5 -- margin
    local s = 2 -- shadow
    -- team 1 score
    for i=1,self.score[2] do
        y_offset = math.floor((i-1)/lines) 
        love.graphics.setColor( 50, 50, 50)
        love.graphics.rectangle('fill', (w+m)*i-(y_offset*(w+m)*lines)+s, (h+m)*y_offset+w+m+s, w, h)
        love.graphics.setColor( unpack(cfg.colors[1]) )
        love.graphics.rectangle('fill', (w+m)*i - (y_offset*(w+m)*lines), (h+m)*y_offset + (w+m), w, h)
    end
    -- team 2 score
    for i=1,self.score[1] do
        y_offset = math.floor((i-1)/lines) 
        love.graphics.setColor( 50, 50, 50)
        love.graphics.rectangle('fill', self.board.background.width - (w+m)*i - (w+m-s) + ((w+m)*y_offset*lines), (h+m)*y_offset+(w+m+s), w, h)
        love.graphics.setColor( unpack(cfg.colors[2]) )
        love.graphics.rectangle('fill', self.board.background.width - (w+m)*i - (w+m) + ((w+m)*y_offset*lines),  (h+m)*y_offset+(w+m), w, h)
    end
end

return {
    Game = Game
}
