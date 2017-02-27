key_funcs = require('key_handlers')

local Menu = objects.object:clone()

function Menu:new(background, choices)
    local self = objects.object.new(self)
    self.background = objects.Sprite:new(background, {0,0} )
    self.choices = choices
    self.selected = 1
    self.last_ts = 0
    self.ts = 0
    self.repeat_max = 0.2

    self.unselected_pics = objects.object:new()
    for i, choice in ipairs(choices) do
        self.unselected_pics:insert( objects.Sprite:new('menu_' .. choice, {0,0} ))
    end
    self.selected_pics = objects.object:new()
    for i, choice in ipairs(choices) do
        self.selected_pics:insert( objects.Sprite:new('menu_' .. choice .. "_sel", {0,0} ))
    end
    return self
end

function Menu:update(dt)
    self.ts = self.ts + dt
    if self.last_ts + self.repeat_max > self.ts then
        return
    end
        
    if gameInputs:ispressed('*', 'down') then
        if self.selected < #self.choices then
            self.last_ts = self.ts
            self.selected = self.selected + 1
        end
    elseif gameInputs:ispressed('*', 'up') then
        if self.selected > 1 then
            self.last_ts = self.ts
            self.selected = self.selected - 1
        end
    elseif gameInputs:ispressed('*', 2) then
        self.last_ts = self.ts
        key_funcs.pop_one_level()
    elseif gameInputs:ispressed('*', 1) then
        self.last_ts = self.ts
        self['handle_' .. self.choices[self.selected]](self, 'return')
    elseif gameInputs:ispressed('*', 'left') then
        self.last_ts = self.ts
        self['handle_' .. self.choices[self.selected]](self, 'left')
    elseif gameInputs:ispressed('*', 'right') then
        self.last_ts = self.ts
        self['handle_' .. self.choices[self.selected]](self, 'right')
    end
end

function Menu:draw()
    self.background:draw(0, 0)
    for i, choice in ipairs(self.unselected_pics) do
        local pic = nil
        if self.selected == i then
            pic = self.selected_pics[i]
        else
            pic = choice
        end
        if pic ~= nil then
            pic:draw(300, i*100)
        end
    end
end

MainMenu = Menu:clone()

function MainMenu:new()
    local self = Menu.new(self, 'menu', {'NewGame', 'Enemies', 'Quit'})
    return self
end

function MainMenu:draw()
    Menu.draw(self)
    for i=1,#game.board.opponents do
        game.board.opponents_img:draw(640 + 50*i, 280)
    end
end

MainMenu.handle_Quit = love.event.quit
MainMenu.handle_Resume = key_funcs.pop_one_level

function MainMenu:handle_NewGame(from)
    game:reset()
    key_funcs.pop_one_level()
end

function MainMenu:handle_Enemies(from)
    if from == 'right' then
        game.board:add_opponent()
    elseif from == 'left' then
        game.board:remove_opponent()
    end
end
