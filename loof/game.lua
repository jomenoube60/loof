objects = require('objects')
cfg = require('config')

function beginContact(a, b, coll)
    local player = nil
    local ball = nil
    if a:getUserData() == 'Ball' and b:getUserData() == 'Dude' then
        ball = a
        player = b
    elseif b:getUserData() == 'Ball' and a:getUserData() == 'Dude' then
        ball = b
        player = a
    end
    if ball then
        ball = objects.drawables[ball]
        player = objects.drawables[player]
        ball:attach(player)
    end
end

function makeBoard() 
    local self = {
        world = love.physics.newWorld(0, 0, true), --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
        size = 900
    }
    self.world:setCallbacks(beginContact)

    --initial graphics setup
    love.graphics.setBackgroundColor(104, 136, 248) --set the background color to a nice blue
    love.window.setMode(self.size, self.size) --set the window dimensions to 650 by 650 with no fullscreen, vsync on, and no antialiasing
    -- terrain limits
    local edges = love.physics.newBody(self.world, 0, 0)
    objects.Edge:clone():init( edges, {0, 0, self.size, 20} )
    objects.Edge:clone():init( edges, {0, 0, 0, self.size-20} )
    objects.Edge:clone():init( edges, {self.size-20, 20, self.size-20, self.size-20} )
    objects.Edge:clone():init( edges, {20, self.size-20, self.size-20, self.size-20} )

    local rnd = function(size)
        return {love.math.random(20, size-20), love.math.random(size)}
    end
    -- player
    self.guy = objects.Dude:clone():init( love.physics.newBody(self.world, self.size/2, self.size/2, "dynamic") )
    self.guy.debug = cfg.DEBUG
    -- computer managed dudes
    self.opponents = {}

    for i=1,cfg.DUDES do
        local pos = rnd(self.size)
        table.insert(self.opponents,
            objects.Dude:clone():init(
            love.physics.newBody(self.world, pos[1], pos[2], "dynamic") , {color={200, 50, 40}})
        )
    end

    self.ball = objects.Ball:clone():init( love.physics.newBody(self.world, self.size/2+2*self.guy.radius, self.size/2, "dynamic") )
    self.active_objects = {}
    for i, dude in ipairs(self.opponents) do
        table.insert(self.active_objects, dude)
    end
    table.insert(self.active_objects, self.guy)
    table.insert(self.active_objects, self.ball)

    self.update = function(dt)
        self.world:update(dt)
        -- allow borrowing ball when collisions are not active (w/ player has the ball)
        r = self.ball.radius
        bx = self.ball.body:getX()
        by = self.ball.body:getY()
        for i, g in ipairs(self.active_objects) do
            g:update(dt)
            if g:isa(objects.Dude) and g ~= self.ball.player then
                local dx = (g.feet[1] + g.body:getX())/2
                local dy = (g.feet[2] + g.body:getY())/2
                if dx - r < bx and  dx + r > bx  and dy - r < by and dy + r > by then
                    if self.ball.player ~= g then
                        self.ball:attach(g)
                    end
                end
            end
        end
    end

    self.draw = function()
        love.graphics.setColor(14, 70, 160) -- set the drawing color to green for the ground
        love.graphics.polygon("fill", 0, 0, self.size, 0, self.size, self.size, 0, self.size)
        for i, g in ipairs(self.active_objects) do
            g:draw()
        end
    end
    return self
end

Game = objects.object:clone( {max_speed = 20000} )

function Game:init()
    love.physics.setMeter(cfg.DISTANCE) --the height of a meter our worlds
    self.board = makeBoard()
    return self
end

function Game:draw()
    self.board.draw()
end

function Game:update(dt)
    self.board.update(dt)
    local power = cfg.POWER
    for i, g in ipairs(self.board.opponents) do
        g:push( love.math.random(-power, power), love.math.random(-power, power) )
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
