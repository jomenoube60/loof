local Inputs = objects.object:clone()
Inputs.list = objects.object:new()

BTN_UP = 1
BTN_DOWN = 2
BTN_LEFT = 3
BTN_RIGHT = 4
BTN_1 = 5

function Inputs:new()
    local self = objects.object.new(self)
    return self
end

function Inputs:add_input(name, input)
    self.list[name] = input
end

function Inputs:remove_input(name)
    self.list[name] = nil
end

-- polling
function Inputs:ispressed(name, keyname)
    local l = self.list[name]
    if l then
        return self.list[name]:ispressed(keyname)
    end
end

function Inputs:getAxis(name, which)
    local l = self.list[name]
    if l then
        return self.list[name]:getAxis(which)
    else
        return 0, 0
    end
end

gameInputs = Inputs:clone()

local KeyboardInput = objects.object:clone()
function KeyboardInput:new(key_mapping, axis) -- axis order: top, down, left, right
    local self = objects.object.new(self)
    self.map = key_mapping
    self.axis = axis

    self.keys = {}
    self.ts = 0
    return self
end
KeyboardInput.pressmap = {}

function KeyboardInput:getAxis(which)
    local x, y = 0, 0
    print("---------")
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
    print(x, y)
    return x, y
end

function KeyboardInput:ispressed(nr)
    if type(nr) == 'number' then
        return self.pressmap[self.map[nr]]
    else
        return self.pressmap[nr]
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
    return self.jp:isDown(nr)
end

function love.joystickadded(joystick)
    gameinputs:add_input( 'gp', JoystickInput:new(joystick) )
end

function love.keypressed(key)
    KeyboardInput.pressmap[key] = true
--    if game.active_keymanager then
--        game.active_keymanager:keypressed(key)
--    end
    game:key_press(key)
end

function love.keyreleased(key)
    KeyboardInput.pressmap[key] = nil
--  if game.active_keymanager then
--    game.active_keymanager:keyreleased(key)
--    end
end

--[[
function love.mousepressed(x, y)
    game:mousepressed(x, y)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    game:mousepressed(x, y)
end

]]
