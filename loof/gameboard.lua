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

Board = objects.object:clone()

function Board:init()
    self.world = love.physics.newWorld(0, 0, true)
    self.world:setCallbacks(beginContact)
    local level = require('levels.' .. cfg.level)
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
    self:reset_state()
    return self
end

function Board:reset_state()
    self.guy.body:setPosition( self.background.width / 4, self.background.height/2 )
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
end

function Board:update(dt)
    if self.goal_marked then
        self.goal_marked = self.goal_marked + dt
        if self.goal_marked > 3 then
            self.goal_marked = nil -- reset game
            self:reset_state()
        end
        return
    end

    self.world:update(dt)

    -- goal detection
    local r = self.ball.radius
    local bx = self.ball.body:getX()
    local by = self.ball.body:getY()

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

function Board:draw()
    self.background:draw(0, 0)
    for i, g in ipairs(self.active_objects) do
        g:draw()
    end
    if self.goal_marked then
        self.goal_img:draw(0, 0)
    end
end

