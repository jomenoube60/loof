local Inputs = objects.object:clone()
Inputs.list = objects.object:new()

BTN_UP = 1
BTN_DOWN = 2
BTN_LEFT = 3
BTN_RIGHT = 4
BTN_1 = 5

function Inputs:new()
    local self = objects.object.new(self)
    self.blocked = 0
    return self
end

function Inputs:update(dt)
    if self.blocked > 0 then
        self.blocked = self.blocked - dt
    end
end

function Inputs:add_input(name, input)
    local realname = name
    local nr = 1
    while self.list[realname] ~= nil do
        nr = nr + 1
        realname = name .. 'nr' 
    end
    self.list[realname] = input
    return realname
end

function Inputs:remove_input(name)
    self.list[name] = nil
end

-- polling
function Inputs:ispressed(name, keyname)
    if self.blocked > 0 then
        return
    end
    local l = self.list[name]
    if l then
        return self.list[name]:ispressed(keyname)
    end
end

function Inputs:getAxis(name, which)
    if self.blocked > 0 then
        return 0,0
    end
    local l = self.list[name]
    if l then
        return self.list[name]:getAxis(which)
    else
        return 0, 0
    end
end

gameInputs = Inputs:new()

local KeyboardInput = objects.object:clone()
function KeyboardInput:new(key_mapping, axis) -- axis order: top, down, left, right
    local self = objects.object.new(self)
    self.map = key_mapping
    self.axis = axis
    local axismap = {}
    for i, name in ipairs({'up', 'down', 'left', 'right'}) do
        axismap[name] = axis[i]
    end
    self.axismap = axismap

    return self
end
KeyboardInput.pressmap = {}

function KeyboardInput:getAxis(which)
    local x, y = 0, 0
    if self.pressmap[self.axis[3]] then
        x = -1
    end
    if self.pressmap[self.axis[4]] then
        if x == 0 then
            x = 1
        else
            x = 0
        end
    end
    if self.pressmap[self.axis[1]] then
        y = -1
    end
    if self.pressmap[self.axis[2]] then
        if y == 0 then
            y = 1
        else
            y = 0
        end
    end
    return x, y
end

function KeyboardInput:ispressed(nr)
    if type(nr) == 'number' then
        return self.pressmap[self.map[nr]]
    else
        return self.pressmap[self.axismap[nr]]
    end
end

KeyboardInput.map = objects.object:new()

-- add default keyboard layout
Inputs:add_input('kb', KeyboardInput:new( {'space', 'escape'}, {'up', 'down', 'left', 'right'}) )
Inputs:add_input('kb2', KeyboardInput:new( {'e'}, {'z', 's', 'q', 'd'}) )

local JoystickInput = objects.object:clone()
function JoystickInput:new(joystick)
    local self = objects.object.new(self)
    self.jp = joystick
    return self
end

function JoystickInput:getAxis(which)
    return self.jp:getGamepadAxis(which..'x'), self.jp:getGamepadAxis(which..'y')
end

function JoystickInput:ispressed(nr)
    if type(nr) == 'number' then
        return self.jp:isDown(nr)
    else
        if nr == 'left' and self.jp:getGamepadAxis('leftx') < 0 then
            return true
        elseif nr == 'right' and self.jp:getGamepadAxis('leftx') > 0 then
            return true
        elseif nr == 'up' and self.jp:getGamepadAxis('lefty') < 0 then
            return true
        elseif nr == 'down' and self.jp:getGamepadAxis('lefty') > 0 then
            return true
        end
    end
end

function love.joystickadded(joystick)
    gameInputs:add_input('gp', JoystickInput:new(joystick) )
end

function love.keypressed(key)
    KeyboardInput.pressmap[key] = true
end

function love.keyreleased(key)
    KeyboardInput.pressmap[key] = nil
end
