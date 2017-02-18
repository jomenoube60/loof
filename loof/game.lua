objects = require('objects')
cfg = require('config')

function dprint(txt)
    if cfg.DEBUG then
        print(txt)
    end
end

function beginContact(a, b, coll) -- collision handling
    local player = nil
    local ball = nil

    a = objects.drawables[a]
    b = objects.drawables[b]

    if a:isa(objects.Ball) and b:isa(objects.Dude) then
        ball = a
        player = b
    elseif b:isa(objects.Ball) and a:isa(objects.Dude) then
        ball = b
        player = a
    elseif b:isa(objects.Dude) and a:isa(objects.Dude) then
        dprint("Dude <> Dude collision")
        if b.boosted or b.pushed then
            a:hit()
        elseif a.boosted or a.pushed then
            b:hit()
        end
    end
    if ball and not player.pushed then
        ball:attach(player)
    end
end

function makeBoard() 
    local self = {
        world = love.physics.newWorld(0, 0, true), --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
        size = 900
    }
    self.reset_state = function()
        self.guy.body:setPosition( self.background.width / 4, self.background.height/2 )
        self.guy.body:setLinearVelocity(0, 0)

        self.ball.body:setPosition( self.background.width / 2, self.background.height/2 )
        self.ball.body:setLinearVelocity(0, 0)

        local op_point = {self.background.width * 3 / 4, self.background.height/2 }
        local amp = self.background.height / 5
        for i, op in ipairs(self.opponents) do
            op.body:setPosition( op_point[1] + love.math.random( -amp/2, amp/2),
                op_point[2] + love.math.random(-amp, amp)
                )
            op.body:setLinearVelocity(0, 0)
        end
    end
    self.update = function(dt)
        if self.goal_marked then
            self.goal_marked = self.goal_marked + dt
            if self.goal_marked > 3 then
                self.goal_marked = nil -- reset game
                self.reset_state()
            end
            return
        end

        self.world:update(dt)
        local r = self.ball.radius
        local bx = self.ball.body:getX()
        local by = self.ball.body:getY()
        -- goal detection
        for i, coords in ipairs(self.goals) do
            if bx > coords[1] and bx < coords[3] and by > coords[2] and by < coords[4] then
                game.score[i] = game.score[i] + 1
                self.goal_marked = 1
            end
        end
        -- allow borrowing ball when collisions are not active (w/ player has the ball)
        local borrowable = self.ball.player ~= nil
        r = r*2 -- make bigger spot
        for i, g in ipairs(self.active_objects) do
            g:update(dt)
            if borrowable and g:isa(objects.Dude) and g ~= self.ball.player then
                local dx = (g.feet[1] + g.body:getX())/2
                local dy = (g.feet[2] + g.body:getY())/2
                if dx - r < bx and  dx + r > bx  and dy - r < by and dy + r > by then
                    if self.ball.player ~= g then
                        dprint("Ball changes from " , self.ball.player , " to " , g)
                        self.ball:attach(g)
                    end
                end
            end
        end
    end

    self.draw = function()
        self.background:draw(0, 0)
        for i, g in ipairs(self.active_objects) do
            g:draw()
        end
        if self.goal_marked then
            self.goal_img:draw(0, 0)
        end
    end
    self.world:setCallbacks(beginContact)

    level = require(cfg.level)
    self.background = objects.Sprite:clone():init(level.bg, {0,0} )
    love.window.setMode(self.background.width, self.background.height)
    self.goal_img = objects.Sprite:clone():init('goal', {0,0} )

    -- build collision elements from level data
    local edges = love.physics.newBody(self.world, 0, 0)

    for i, ch in ipairs(level.chains) do
        objects.Poly2:clone():init(edges, ch)
    end
    for i, ch in ipairs(level.polygons) do
        objects.Poly:clone():init(edges, ch)
    end
    for i, ch in ipairs(level.rectangles) do
        objects.Rectangle:clone():init(edges, ch)
    end
    self.goals = level.goals

    local rnd = function(size)
        return {love.math.random(20, size-20), love.math.random(size)}
    end
    -- bg
    -- player
    self.guy = objects.Dude:clone():init( love.physics.newBody(self.world, 0, 0, "dynamic") , {color={128, 179, 255}})
    self.guy.img = objects.Sprite:clone():init('p1')
    self.guy.debug = cfg.DEBUG
    -- computer managed dudes
    self.opponents = {}

    local p2 = objects.Sprite:clone():init('p2')
    for i=1,cfg.DUDES do
        local d = objects.Dude:clone():init(love.physics.newBody(self.world, 0, 0, "dynamic") , {color={255, 70, 204}})
        d.img = p2
        table.insert(self.opponents, d)
    end

    self.ball = objects.Ball:clone():init( love.physics.newBody(self.world, 0, 0, "dynamic") )
    self.active_objects = {}
    for i, dude in ipairs(self.opponents) do
        table.insert(self.active_objects, dude)
    end
    table.insert(self.active_objects, self.guy)
    table.insert(self.active_objects, self.ball)
    self.reset_state()
    return self
end

Game = objects.object:clone( {max_speed = 20000} )

function Game:init()
    love.physics.setMeter(cfg.DISTANCE) --the height of a meter our worlds
    self.board = makeBoard()
    self.score = {0, 0}
    return self
end

function Game:draw()
    self.board.draw()
    -- team 1 score
    for i=1,self.score[2] do
        love.graphics.setColor( 50, 50, 50)
        love.graphics.rectangle('fill', 15*i+2, 15+2, 10, 30)
        love.graphics.setColor( unpack(cfg.colors[1]) )
        love.graphics.rectangle('fill', 15*i, 15, 10, 30)
    end
    -- team 2 score
    for i=1,self.score[1] do
        love.graphics.setColor( 50, 50, 50)
        love.graphics.rectangle('fill', self.board.background.width - 15*i - 13, 17, 10, 30)
        love.graphics.setColor( unpack(cfg.colors[2]) )
        love.graphics.rectangle('fill', self.board.background.width - 15*i - 15, 15, 10, 30)
    end
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
