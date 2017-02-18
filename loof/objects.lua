-- helper functions
--
-- from http://lua-users.org/wiki/InheritanceTutorial
--


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
    local fac = 1/(asx + asy)
    return { sx*fac, sy*fac }
end

-- Types:
--
-- interfaces

local all_drawables = {}

local Sprite = object:clone()

function Sprite:init(filename)
    self.img = love.graphics.newImage('img/' .. filename .. '.png')
    self.ox = - ( self.img:getWidth() / 2 )
    self.oy = - ( self.img:getHeight() / 2 )
    return self
end

function Sprite:draw(x, y)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.img, x + self.ox, y + self.oy )
end

local DrawableInterface = object:clone()

function DrawableInterface:init(body, shape)
    self.body = body
    self.shape = shape or love.physics.newRectangleShape(0, 0, 50, 100)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1) -- A higher density gives it more mass.
--    self.body:setFixedRotation(true) -- disable rotations
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
    self.fixture:setFriction(0.2)
    self.body:setLinearDamping(0.3)
    self.fixture:setRestitution(0.9)
    self.img = Sprite:clone():init('pawn')
    return self
end

function Ball:draw()
    --[[
    love.graphics.setColor(220, 220, 200)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius-5)
    ]]
    if self.img ~= nil then
        self.img:draw(self.body:getX(), self.body:getY())
    end
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
    if self.player == player or player ~= nil and player.shot then
        return
    end
    if self.player ~= nil then
        self.player.ball = nil
    end
    if player then
        player.ball = self
    end
    dprint("Ball attached to ", player)
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
    if self.img ~= nil then
        self.img:draw(self.body:getX(), self.body:getY())
    else
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
        love.graphics.setColor(unpack(self.color))
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius-5)
    end

    local sx, sy = self.body:getLinearVelocity()
    local s = normalVelocity(sx, sy)
--    if not s[1] or not s[2] then
--        return
--    end
    if self.slowed_down then
        love.graphics.setColor(80, 80, 82)
    else
        love.graphics.setColor(240, 240, 200)
    end
    local x = self.body:getX()+(self.radius*s[1])
    local y = self.body:getY()+(self.radius*s[2])

    love.graphics.circle("fill", x, y, 10)
    self.feet = {x, y}
end

function Dude:hit()
    self.pushed = 1
end

function Dude:update(dt)
--    self.body:setAngle(0)
    if self.pushed then
        if self.pushed == 1 then
            dprint("PUSHED, SHOOTING !!!")
            self:boost()
        end
        self.pushed = self.pushed + dt
        if self.pushed > 0.2 then
            self.pushed = nil
        end
    end
    if self.shot ~= nil then
        self.shot = self.shot + dt
        if self.shot > 1.5 then
            self.shot = nil
            dprint("shot = nil")
        end
    end

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
            dprint("reset")
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
        self.shot = 1
        dprint("shot = 1")
        ball:attach(nil)
        ball.body:setLinearVelocity(s[1] * cfg.POWER*2 , s[2]*cfg.POWER*2) 
    elseif not self.shot and self.boosted == nil and self.slowed_down == nil then
        dprint("boost !")
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
    Sprite = Sprite,
}
