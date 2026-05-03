local BaseTool = require("scripts/editor/tools/BaseTool")

local BrushTool = setmetatable({}, { __index = BaseTool })

function BrushTool:new()
    local obj = BaseTool:new("brush", "brush")
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function BrushTool:OnPress(col, row, state, tileMap, GRID_COLS, GRID_ROWS)
    self:Paint(col, row, state, tileMap, GRID_COLS, GRID_ROWS)
    return true
end

function BrushTool:OnDrag(col, row, state, tileMap, GRID_COLS, GRID_ROWS)
    self:Paint(col, row, state, tileMap, GRID_COLS, GRID_ROWS)
    return true
end

function BrushTool:Paint(col, row, state, tileMap, GRID_COLS, GRID_ROWS)
    local tileId = state.currentTileId
    local size = state.brushSize
    local half = math.floor(size / 2)

    for dc = -half, half do
        for dr = -half, half do
            local tc = col + dc
            local tr = row + dr
            if tc >= 1 and tc <= GRID_COLS and tr >= 1 and tr <= GRID_ROWS then
                tileMap[tr][tc] = tileId
            end
        end
    end
end

return BrushTool
