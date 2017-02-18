local managed = {}

local function manage(dude)
    if managed[dude] == nil then
        managed[dude] = {
            mode = 'toball'
        }
    end
    local infos = managed[dude]

    if dude.ball then
        infos.mode = 'togoal'
    else
        infos.mode = 'toball'
    end

    if infos.mode == 'toball' then
        local x =  math.min(game.board.ball.x - dude.x , cfg.POWER)
        local y =  math.min(game.board.ball.y - dude.y , cfg.POWER)
        dude:push(x, y)
    else -- togoal
        local g = game.board.goals[1]
        local x = - cfg.POWER
        local y = math.min( (g[2] + (g[4] - g[2])/2) - dude.y , cfg.POWER)
        dude:push(x, y)
    end
end


local function clear()
    managed = {}
end

return {
    manage = manage,
    clear = clear,
}
