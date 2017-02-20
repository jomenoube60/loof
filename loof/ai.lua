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

local function manage(dude, dt)
    if managed[dude] == nil then
        managed[dude] = {
            mode = 'toball',
            lastmode_ts = 0,
        }
    end
    local infos = managed[dude]

    local g = game.board.goals[1]
    if dude.ball then
        if dude.y > g[2] and dude.y < g[4] and dude.x - g[1] < 600 then
            print("TOGOAL !!")
            infos.mode = 'togoal'
        else
            infos.mode = 'tofrontgoal'
        end
    else
        if managed.have_ball then
            infos.mode = 'agressive'
        elseif infos.lastmode == nil or infos.lastmode_ts  > 3 then
            infos.lastmode_ts = 0
            if math.random() < 0.5 then
                infos.mode = 'agressive'
            else
                infos.mode = 'toball'
            end
            infos.lastmode = infos.mode
        else
            infos.lastmode_ts = infos.lastmode_ts + dt
            infos.mode = infos.lastmode
        end
    end
    dude.targetting = dude:targets( g[3], game.board.background.height / 2, 0.3)

    local x, y = nil, nil

    if infos.mode == 'agressive' then
        local tgt, dist
        tgt, dist, x, y = dude:targets(game.board.guy)
        if not dude.boosted and tgt and dist < 100 then
            dude:boost(dt)
        end
    elseif infos.mode == 'toball' then
        x, y = dude:distance(game.board.ball)
    else
        local tgt, dist
        tgt, dist, x, y = dude:targets( g[3], game.board.background.height / 2, 0.3)
        if tgt and  dist < 600 then
            dude:boost(dt) -- shoot
        end
    end

    if x then
        local s = normalVelocity(x, y)
        if s and s[1] == s[1] then
            dude:push(s[1]*dt*cfg.POWER, s[2]*dt*cfg.POWER)
        end
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
