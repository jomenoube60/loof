key_funcs = require('key_handlers')

local Menu = objects.object:clone()

function Menu:new(background, choices)
    local self = objects.object.new(self)
    self.background = objects.Sprite:new(background, {0,0} )
    self.choices = choices

    self.keymanager = KeyManager:new()
    self.keymanager.idle_time = os.time() + 1
    self.keymanager:register('escape', key_funcs.pop_one_level, 0.5, true)
    self.keymanager:register('up', function(dt)
        if self.selected == 1 then
            self.selected = #self.choices
        else
            self.selected = self.selected - 1
        end
    end, 0.3)
    self.keymanager:register('down', function(dt)
        if self.selected == #self.choices then
            self.selected = 1
        else
            self.selected = self.selected + 1
        end
    end, 0.3)
    for i,k in ipairs({'left', 'right', 'return'}) do -- dynamic keys
        local key = k -- curry
        self.keymanager:register(key, function(dt)
            self['handle_' .. self.choices[self.selected]](self, key)
        end, 0.3)
    end

    self.unselected_pics = objects.object:new()
    for i, choice in ipairs(choices) do
        self.unselected_pics:insert( objects.Sprite:new('menu_' .. choice, {0,0} ))
    end
    self.selected_pics = objects.object:new()
    for i, choice in ipairs(choices) do
        self.selected_pics:insert( objects.Sprite:new('menu_' .. choice .. "_sel", {0,0} ))
    end
    self.selected = 1
    return self
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
    local self = Menu.new(self, 'menu', {'Resume', 'NewGame', 'Ennemies', 'Quit'})
    return self
end

function MainMenu:draw()
    Menu.draw(self)
    game:drawbars(#game.board.opponents, cfg.colors[2], 10, 100, false)
end

MainMenu.handle_Quit = love.event.quit
MainMenu.handle_Resume = key_funcs.pop_one_level

function MainMenu:handle_NewGame(from)
    game:reset()
end

function MainMenu:handle_Ennemies(from)
    if from == 'right' then
        game.board:add_opponent()
    elseif from == 'left' then
        game.board:remove_opponent()
    elseif from == 'left' then
        game.board:remove_opponent()
    end
end
