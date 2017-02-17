-- helper functions
--
-- from http://lua-users.org/wiki/InheritanceTutorial

local function clone( base_object, clone_object )
    if type( base_object ) ~= "table" then
        return clone_object or base_object 
    end
    clone_object = clone_object or {}
    clone_object.__index = base_object
    return setmetatable(clone_object, clone_object)
end

local function isa( clone_object, base_object )
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

local object = clone( table, { clone = clone, isa = isa } )

-- misc

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

-- Types:
--
-- interfaces

local all_drawables = {}

local DrawableInterface = object:clone()

function DrawableInterface:init(body, shape)
    self.body = body
    self.shape = shape or love.physics.newRectangleShape(0, 0, 50, 100)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1) -- A higher density gives it more mass.
    self.body:setFixedRotation(true) -- disable rotations
    all_drawables[self.fixture] = self
    return self
end

function DrawableInterface:draw()
end

function DrawableInterface:update()
end

-- Std objects

local Edge = DrawableInterface:clone()

function Edge:init(body, position)
    DrawableInterface.init(self, body, love.physics.newEdgeShape(unpack(position)))
    self.fixture:setRestitution(0.01)
    self.fixture:setFriction(1)
    return self
end

local Ball = DrawableInterface:clone()

function Ball:init(body, opts)
    local radius = opts and opts.radius or 10
    DrawableInterface.init(self, body, love.physics.newCircleShape(radius))
    self.fixture:setUserData("Ball")
    self.color = opts and opts.color or {0, 0, 0}
    self.radius = radius
    self.body:setMass(0.1)
    self.fixture:setDensity(0.5)
    self.fixture:setFriction(1)
    self.fixture:setRestitution(0.8)
    return self
end

function Ball:draw()
    love.graphics.setColor(220, 220, 200)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius-5)
end

function Ball:update(dt)
    if self.player ~= nil then
        if self.body:isActive() then
            self.body:setActive(false)
        end
        self.body:setPosition(unpack(self.player.feet))
    else
        if not self.body:isActive() then
            self.body:setActive(true)
        end
    end
end

function Ball:attach(player)
    if self.player == player then
        return
    end
    if self.player ~= nil then
        self.player.ball = nil
    end
    if player then
        player.ball = self
    end
    self.player = player
end

local Dude = DrawableInterface:clone()

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
    self.fixture:setUserData('Dude')
    self.feet = {0, 0}
    return self
end

function Dude:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
    love.graphics.setColor(100, 100, 100)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius-10)

    local sx, sy = self.body:getLinearVelocity()
    local s = normalVelocity(sx, sy)
--    if not s[1] or not s[2] then
--        return
--    end
    love.graphics.setColor(0, 0, 0)
    local x = self.body:getX()+(self.radius*s[1])
    local y = self.body:getY()+(self.radius*s[2])

    love.graphics.circle("fill", x, y, 4)
    self.feet = {x, y}
end

function Dude:update(dt)
--    self.body:setAngle(0)

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
    local sx, sy = self.body:getLinearVelocity()
    s = normalVelocity(sx, sy)
    if self.ball then
        local ball = self.ball
        print("shoot!")
        ball:attach(nil)
        ball.body:setPosition( ball.body:getX() + sx, ball.body:getY() + sy )
        ball.body:setLinearVelocity(s[1] * cfg.POWER*2 , s[2]*cfg.POWER*2) 
    elseif self.boosted == nil and self.slowed_down == nil then
        print("boost !")
        self.boosted = 0.0001
        self.body:setLinearVelocity(s[1] * cfg.POWER*2 , s[2]*cfg.POWER*2) 
    end
end

return {
    drawables = all_drawables,
    object = object,
    Edge = Edge,
    Dude = Dude,
    Ball = Ball,
}
