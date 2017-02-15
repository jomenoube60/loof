local POWER = 400
local DISTANCE = 70

function DrawableInterface(body, shape)
    local self = {
        body = body,
        shape = shape or love.physics.newRectangleShape(0, 0, 50, 100)
    }
    self.fixture = love.physics.newFixture(self.body, self.shape, 5) -- A higher density gives it more mass.

    self.draw = function()
    end

    return self
end

function makeEdge(body, position)
    local self = DrawableInterface(body, love.physics.newEdgeShape(unpack(position)))
    self.shape = love.physics.newEdgeShape(unpack(position))
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setRestitution(0.0001)
    self.fixture:setFriction(1)

    return self
end

function normalVelocity(sx, sy)
    local asx = math.abs(sx)
    local asy = math.abs(sy)
    if asx > asy then
        sy = sy / asx
        sx = sx / asx
    else
        sx = sx / asy
        sy = sy / asy
    end
    return {sx, sy}
end

function makeDude(body, opts)
    local radius = opts and opts.radius or 20
    local self = DrawableInterface(body, love.physics.newCircleShape(radius)) 
    self.color = opts and opts.color or {0, 0, 0}
    self.radius = radius
    self.boosted = nil
    -- bounce settings
    self.fixture:setRestitution(0.99)
    self.body:setLinearVelocity(50, 10) --let the ball bounce
    self.body:setLinearDamping(0.5) --let the ball bounce
    self.fixture:setFriction(0.01) --let the ball bounce

    self.draw = function()
        love.graphics.setColor(unpack(self.color))
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
        love.graphics.setColor(200, 200, 200)
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius()-10)

        local sx, sy = self.body:getLinearVelocity()
        local s = normalVelocity(sx, sy)
        local r = self.shape:getRadius()
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", self.body:getX()+(s[1]*r), 
        self.body:getY()+(s[2]*r), 4)

    end

    self.update = function(dt)
--        print(self.slowed_down, self.boosted)
        if self.boosted ~= nil then
            self.boosted = dt + self.boosted
            if self.boosted >= 0.1 then
                if self.slowed_down == nil then
                    self.body:setLinearVelocity(0, 0)
                end
            end

            if self.boosted >= 0.2 then
                self.slowed_down = self.boosted
                self.boosted = nil
            end
        end
        if self.slowed_down then
            self.slowed_down = self.slowed_down + dt
            if self.slowed_down > 2 then
                self.slowed_down = nil
                print("reset")
            end
        end
    end

    self.push = function(x, y)
        if self.slowed_down == nil then
        else
            x = x/2
            y = y/2
        end
        self.body:applyForce(x, y)
    end

    self.setVelocity = function(x, y)
        self.body:setLinearVelocity(x, y)
    end

    self.boost = function()
        if self.boosted == nil and self.slowed_down == nil then
        local sx, sy = self.body:getLinearVelocity()
        s = normalVelocity(sx, sy)
            self.boosted = 0.0001
            local fac = 3
--            print(sx, sy)
--            if sx
            local function getPower(velocity)
            end
            self.body:setLinearVelocity(s[1] * POWER*2 , s[2]*POWER*2) 
        end
    end

    return self
end

function makeBoard() 
    local self = {
        world = love.physics.newWorld(0, 0, true), --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
        size = 900
    }

    --initial graphics setup
    love.graphics.setBackgroundColor(104, 136, 248) --set the background color to a nice blue
    love.window.setMode(self.size, self.size) --set the window dimensions to 650 by 650 with no fullscreen, vsync on, and no antialiasing
    -- terrain limits
    makeEdge( love.physics.newBody(self.world, 0, 0), {0, 0, self.size, 0} )
    makeEdge( love.physics.newBody(self.world, 0, 0), {0, 0, 0, self.size} )
    makeEdge( love.physics.newBody(self.world, 0, 0), {self.size, 0, self.size, self.size} )
    makeEdge( love.physics.newBody(self.world, 0, 0), {0, self.size, self.size, self.size} )
    -- player
    self.guy = makeDude( love.physics.newBody(self.world, self.size/2, self.size/2, "dynamic") )
    -- computer managed dudes
    self.opponents = {
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color={200, 50, 40}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {200, 200, 40}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {40, 200, 200}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {100, 100, 100}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {100, 100, 100}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {100, 100, 100}}),
        makeDude( love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {100, 100, 100}}),
    }

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
    love.physics.setMeter(DISTANCE) --the height of a meter our worlds
    self.board = makeBoard()

    self.draw = function()
        self.board.draw()
    end

    self.update = function(dt)
        self.board.update(dt)
        local power = POWER
        for i, g in ipairs(self.board.opponents) do
            g.push( love.math.random(-power, power), love.math.random(-power, power) )
        end
        local dude = game.board.guy
        -- ui keys
        if love.keyboard.isDown('escape') then
            love.event.quit()
            return
        end
        -- special keys
        if love.keyboard.isDown("space") then
            dude.boost()
        end
        -- direction keys, special handling
        local sx, sy = dude.body:getLinearVelocity()
        if math.abs(sx)+math.abs(sy) < self.max_speed then
            --here we are going to create some keyboard events
            local num_directions = 0
            local direction_keys = {
                          right  = function() if sx < 0 then dude.setVelocity(0, sy) else dude.push(power, 0) end end,
                          left   = function() if sx > 0 then dude.setVelocity(0, sy) else dude.push(-power, 0) end end,
                          up     = function() if sy > 0 then dude.setVelocity(sx, 0) else dude.push(0, -power) end end,
                          down   = function() if sy < 0 then dude.setVelocity(sx, 0) else dude.push(0, power) end end,
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

