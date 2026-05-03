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
    local wx, wy = camera:ScreenToWorld(mx, my, logicalW, logicalH, ISO_Y_SCALE)

    self.hoverWorldX = wx
    self.hoverWorldY = wy
    self.hoverCol = math.floor(wx / TILE_SIZE) + 1
    self.hoverRow = math.floor(wy / TILE_SIZE) + 1

    if self.hoverCol < 1 then self.hoverCol = 1 end
    if self.hoverCol > GRID_COLS then self.hoverCol = GRID_COLS end
    if self.hoverRow < 1 then self.hoverRow = 1 end
    if self.hoverRow > GRID_ROWS then self.hoverRow = GRID_ROWS end
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

function EditorState:HandleKeyPress(key)
    if key == KEY_Q then
        self.currentTileId = self.currentTileId - 1
        if self.currentTileId < 0 then self.currentTileId = 3 end
        return true
    elseif key == KEY_E then
        self.currentTileId = self.currentTileId + 1
        if self.currentTileId > 3 then self.currentTileId = 0 end
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
