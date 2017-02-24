mod = {}

mod.pop_one_level = function()
    if game.menu ~= nil then
        game.menu = nil
    else
        love.event.quit()
    end
    gameInputs.blocked = 0.25
end

return mod
