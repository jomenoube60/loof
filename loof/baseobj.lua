
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

local object = clone( table, { clone = clone, new = clone, isa = isa } )

local all_drawables = {}

local DrawableInterface = object:new()
DrawableInterface.x = 0
DrawableInterface.y = 0

function DrawableInterface:new(body, shape)
    local self = object.new(self)
    self.body = body
    self.shape = shape or love.physics.newRectangleShape(0, 0, 50, 100)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1) -- A higher density gives it more mass.
    all_drawables[self.fixture] = self
    return self
end

function DrawableInterface:draw()
    if self.body then
        self.x = self.body:getX()
        self.y = self.body:getY()
    end
end

function DrawableInterface:update()
end

function DrawableInterface:reset()
    self.body:setLinearVelocity(0, 0)
    self.x = 0
    self.y = 0
end

function DrawableInterface:distance(coords, coord2) -- returns the x,y distance from this coordinates
    if coord2 ~= nil then
        coords = {coords, coord2}
    elseif coords[1] == nil then
        coords = {coords.x, coords.y}
    end
    return coords[1]-self.x, coords[2]-self.y
end

function DrawableInterface:targets(coords, coord2, delta) -- returns true if targetting this coordinate
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

local Sprite = object:new()

function Sprite:new(filename, origin)
    local self = object.new(self)
    self.img = love.graphics.newImage('img/' .. filename .. '.png')
    self.width = self.img:getWidth()
    self.height = self.img:getHeight()
    if origin then
        self.ox = origin[1]
        self.oy = origin[2]
    else
        self.ox = - ( self.width / 2 )
        self.oy = - ( self.height / 2 )
    end
    return self
end

function Sprite:draw(x, y)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.img, x + self.ox, y + self.oy )
end

return {
    all_drawables = all_drawables,
    object = object,
    DrawableInterface = DrawableInterface,
    Sprite = Sprite,
}
