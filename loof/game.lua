objects = require('objects')
cfg = require('config')
require('gameboard')
ai = require('ai')
key_funcs = require('key_handlers')
ok, see = pcall(function() return require('inspect').inspect end)
require('menu')

if not ok then
    function see(...)
        print(arg)
    end
end

function dprint(txt)
    if cfg.DEBUG then
        print(txt)
    end
end

Game = objects.object:clone()
function Game:new()
    local self = objects.object.new(self)
    self.board = Board:new()
    love.window.setMode(self.board.background.width, self.board.background.height, {
        fullscreen = true,
        vsync = true,
    })
    love.physics.setMeter(cfg.DISTANCE) --the height of a meter our worlds
    self.score = {0, 0}
    self.goal_img = objects.Sprite:new('goal', {0,0} )
    -- register keys
    local keymanager = KeyManager:new()

    keymanager:register('space', function(dt) self.board.guy:boost(dt) end)
    keymanager:register('r', function(dt)
        self.board:reset() -- resets guy, ball & opponents states
        self.board = Board:new()
        self.score = {0, 0}
    end, 3.0)
    keymanager:register('left', function(dt, map)
        if map['top'] or map['down'] then
            self.board.guy:push((-cfg.POWER*dt)*0.5, 0)
        else
            self.board.guy:push(-cfg.POWER*dt, 0)
        end
    end)
    keymanager:register('right', function(dt, map)
        if map['top'] or map['down'] then
            self.board.guy:push((cfg.POWER*dt)*0.5, 0)
        else
            self.board.guy:push(cfg.POWER*dt, 0)
        end
    end)
    keymanager:register('up', function(dt, map)
        if map['left'] or map['right'] then
            self.board.guy:push(0, (-cfg.POWER*dt)*0.5)
        else
            self.board.guy:push(0, -cfg.POWER*dt)
        end
    end)
    keymanager:register('down', function(dt, map)
        if map['left'] or map['right'] then
            self.board.guy:push(0, (cfg.POWER*dt)*0.5)
        else
            self.board.guy:push(0, cfg.POWER*dt)
        end
    end)
    self.keymanager = keymanager
    self.cached_menu = MainMenu:new()
    return self
end

function Game:update(dt)
    if self.menu == nil then
        self.board:update(dt)
        -- update opponents
        ai.step(dt)
        for i, g in ipairs(self.board.opponents) do
            ai.manage(g, dt)
        end
    end
    -- manage keys
    if self.menu == nil then
      self.active_keymanager = self.keymanager
        self.keymanager:manage(dt)
    else
      self.active_keymanager = self.menu.keymanager
        self.menu.keymanager:manage(dt)
    end
end

function Game:drawbars(num, color, m, y_offset, right)
    local y_offset = y_offset or 0
    local lines = 10
    local w = 10 -- width
    local h = 30 -- height
    local m = m or 5 -- margin (x)
    local s = 2 -- shadow
    if right then -- align right
        for i=1,self.score[1] do
            y_offset = math.floor((i-1)/lines) 
            love.graphics.setColor( 50, 50, 50)
            love.graphics.rectangle('fill', self.board.background.width - (w+m)*i - (w+m-s) + ((w+m)*y_offset*lines), (h+m)*y_offset+(w+m+s), w, h)
            love.graphics.setColor( unpack(color) )
            love.graphics.rectangle('fill', self.board.background.width - (w+m)*i - (w+m) + ((w+m)*y_offset*lines),  (h+m)*y_offset+(w+m), w, h)
        end
    else
        for i=1,num do
            y_offset = math.floor((i-1)/lines) 
            love.graphics.setColor( 50, 50, 50)
            love.graphics.rectangle('fill', (w+m)*i-(y_offset*(w+m)*lines)+s, (h+m)*y_offset+w+m+s, w, h)
            love.graphics.setColor( unpack(color) )
            love.graphics.rectangle('fill', (w+m)*i - (y_offset*(w+m)*lines), (h+m)*y_offset + (w+m), w, h)
        end
    end
end

function Game:draw()
    self.board:draw()
    -- SCORE display
    self:drawbars(self.score[2], cfg.colors[1], 5, 0, false)
    self:drawbars(self.score[1], cfg.colors[2], 5, 0, true)
    -- overlays
    --
    -- goal
    if self.menu ~= nil then
        self.menu:draw()
    end
    if self.board.goal_marked then
        self.goal_img:draw(0, 0)
    end
end

function Game:reset()
    self.board:reset_state() -- resets guy, ball & opponents states
    self.board = Board:new()
    self.score = {0, 0}
end

function Game:key_press(key)
    if key == 'escape' then
        if self.menu == nil then
            self.menu = self.cached_menu
        else
            self.menu = nil
        end
    else
        if self.menu ~= nil then
            self.menu:key_press(key)
        end
    end
end

function love.keypressed(key)
  if game.active_keymanager then
      game.active_keymanager:keypressed(key)
  end
  game:key_press(key)
end


function love.keyreleased(key)
  if game.active_keymanager then
    game.active_keymanager:keyreleased(key)
    end
end
return {
    Game = Game
}
