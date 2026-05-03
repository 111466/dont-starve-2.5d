local TilePalette = {
    items = {},
    spriteMap = {},
    tileSize = 16,
    atlasImage = nil,
    atlasHandle = -1,
    atlasWidth = 0,
    atlasHeight = 0,
    colsInAtlas = 0,
    rowsInAtlas = 0,
}

function TilePalette:InitFromAtlas(vg, imagePath, tileSize)
    self.items = {}
    self.spriteMap = {}
    self.tileSize = tileSize or 16

    if imagePath and imagePath ~= "" then
        self.atlasHandle = nvgCreateImage(vg, imagePath, 0)
        if self.atlasHandle ~= -1 then
            self.atlasImage = imagePath
            local w, h = nvgImageSize(vg, self.atlasHandle)
            self.atlasWidth = w
            self.atlasHeight = h
            self.colsInAtlas = math.floor(w / self.tileSize)
            self.rowsInAtlas = math.floor(h / self.tileSize)

            local id = 0
            for row = 0, self.rowsInAtlas - 1 do
                for col = 0, self.colsInAtlas - 1 do
                    table.insert(self.items, {
                        id = id,
                        name = string.format("瓦片%d", id),
                        color = {128, 128, 128},
                        sprite = imagePath,
                        handle = self.atlasHandle,
                        atlasCol = col,
                        atlasRow = row,
                        uvX = col * self.tileSize,
                        uvY = row * self.tileSize,
                        uvW = self.tileSize,
                        uvH = self.tileSize,
                    })
                    id = id + 1
                end
            end

            print(string.format("[Editor] TilePalette initialized from atlas: %s, tileSize=%d, %dx%d=%d tiles",
                imagePath, self.tileSize, self.colsInAtlas, self.rowsInAtlas, #self.items))
        else
            print("[Editor] WARNING: Failed to load atlas image: " .. imagePath)
        end
    end

    if #self.items == 0 then
        self:InitFallback()
    end
end

function TilePalette:InitFromSprites(tileSprites)
    self.items = {}
    self.spriteMap = {}
    self.atlasHandle = -1
    self.atlasImage = nil

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
                atlasCol = 0,
                atlasRow = 0,
                uvX = 0,
                uvY = 0,
                uvW = 0,
                uvH = 0,
            })
            self.spriteMap[config.key] = handle
        end
    end

    if #self.items == 0 then
        self:InitFallback()
    end

    print("[Editor] TilePalette initialized with " .. #self.items .. " tiles")
end

function TilePalette:InitFallback()
    self.items = {
        { id = 0, name = "草地", color = {85, 150, 65}, sprite = "", handle = -1, atlasCol = 0, atlasRow = 0, uvX = 0, uvY = 0, uvW = 0, uvH = 0 },
        { id = 1, name = "泥土", color = {150, 115, 75}, sprite = "", handle = -1, atlasCol = 0, atlasRow = 0, uvX = 0, uvY = 0, uvW = 0, uvH = 0 },
        { id = 2, name = "石头", color = {160, 155, 145}, sprite = "", handle = -1, atlasCol = 0, atlasRow = 0, uvX = 0, uvY = 0, uvW = 0, uvH = 0 },
    }
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

function TilePalette:IsAtlasMode()
    return self.atlasHandle ~= -1 and self.atlasHandle ~= nil
end

function TilePalette:GetAtlasInfo()
    return {
        handle = self.atlasHandle,
        width = self.atlasWidth,
        height = self.atlasHeight,
        tileSize = self.tileSize,
        cols = self.colsInAtlas,
        rows = self.rowsInAtlas,
    }
end

return TilePalette
