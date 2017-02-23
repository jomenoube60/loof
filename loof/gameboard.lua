local ai = require('ai')

function solve_collision(a, b, coll) -- collision handling
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

Board = objects.object:clone()

function Board:new()
    local self = objects.object.new(self)
    local level = require('levels.' .. cfg.level)
    self.world = love.physics.newWorld(0, 0, true)
    self.world:setCallbacks(solve_collision)

    self.background = objects.Sprite:new(level.bg, {0,0} )

    -- build collision elements from level data
    local edges = love.physics.newBody(self.world, 0, 0)

    for i, ch in ipairs(level.chains) do
        objects.Poly2:new(edges, ch)
    end
    for i, ch in ipairs(level.polygons) do
        objects.Poly:new(edges, ch)
    end
    for i, ch in ipairs(level.rectangles) do
        objects.Rectangle:new(edges, ch)
    end
    self.goals = level.goals

    -- player
    self.guy = objects.Dude:new(love.physics.newBody(self.world, 0, 0, "dynamic") , {color={128, 179, 255}})
    self.guy.img = objects.Sprite:new('p1')
    self.guy.debug = cfg.DEBUG

    -- computer managed dudes
    self.opponents = {}
    self.active_objects = {}

    local p2 = objects.Sprite:new('p2')
    for i=1,cfg.DUDES do
        self:add_opponent(p2)
    end
    self.opponents_img = p2

    table.insert(self.active_objects, self.guy)

    self.ball = objects.Ball:new( love.physics.newBody(self.world, 0, 0, "dynamic") )
    table.insert(self.active_objects, self.ball)

    self:reset_state()
    return self
end

function Board:remove_opponent()
    if #self.opponents > 0 then
        local dead = self.opponents[1]
        table.remove(self.opponents, 1)
        table.remove(self.active_objects, 1)
        dead:destroy()
        cfg.DUDES = cfg.DUDES - 1
    end
end

function Board:add_opponent(image)
    if image == nil then
        image = objects.Sprite:new('p2')
        cfg.DUDES = cfg.DUDES + 1
    end
    local d = objects.Dude:new(love.physics.newBody(self.world, 0, 0, "dynamic") , {color={255, 70, 204}})
    d.img = image
    table.insert(self.opponents, 1, d)
    table.insert(self.active_objects, 1, d)

    local op_point = {self.background.width * 3 / 4, self.background.height/2 }
    local amp = self.background.height / 5
    d.body:setPosition( op_point[1] + love.math.random( -amp/2, amp/2),
        op_point[2] + love.math.random(-amp, amp)
    )
end

function Board:reset_state()
    self.guy.body:setPosition( self.background.width / 4 + math.random(-100, 100), self.background.height/2  + math.random(-100, 100))
    self.guy:reset()

    self.ball.body:setPosition( self.background.width / 2, self.background.height/2 )
    self.ball:reset()

    local op_point = {self.background.width * 3 / 4, self.background.height/2 }
    local amp = self.background.height / 5
    for i, op in ipairs(self.opponents) do
        op.body:setPosition( op_point[1] + love.math.random( -amp/2, amp/2),
            op_point[2] + love.math.random(-amp, amp)
        )
        op:reset()
    end
    self.ball:attach(nil)
end

function Board:update(dt)
    self.world:update(dt)
    if self.goal_marked then
        self.goal_marked = self.goal_marked + dt
        if self.goal_marked > 3 then
            self.goal_marked = nil -- reset game
            self:reset_state()
            ai.clear()
            return
        end
    end
    -- goal detection
    local bx = self.ball.body:getX()
    local by = self.ball.body:getY()

    if not self.goal_marked then
        for i, coords in ipairs(self.goals) do
            if bx > coords[1] and bx < coords[3] and by > coords[2] and by < coords[4] then
                game.score[i] = game.score[i] + 1
                self.goal_marked = 1
            end
        end
    end
    
    local found = nil
    for i, g in ipairs(self.active_objects) do
        if not found and g:isa(objects.Dude) and g ~= self.ball.player then -- if dude without a ball
            local x, y, dist = self.ball:distance(unpack(g.feet))
            if dist - g.radius - self.ball.radius - 10 <= 0 then
                self.ball:attach(nil)
                found = true
            end
        end
        g:update(dt)
    end
end

function Board:draw()
    self.background:draw(0, 0)
    for i, g in ipairs(self.active_objects) do
        g:draw()
    end
end

