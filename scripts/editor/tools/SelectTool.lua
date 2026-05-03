local BaseTool = require("scripts/editor/tools/BaseTool")

local SelectTool = setmetatable({}, { __index = BaseTool })

function SelectTool:new()
    local obj = BaseTool:new("select", "select")
    obj.selectionStart = nil
    obj.selectionEnd = nil
    obj.selectedTiles = {}
    obj.clipboard = nil
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function SelectTool:OnPress(col, row, state, layerId, tileMap, GRID_COLS, GRID_ROWS)
    self.selectionStart = { col = col, row = row }
    self.selectionEnd = { col = col, row = row }
    self.selectedTiles = {}
    return true
end

function SelectTool:OnDrag(col, row, state, layerId, tileMap, GRID_COLS, GRID_ROWS)
    if self.selectionStart then
        self.selectionEnd = { col = col, row = row }
        self:UpdateSelection()
    end
    return true
end

function SelectTool:OnRelease(col, row, state, layerId, tileMap, GRID_COLS, GRID_ROWS)
    self.selectionEnd = { col = col, row = row }
    self:UpdateSelection()
    return true
end

function SelectTool:UpdateSelection()
    self.selectedTiles = {}
    if not self.selectionStart or not self.selectionEnd then return end

    local c1 = math.min(self.selectionStart.col, self.selectionEnd.col)
    local c2 = math.max(self.selectionStart.col, self.selectionEnd.col)
    local r1 = math.min(self.selectionStart.row, self.selectionEnd.row)
    local r2 = math.max(self.selectionStart.row, self.selectionEnd.row)

    for c = c1, c2 do
        for r = r1, r2 do
            table.insert(self.selectedTiles, { col = c, row = r })
        end
    end
end

function SelectTool:Copy(tileMap)
    if #self.selectedTiles == 0 then return end

    self.clipboard = {}
    local c1 = math.huge
    local r1 = math.huge

    for _, t in ipairs(self.selectedTiles) do
        c1 = math.min(c1, t.col)
        r1 = math.min(r1, t.row)
    end

    for _, t in ipairs(self.selectedTiles) do
        local relCol = t.col - c1 + 1
        local relRow = t.row - r1 + 1
        if not self.clipboard[relRow] then
            self.clipboard[relRow] = {}
        end
        self.clipboard[relRow][relCol] = tileMap[t.row][t.col]
    end
end

function SelectTool:Paste(tileMap, GRID_COLS, GRID_ROWS, startCol, startRow)
    if not self.clipboard then return end

    for r, row in pairs(self.clipboard) do
        for c, tileId in pairs(row) do
            local tc = startCol + c - 1
            local tr = startRow + r - 1
            if tc >= 1 and tc <= GRID_COLS and tr >= 1 and tr <= GRID_ROWS then
                tileMap[tr][tc] = tileId
            end
        end
    end
end

function SelectTool:ClearSelection()
    self.selectionStart = nil
    self.selectionEnd = nil
    self.selectedTiles = {}
end

return SelectTool
