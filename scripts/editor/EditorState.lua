local EditorState = {
    currentTileId = 0,
    brushSize = 1,
    hoverCol = 0,
    hoverRow = 0,
    hoverWorldX = 0,
    hoverWorldY = 0,
    showGrid = true,
    paletteOpen = true,
    currentTool = "brush",
    isDragging = false,
    dragButton = 0,
}

function EditorState:new()
    local obj = {}
    for k, v in pairs(self) do
        obj[k] = v
    end
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function EditorState:Update(mx, my, camera, logicalW, logicalH, TILE_SIZE, ISO_Y_SCALE, GRID_COLS, GRID_ROWS)
    -- 使用改进的等距投影坐标转换
    local wx, wy = camera:ScreenToWorldIso(mx, my, logicalW, logicalH, TILE_SIZE, ISO_Y_SCALE)

    self.hoverWorldX = wx
    self.hoverWorldY = wy

    -- 等距投影坐标转换: 将世界坐标转换为网格坐标
    -- 考虑 TILE_SIZE 和 ISO_Y_SCALE 的影响
    local col = math.floor(wx / TILE_SIZE) + 1
    local row = math.floor(wy / TILE_SIZE) + 1

    -- 边界限制
    if col < 1 then col = 1 end
    if col > GRID_COLS then col = GRID_COLS end
    if row < 1 then row = 1 end
    if row > GRID_ROWS then row = GRID_ROWS end

    self.hoverCol = col
    self.hoverRow = row
end

function EditorState:HandleMousePress(x, y, button, tileMap, GRID_COLS, GRID_ROWS)
    self.isDragging = true
    self.dragButton = button

    if button == 1 then
        if self.currentTool == "brush" then
            self:Paint(tileMap, self.hoverCol, self.hoverRow, GRID_COLS, GRID_ROWS)
            return true
        elseif self.currentTool == "eraser" then
            self:Erase(tileMap, self.hoverCol, self.hoverRow, GRID_COLS, GRID_ROWS)
            return true
        end
    elseif button == 2 then
        self:Erase(tileMap, self.hoverCol, self.hoverRow, GRID_COLS, GRID_ROWS)
        return true
    end

    return false
end

function EditorState:HandleMouseDrag(x, y, button, tileMap, GRID_COLS, GRID_ROWS)
    if not self.isDragging then return false end

    if button == 1 then
        if self.currentTool == "brush" then
            self:Paint(tileMap, self.hoverCol, self.hoverRow, GRID_COLS, GRID_ROWS)
            return true
        elseif self.currentTool == "eraser" then
            self:Erase(tileMap, self.hoverCol, self.hoverRow, GRID_COLS, GRID_ROWS)
            return true
        end
    elseif button == 2 then
        self:Erase(tileMap, self.hoverCol, self.hoverRow, GRID_COLS, GRID_ROWS)
        return true
    end

    return false
end

function EditorState:Paint(tileMap, col, row, GRID_COLS, GRID_ROWS)
    local size = self.brushSize
    local half = math.floor(size / 2)

    for dc = -half, half do
        for dr = -half, half do
            local tc = col + dc
            local tr = row + dr
            if tc >= 1 and tc <= GRID_COLS and tr >= 1 and tr <= GRID_ROWS then
                tileMap[tr][tc] = self.currentTileId
            end
        end
    end
end

function EditorState:Erase(tileMap, col, row, GRID_COLS, GRID_ROWS)
    local size = self.brushSize
    local half = math.floor(size / 2)

    for dc = -half, half do
        for dr = -half, half do
            local tc = col + dc
            local tr = row + dr
            if tc >= 1 and tc <= GRID_COLS and tr >= 1 and tr <= GRID_ROWS then
                tileMap[tr][tc] = 0
            end
        end
    end
end

function EditorState:HandleKeyPress(key, tilePalette)
    if key == KEY_Q then
        if tilePalette then
            self.currentTileId = tilePalette:GetPrevId(self.currentTileId)
        else
            self.currentTileId = self.currentTileId - 1
            if self.currentTileId < 0 then self.currentTileId = 3 end
        end
        return true
    elseif key == KEY_E then
        if tilePalette then
            self.currentTileId = tilePalette:GetNextId(self.currentTileId)
        else
            self.currentTileId = self.currentTileId + 1
            if self.currentTileId > 3 then self.currentTileId = 0 end
        end
        return true
    elseif key == KEY_G then
        self.showGrid = not self.showGrid
        return true
    elseif key == KEY_B then
        if self.currentTool == "brush" then
            self.currentTool = "eraser"
        else
            self.currentTool = "brush"
        end
        return true
    elseif key == KEY_KP_PLUS or key == KEY_EQUALS then
        self.brushSize = math.min(5, self.brushSize + 1)
        return true
    elseif key == KEY_KP_MINUS or key == KEY_MINUS then
        self.brushSize = math.max(1, self.brushSize - 1)
        return true
    end
    return false
end

return EditorState
