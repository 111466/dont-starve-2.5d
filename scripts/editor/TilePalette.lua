local TilePalette = {
    sources = {},
    sourceOrder = {},
    items = {},
    itemsBySource = {},
    itemById = {},
}

local function MakeTileId(sourceId, localId)
    return sourceId * 10000 + localId
end

function TilePalette:Reset()
    self.sources = {}
    self.sourceOrder = {}
    self.items = {}
    self.itemsBySource = {}
    self.itemById = {}
end

function TilePalette:InitFromImageEntries(imageEntries)
    self:Reset()

    for index, entry in ipairs(imageEntries or {}) do
        if entry.handle and entry.handle ~= -1 then
            local source = {
                id = index,
                key = entry.key,
                name = entry.name or ("素材" .. tostring(index)),
                path = entry.path or "",
                handle = entry.handle,
                width = entry.width or 0,
                height = entry.height or 0,
                tileSize = entry.tileSize,
                tileId = entry.tileId,
                color = entry.color or { 128, 128, 128 },
            }
            self.sources[source.id] = source
            table.insert(self.sourceOrder, source.id)
        end
    end

    self:RebuildItems()

    if #self.items == 0 then
        self:InitFallback()
    end
end

function TilePalette:RebuildItems()
    self.items = {}
    self.itemsBySource = {}
    self.itemById = {}

    for _, sourceId in ipairs(self.sourceOrder) do
        local source = self.sources[sourceId]
        local sourceItems = {}
        self.itemsBySource[sourceId] = sourceItems

        if source and source.tileSize and source.tileSize > 0 then
            local cols = math.floor(source.width / source.tileSize)
            local rows = math.floor(source.height / source.tileSize)
            if cols > 0 and rows > 0 then
                source.isAtlas = true
                source.cols = cols
                source.rows = rows

                local localId = 0
                for row = 0, rows - 1 do
                    for col = 0, cols - 1 do
                        local item = {
                            id = MakeTileId(sourceId, localId),
                            sourceId = sourceId,
                            name = string.format("%s_%d", source.name, localId),
                            color = source.color,
                            sprite = source.path,
                            handle = source.handle,
                            atlasCol = col,
                            atlasRow = row,
                            uvX = col * source.tileSize,
                            uvY = row * source.tileSize,
                            uvW = source.tileSize,
                            uvH = source.tileSize,
                            atlasWidth = source.width,
                            atlasHeight = source.height,
                            tileSize = source.tileSize,
                            isAtlas = true,
                        }
                        table.insert(self.items, item)
                        table.insert(sourceItems, item)
                        self.itemById[item.id] = item
                        localId = localId + 1
                    end
                end
            else
                source.isAtlas = false
                source.cols = 1
                source.rows = 1
            end
        else
            source.isAtlas = false
            source.cols = 1
            source.rows = 1
        end

        if not source.isAtlas then
            local item = {
                id = source.tileId ~= nil and source.tileId or MakeTileId(sourceId, 0),
                sourceId = sourceId,
                name = source.name,
                color = source.color,
                sprite = source.path,
                handle = source.handle,
                atlasCol = 0,
                atlasRow = 0,
                uvX = 0,
                uvY = 0,
                uvW = source.width,
                uvH = source.height,
                atlasWidth = source.width,
                atlasHeight = source.height,
                tileSize = 0,
                isAtlas = false,
            }
            table.insert(self.items, item)
            table.insert(sourceItems, item)
            self.itemById[item.id] = item
        end
    end
end

function TilePalette:InitFallback()
    self:Reset()
    local source = {
        id = 1,
        key = "fallback",
        name = "默认瓦片",
        path = "",
        handle = -1,
        width = 0,
        height = 0,
        color = { 128, 128, 128 },
        isAtlas = false,
        cols = 1,
        rows = 1,
    }
    self.sources[source.id] = source
    self.sourceOrder = { source.id }

    local fallback = {
        { id = 0, name = "草地", color = {85, 150, 65}, sprite = "", handle = -1, atlasCol = 0, atlasRow = 0, uvX = 0, uvY = 0, uvW = 0, uvH = 0, isAtlas = false, sourceId = source.id },
        { id = 1, name = "泥土", color = {150, 115, 75}, sprite = "", handle = -1, atlasCol = 0, atlasRow = 0, uvX = 0, uvY = 0, uvW = 0, uvH = 0, isAtlas = false, sourceId = source.id },
        { id = 2, name = "石头", color = {160, 155, 145}, sprite = "", handle = -1, atlasCol = 0, atlasRow = 0, uvX = 0, uvY = 0, uvW = 0, uvH = 0, isAtlas = false, sourceId = source.id },
    }

    self.items = fallback
    self.itemsBySource[source.id] = fallback
    for _, item in ipairs(fallback) do
        self.itemById[item.id] = item
    end
end

function TilePalette:SetSourceTileSize(sourceId, tileSize)
    local source = self.sources[sourceId]
    if not source then
        return false
    end

    if tileSize and tileSize > 0 then
        source.tileSize = tileSize
    else
        source.tileSize = nil
    end

    self:RebuildItems()
    return true
end

function TilePalette:GetSources()
    local result = {}
    for _, sourceId in ipairs(self.sourceOrder) do
        table.insert(result, self.sources[sourceId])
    end
    return result
end

function TilePalette:GetSourceById(sourceId)
    return self.sources[sourceId]
end

function TilePalette:GetItems()
    return self.items
end

function TilePalette:GetItemsForSource(sourceId)
    return self.itemsBySource[sourceId] or {}
end

function TilePalette:GetById(id)
    return self.itemById[id] or self.items[1]
end

function TilePalette:GetNextId(currentId)
    for i, item in ipairs(self.items) do
        if item.id == currentId then
            local nextIndex = i % #self.items + 1
            return self.items[nextIndex].id
        end
    end
    return self.items[1] and self.items[1].id or 0
end

function TilePalette:GetPrevId(currentId)
    for i, item in ipairs(self.items) do
        if item.id == currentId then
            local prevIndex = (i - 2 + #self.items) % #self.items + 1
            return self.items[prevIndex].id
        end
    end
    return self.items[1] and self.items[1].id or 0
end

function TilePalette:GetCount()
    return #self.items
end

function TilePalette:IsAtlasMode()
    for _, sourceId in ipairs(self.sourceOrder) do
        local source = self.sources[sourceId]
        if source and source.isAtlas then
            return true
        end
    end
    return false
end

function TilePalette:IsSourceAtlas(sourceId)
    local source = self.sources[sourceId]
    return source and source.isAtlas or false
end

function TilePalette:GetSourceAtlasInfo(sourceId)
    local source = self.sources[sourceId]
    if not source then
        return nil
    end

    return {
        handle = source.handle,
        width = source.width,
        height = source.height,
        tileSize = source.tileSize or 0,
        cols = source.cols or 1,
        rows = source.rows or 1,
    }
end

function TilePalette:GetAtlasInfo()
    local source = self.sources[self.sourceOrder[1]]
    if not source then
        return nil
    end
    return self:GetSourceAtlasInfo(source.id)
end

return TilePalette
