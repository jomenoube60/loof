function Drawable(body, shape)
    local self = {
        body = body,
        shape = shape or love.physics.newRectangleShape(0, 0, 50, 100)
    }
    self.fixture = love.physics.newFixture(self.body, self.shape, 5) -- A higher density gives it more mass.
    return self
end

function makeEdge(body, position)
    local self = Drawable(body, love.physics.newEdgeShape(unpack(position)))
    self.draw = function()
    end
    self.shape = love.physics.newEdgeShape(unpack(position))
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setRestitution(0.0001)
    self.fixture:setFriction(1)

    return self
end

function makeDude(body, opts)
    local radius = opts and opts.radius or 20
    local self = Drawable(body, love.physics.newCircleShape(radius)) 
    self.color = opts and opts.color or {0, 0, 0}
    self.radius = radius
    self.boosted = 0

    self.draw = function()
        love.graphics.setColor(unpack(self.color))
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())

        local sx, sy = self.body:getLinearVelocity()
        asx = math.abs(sx)
        asy = math.abs(sy)
        local r = self.shape:getRadius()
        if asx > asy then
            sy = sy / asx
            sx = sx / asx
        else
            sx = sx / asy
            sy = sy / asy
        end
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", self.body:getX()+(sx*r), 
        self.body:getY()+(sy*r), 4)

    end

    self.update = function(dt)
        if self.boosted then
            self.boosted = dt + self.boosted
            if self.boosted >= 0.25 and not self.slowed_down then
                self.body:setLinearVelocity(0, 0)
                self.slowed_down = true
            elseif self.boosted >= 3 then
                self.boosted = nil
                self.slowed_down = nil
            end
        end
    end

    self.push = function(x, y)
        self.body:applyForce(x, y)
    end

    self.boost = function()
        if self.boosted == nil then
            self.boosted = 0
            local fac = 3
            sx, sy = self.body:getLinearVelocity()
            self.body:setLinearVelocity(sx*fac, sy*fac)
        end
    end

    -- bounce settings
    self.fixture:setRestitution(0.99)
    self.body:setLinearVelocity(50, 10) --let the ball bounce
    self.body:setLinearDamping(1) --let the ball bounce
    self.fixture:setFriction(0.9) --let the ball bounce

    return self
end

function makeBoard() 
    local self = {
        world = love.physics.newWorld(0, 0, true), --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
        size = 650
    }
    makeEdge( love.physics.newBody(self.world, 0, 0), {0, 0, self.size, 0} )
    makeEdge( love.physics.newBody(self.world, 0, 0), {0, 0, 0, self.size} )
    makeEdge( love.physics.newBody(self.world, 0, 0), {self.size, 0, self.size, self.size} )
    makeEdge( love.physics.newBody(self.world, 0, 0), {0, self.size, self.size, self.size} )
    self.guy = makeDude( love.physics.newBody(self.world, self.size/2, self.size/2, "dynamic") )
    self.opponents = {
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color={200, 50, 40}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {200, 200, 40}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {40, 200, 200}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {100, 100, 100}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {100, 100, 100}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {100, 100, 100}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {100, 100, 100}}),
    }

    --initial graphics setup
    love.graphics.setBackgroundColor(104, 136, 248) --set the background color to a nice blue
    love.window.setMode(self.size, self.size) --set the window dimensions to 650 by 650 with no fullscreen, vsync on, and no antialiasing
    self.update = function(dt)
        self.world:update(dt)
        self.guy.update(dt)
        for i, g in ipairs(self.opponents) do
            g.update(dt)
        end
    end
    self.draw = function()
        love.graphics.setColor(14, 70, 160) -- set the drawing color to green for the ground
        love.graphics.polygon("fill", 0, 0, self.size, 0, self.size, self.size, 0, self.size)
        for i, g in ipairs(self.opponents) do
            g.draw()
        end
        self.guy.draw()
    end
    return self
end

function makeGame()
    local self = {
        max_speed = 20000
    }
    love.physics.setMeter(64) --the height of a meter our worlds will be 64px
    self.board = makeBoard()

    self.draw = function()
        self.board.draw()
    end
    self.update = function(dt)
        self.board.update(dt)
        local power = 400
        for i, g in ipairs(self.board.opponents) do
            g.push( love.math.random(-400, 400), love.math.random(-400, 400) )
        end
        local dude = game.board.guy
        local sx, sy = dude.body:getLinearVelocity()
        if love.keyboard.isDown('escape') then
            love.event.quit()
            return
        end
        if math.abs(sx)+math.abs(sy) < self.max_speed then
            --here we are going to create some keyboard events
            local num_directions = 0
            local direction_keys = {
                right= function() dude.push(power, 0) end,
                left= function() dude.push(-power, 0) end,
                up= function() dude.push(0, -power) end,
                down= function() dude.push(0, power) end,
            }
            local pressed = {}
            for x in pairs(direction_keys) do
                if love.keyboard.isDown(x) then
                    num_directions = num_directions + 1
                    table.insert(pressed, x)
                end
            end
            power = power / num_directions
            for i, x in ipairs(pressed) do
                direction_keys[x]()
            end
            if love.keyboard.isDown("space") then
                dude.boost()
            end
        end 
    end

    return self
end

function love.load()
    game = makeGame()
end

function love.update(dt)
  game.update(dt)
end

function love.draw()
    game.draw()
end
