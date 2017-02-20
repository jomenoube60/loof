Menu = objects.object:clone()

function Menu:new(background, choices)
    local self = objects.object.new(self)
    self.background = objects.Sprite:new(background, {0,0} )
    self.choices = objects.object:new()
    for i, choice in ipairs(choices) do
        self.choices:insert( objects.Sprite:new(choice, {0,0} ))
    end
    return self
end

function Menu:draw()
    print("draw")
    self.background:draw(0, 0)
    for i, choice in ipairs(self.choices) do
        choice:draw(300, i*100)
    end
end


return {
    Menu = Menu
}
