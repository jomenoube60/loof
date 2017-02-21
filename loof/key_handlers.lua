mod = {}

mod.pop_one_level = function()
    if game.menu ~= nil then
        game.menu = nil
    else
        love.event.quit()
    end
end

KeyManager = objects.object:clone() -- global class

function KeyManager:new()
    local self = objects.object.new(self)
    self.keys_by_name = {}
    self.keys = {}
    self.ts = 0
    return self
end

function KeyManager:register(key, callable, min_delay, in_menu)
    local d = {name=key, fn=callable, interval=min_delay}
    self.keys_by_name[key] = d
    table.insert(self.keys, d)
end

function KeyManager:is_active(key)
    local k = self.keys_by_name[key]
    return k.ts ~= nil and k.ts + k.interval > self.ts
end

function KeyManager:manage(dt) -- continuous key handling
    if self.idle_time ~= nil and self.idle_time > os.time() then
        return
    end
    self.idle_time = nil
    self.ts = self.ts + dt
    local pressed = {}
    for i, k in ipairs(self.keys) do
        if love.keyboard.isDown(k.name) then
            pressed[k.name] = true
        end
    end
    for i, k in ipairs(self.keys) do
        if self.menu == nil or k.in_menu ~= true then
            if pressed[k.name] then
                if not self:is_active(k.name) then
                    if k.interval ~= nil then -- if interval defined, store ts
                        k.ts = self.ts
                    end
                    k.fn(dt, pressed)
                end
            end
        end
    end
end


return mod
