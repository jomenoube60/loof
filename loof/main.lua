local POWER = 400
local DISTANCE = 30

-- helper functions
--
-- from http://lua-users.org/wiki/InheritanceTutorial

function clone( base_object, clone_object )
    if type( base_object ) ~= "table" then
        return clone_object or base_object 
    end
    clone_object = clone_object or {}
    clone_object.__index = base_object
    return setmetatable(clone_object, clone_object)
end

function isa( clone_object, base_object )
    local clone_object_type = type(clone_object)
    local base_object_type = type(base_object)
    if clone_object_type ~= "table" and base_object_type ~= table then
        return clone_object_type == base_object_type
    end
    local index = clone_object.__index
    local _isa = index == base_object
    while not _isa and index ~= nil do
        index = index.__index
        _isa = index == base_object
    end
    return _isa
end

object = clone( table, { clone = clone, isa = isa } )

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

-- interfaces

DrawableInterface = object:clone()

function DrawableInterface:init(body, shape)
    self.body = body
    self.shape = shape or love.physics.newRectangleShape(0, 0, 50, 100)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1) -- A higher density gives it more mass.
    return self
end

function DrawableInterface:draw()
end

function DrawableInterface:update()
end

-- Std objects

Edge = DrawableInterface:clone()

function Edge:init(body, position)
    DrawableInterface.init(self, body, love.physics.newEdgeShape(unpack(position)))
    self.fixture:setRestitution(0.0001)
    self.fixture:setFriction(1)
    return self
end

Ball = DrawableInterface:clone()

function Ball:init(body, opts)
    local radius = opts and opts.radius or 20
    DrawableInterface.init(self, body, love.physics.newCircleShape(radius))
    self.color = opts and opts.color or {0, 0, 0}
    self.radius = radius
    return self

end
function Ball:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
    love.graphics.setColor(220, 220, 200)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius-10)
end



Dude = DrawableInterface:clone()
function Dude:init(body, opts)
    local radius = opts and opts.radius or 20
    DrawableInterface.init(self, body, love.physics.newCircleShape(radius)) 
    self.color = opts and opts.color or {0, 0, 0}
    self.radius = radius
    self.boosted = nil
    -- bounce settings
    self.fixture:setRestitution(0.1)
    self.body:setLinearDamping(0.5)
    self.fixture:setFriction(1)
    return self
end

function Dude:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
    love.graphics.setColor(100, 100, 100)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius-10)

    local sx, sy = self.body:getLinearVelocity()
    local s = normalVelocity(sx, sy)
    love.graphics.setColor(0, 0, 0)
    if self.debug then
        print(s[1], s[2])
    end
    love.graphics.circle("fill",
        self.body:getX()+(s[1]*self.radius),
        self.body:getY()+(s[2]*self.radius),
        4)
end

function Dude:update(dt)
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

function Dude:push(x, y)
    if self.slowed_down == nil then
    else
        x = x/2
        y = y/2
    end
    self.body:applyForce(x, y)
end

function Dude:setVelocity(x, y)
    self.body:setLinearVelocity(x, y)
end

function Dude:boost()
    if self.boosted == nil and self.slowed_down == nil then
        print("boost !")
        local sx, sy = self.body:getLinearVelocity()
        s = normalVelocity(sx, sy)
        self.boosted = 0.0001
        local fac = 3
        self.body:setLinearVelocity(s[1] * POWER*2 , s[2]*POWER*2) 
    end
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
    Edge:clone():init( love.physics.newBody(self.world, 0, 0), {0, 0, self.size, 0} )
    Edge:clone():init( love.physics.newBody(self.world, 0, 0), {0, 0, 0, self.size} )
    Edge:clone():init( love.physics.newBody(self.world, 0, 0), {self.size, 0, self.size, self.size} )
    Edge:clone():init( love.physics.newBody(self.world, 0, 0), {0, self.size, self.size, self.size} )
    -- player
    self.guy = Dude:clone():init( love.physics.newBody(self.world, self.size/2, self.size/2, "dynamic") )
--    self.guy.debug = true
    -- computer managed dudes
    self.opponents = {
        Dude:clone():init(
        love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color={200, 50, 40}}),
        Dude:clone():init(
        love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {200, 200, 40}}),
        Dude:clone():init(
        love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {40, 200, 200}}),
        Dude:clone():init(
        love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {200, 100, 100}}),
        Dude:clone():init(
        love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {200, 100, 100}}),
        Dude:clone():init(
        love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {200, 100, 100}}),
        Dude:clone():init(
        love.physics.newBody(self.world, love.math.random(self.size), love.math.random(self.size), "dynamic") , {color= {200, 100, 100}}),
    }
    self.ball = Ball:clone():init( love.physics.newBody(self.world, self.size/2+self.guy.radius, self.size/2, "dynamic") )
    self.active_objects = {}
    for i, dude in ipairs(self.opponents) do
        table.insert(self.active_objects, dude)
    end
    table.insert(self.active_objects, self.guy)
    table.insert(self.active_objects, self.ball)

    self.update = function(dt)
        self.world:update(dt)
        for i, g in ipairs(self.active_objects) do
            g:update(dt)
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

Game = object:clone( {max_speed = 20000} )

function Game:init()
    love.physics.setMeter(DISTANCE) --the height of a meter our worlds
    self.board = makeBoard()
    return self
end

function Game:draw()
    self.board.draw()
end

function Game:update(dt)
    self.board.update(dt)
    local power = POWER
    for i, g in ipairs(self.board.opponents) do
        g:push( love.math.random(-power, power), love.math.random(-power, power) )
    end
    local dude = game.board.guy
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
    if math.abs(sx)+math.abs(sy) < self.max_speed then
        --here we are going to create some keyboard events
        local num_directions = 0
        local direction_keys = {
            left   = function() if sx > 0 then dude:setVelocity(0, sy) else dude:push(-power, 0) end end,
            right  = function() if sx < 0 then dude:setVelocity(0, sy) else dude:push(power, 0) end end,
            up     = function() if sy > 0 then dude:setVelocity(sx, 0) else dude:push(0, -power) end end,
            down   = function() if sy < 0 then dude:setVelocity(sx, 0) else dude:push(0, power) end end,
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

function love.load()
    game = Game:clone():init()
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

