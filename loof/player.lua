local baseobj = require('baseobj')

local Dude = baseobj.DrawableInterface:clone()
Dude.head = baseobj.Sprite:new('pawn')
Dude.head_slow = baseobj.Sprite:new('pawn_slow')

function Dude:new(body, opts)
    local radius = opts and opts.radius or 20
    local self = baseobj.DrawableInterface.new(self, body, love.physics.newCircleShape(radius)) 
    self.color = opts and opts.color or {0, 0, 0}
    self.radius = radius
    self.boosted = nil
    -- bounce settings
    self.body:setMass(2)
    self.body:setBullet(true)
    self.body:setLinearDamping(0.9)
    self.fixture:setRestitution(0.8)
    self.fixture:setFriction(0.3)
    self.fixture:setUserData('Dude')
    self.feet = {0, 0}
    self.x = 0
    self.y = 0
    return self
end

function Dude:destroy()
    self.fixture:destroy()
    self.body:destroy()
    self.body = nil
    self.fixture = nil
end

function Dude:reset()
    baseobj.DrawableInterface.reset(self)
    self.shot        = nil
    self.pushed      = nil
    self.boosted     = nil
    self.slowed_down = nil
end

function Dude:distance(coords, coord2)
    if coord2 ~= nil then
        coords = {coords, coord2}
    elseif coords[1] == nil then
        coords = {coords.x, coords.y}
    end
    return coords[1]-self.x, coords[2]-self.y
end

function Dude:targets(coords, coord2, delta)
    local x, y = self:distance(coords, coord2)
    local r = normalVelocity(x, y)
    local sx, sy = self.body:getLinearVelocity()
    local s = normalVelocity(sx, sy)
    local ret = false

    if s and s[1] == s[1] then
        if math.abs(s[2] - r[2]) + math.abs(s[1] - r[1]) < (delta or 0.1) then
            ret = true
        end
    end
    return ret, math.abs(x) + math.abs(y), x, y
end

function Dude:draw()
    baseobj.DrawableInterface.draw(self)
    if self.img ~= nil then
        self.img:draw(self.body:getX(), self.body:getY())
    else
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
        love.graphics.setColor(unpack(self.color))
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius-5)
    end
    if self.targetting then
        love.graphics.setColor(0, 255, 0)
    else
        love.graphics.setColor(0, 0, 0)
    end
--    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)

    local sx, sy = self.body:getLinearVelocity()
    local s = normalVelocity(sx, sy)
    local x = self.body:getX()+(self.radius*s[1])
    local y = self.body:getY()+(self.radius*s[2])

    if self.slowed_down ~= nil then
        self.head_slow:draw(x, y)
    else
        self.head:draw(x, y)
    end
    self.feet = {x, y}
end

function Dude:hit()
    self.pushed = 1
end

function Dude:update(dt)
    local x, y = self.body:getLinearVelocity()
    if self.pushed ~= nil then
        if self.pushed == 1 then
            dprint("PUSHED, SHOOTING !!!")
            self:boost(dt)
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
    if self.slowed_down ~= nil then
        self.slowed_down = self.slowed_down + dt
        x = x/2
        y = y/2
        if self.slowed_down > 0.5 then
            self.slowed_down = nil
            dprint("reset")
        end
    end
    self.body:setLinearVelocity(x, y)
end

function Dude:push(x, y)
    if not self.boosted and not self.slowed_down then
      self.body:applyForce(x, y)
    end
end

function Dude:boost(dt)
    local sx, sy = self.body:getLinearVelocity()
    s = normalVelocity(sx, sy)
    if s[1] == s[1] then
        if self.ball then
            local ball = self.ball
            self.shot = 1
            dprint("shot = 1")
            ball:attach(nil)
            ball.body:setPosition(self.feet[1]+s[1]*self.radius, self.feet[2]+s[2]*self.radius)
            ball.body:setLinearVelocity(s[1] * cfg.BALL_SPEED, s[2]*cfg.BALL_SPEED) 
        elseif not self.shot and self.boosted == nil and self.slowed_down == nil then
            dprint("boost !")
            self.boosted = 0.0001
            local asx = math.abs(sx)
            local asy = math.abs(sy)
            coef = 1/math.sqrt( asx^2 + asy^2)
            self.body:setLinearVelocity(s[1]*cfg.POWER*dt, s[2]*cfg.POWER*dt)
        end
    end
end

return {
    Dude = Dude
}
