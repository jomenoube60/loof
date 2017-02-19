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
    self.fixture:setRestitution(0.8)
    self.body:setLinearDamping(0.5)
    self.fixture:setFriction(0.3)
    self.fixture:setUserData('Dude')
    self.feet = {0, 0}
    return self
end

function Dude:reset()
    baseobj.DrawableInterface.reset(self)
    self.shot        = nil
    self.pushed      = nil
    self.boosted     = nil
    self.slowed_down = nil
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

    local sx, sy = self.body:getLinearVelocity()
    local s = normalVelocity(sx, sy)
    local x = self.body:getX()+(self.radius*s[1])
    local y = self.body:getY()+(self.radius*s[2])

    if self.slowed_down then
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
        self.body:setLinearVelocity((sx+s[1]) * cfg.POWER*0.01 , (sy+s[2])*cfg.POWER*0.01)
    end
end

return {
    Dude = Dude
}
