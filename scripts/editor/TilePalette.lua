local TilePalette = {
    items = {},
    spriteMap = {},
}

function TilePalette:InitFromSprites(tileSprites)
    self.items = {}
    self.spriteMap = {}

    local tileConfigs = {
        { key = "grass1", name = "草地1", color = {85, 150, 65} },
        { key = "grass2", name = "草地2", color = {75, 140, 60} },
        { key = "dirt",   name = "泥土",  color = {150, 115, 75} },
        { key = "stone",  name = "石头",  color = {160, 155, 145} },
    }

    for i, config in ipairs(tileConfigs) do
        local handle = tileSprites[config.key]
        if handle and handle ~= -1 then
            table.insert(self.items, {
                id = i - 1,
                name = config.name,
                color = config.color,
                sprite = config.key,
                handle = handle,
            })
            self.spriteMap[config.key] = handle
        end
    end

    if #self.items == 0 then
        table.insert(self.items, { id = 0, name = "草地", color = {85, 150, 65}, sprite = "", handle = -1 })
        table.insert(self.items, { id = 1, name = "泥土", color = {150, 115, 75}, sprite = "", handle = -1 })
        table.insert(self.items, { id = 2, name = "石头", color = {160, 155, 145}, sprite = "", handle = -1 })
    end

    print("[Editor] TilePalette initialized with " .. #self.items .. " tiles")
end

function TilePalette:GetById(id)
    for _, item in ipairs(self.items) do
        if item.id == id then
            return item
        end
    end
    return self.items[1]
end

function TilePalette:GetNextId(currentId)
    for i, item in ipairs(self.items) do
        if item.id == currentId then
            local nextIndex = i % #self.items + 1
            return self.items[nextIndex].id
        end
    end
    return self.items[1].id
end

function TilePalette:GetPrevId(currentId)
    for i, item in ipairs(self.items) do
        if item.id == currentId then
            local prevIndex = (i - 2 + #self.items) % #self.items + 1
            return self.items[prevIndex].id
        end
    end
    return self.items[1].id
end

function TilePalette:GetCount()
    return #self.items
end

function TilePalette:GetItems()
    return self.items
end

return TilePalette
