local function manage(dude)
    dude:push( love.math.random(-cfg.POWER, cfg.POWER), love.math.random(-cfg.POWER, cfg.POWER) )
end

return {
    manage = manage
}
