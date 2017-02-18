-- helper functions
--
-- from http://lua-users.org/wiki/InheritanceTutorial


local baseobj = require('baseobj')
local player = require('player')


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


-- Std objects

local Edge = baseobj.DrawableInterface:clone()

function Edge:init(body, position)
    baseobj.DrawableInterface.init(self, body, love.physics.newEdgeShape(unpack(position)))
    self.fixture:setRestitution(0.01)
    self.fixture:setFriction(1)
    return self
end

local Rectangle = baseobj.DrawableInterface:clone()

function Rectangle:init(body, coords)
    local co = { coords[1], coords[2], coords[3], coords[2], coords[3], coords[4], coords[1], coords[4] }
    baseobj.DrawableInterface.init(self, body, love.physics.newPolygonShape(unpack(co)))
    self.fixture:setRestitution(0.01)
    self.fixture:setFriction(1)
    return self
end

local Poly2 = baseobj.DrawableInterface:clone()

function Poly2:init(body, coords)
    baseobj.DrawableInterface.init(self, body, love.physics.newChainShape(true, unpack(coords)))
    self.fixture:setRestitution(0.01)
    self.fixture:setFriction(1)
    return self
end

local Ball = baseobj.DrawableInterface:clone()

function Ball:init(body, opts)
    local radius = opts and opts.radius or 10
    baseobj.DrawableInterface.init(self, body, love.physics.newCircleShape(radius))
    self.fixture:setUserData("Ball")
    self.color = opts and opts.color or {0, 0, 0}
    self.radius = radius
    self.body:setMass(0.1)
    self.fixture:setDensity(0.5)
    self.fixture:setFriction(0.2)
    self.body:setLinearDamping(0.3)
    self.fixture:setRestitution(0.9)
    self.img = baseobj.Sprite:clone():init('ball')
    return self
end

function Ball:draw()
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

return {
    object = baseobj.object,
    drawables = baseobj.all_drawables,
    Sprite = baseobj.Sprite,

    Edge = Edge,
    Poly = Poly,
    Poly2 = Poly2,
    Rectangle = Rectangle,

    Ball = Ball,
    Dude = player.Dude,
}
