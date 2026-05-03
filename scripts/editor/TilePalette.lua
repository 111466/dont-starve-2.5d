local TilePalette = {
    items = {
        { id = 0, name = "草地1", color = {85, 150, 65}, sprite = "grass1" },
        { id = 1, name = "草地2", color = {75, 140, 60}, sprite = "grass2" },
        { id = 2, name = "泥土",  color = {150, 115, 75}, sprite = "dirt" },
        { id = 3, name = "石头",  color = {160, 155, 145}, sprite = "stone" },
    }
}

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

return TilePalette
