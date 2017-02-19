local managed = {}

local function step(dt)
    managed.have_ball = false
    for dude in pairs(managed) do
        if dude.ball then
            managed.have_ball = true
            break
        end
    end
end

local function manage(dude)
    if managed[dude] == nil then
        managed[dude] = {
            mode = 'toball'
        }
    end
    local infos = managed[dude]

    local g = game.board.goals[1]
    if dude.ball then
        if dude.y > g[2] and dude.y < g[4] and dude.x - g[1] < 600 then
            infos.mode = 'togoal'
        else
            infos.mode = 'tofrontgoal'
        end
    else
        infos.mode = 'toball'
    end

    if infos.mode == 'toball' then
        local x =  game.board.ball.x - dude.x
        local y =  game.board.ball.y - dude.y
        local v = math.abs(x) + math.abs(y)
        local s = normalVelocity(x, y)
        if s[1] == s[1] then
            if not managed.have_ball and v < 60 then
                dude:boost()
            else
                if managed.have_ball then
                    x = game.board.guy.x - dude.x
                    y = game.board.guy.y - dude.y
                    s = normalVelocity(x, y)
                    v = math.abs(x) + math.abs(y)
                    if v < 100 and not dude.boosted then
                        dude:boost()
                    end
                end
                dude:push(s[1]*cfg.POWER, s[2]*cfg.POWER)
            end
        end
    elseif infos.mode == 'tofrontgoal' then -- front goal
        local x = math.min( g[3] + (game.board.background.width / 10) - dude.x, cfg.POWER)
        local y = math.min( (g[2] + (g[4] - g[2])/2) - dude.y , cfg.POWER)
        local s = normalVelocity(x, y)
        dude:push(s[1]*cfg.POWER, s[2]*cfg.POWER)
        print("front goal", x, y)
    else -- togoal
        local g = game.board.goals[1]
        local x = math.min( g[3] - dude.y - 0.1, cfg.POWER)
        local y = math.min( (g[2] + (g[4] - g[2])/2) - dude.y , cfg.POWER)
        dude:push(x, y)
        print("goal")
    end
end


local function clear()
    managed = {}
end

return {
    manage = manage,
    step = step,
    clear = clear,
}
