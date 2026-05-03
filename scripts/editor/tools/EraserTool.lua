local BaseTool = require("scripts/editor/tools/BaseTool")

local EraserTool = setmetatable({}, { __index = BaseTool })

function EraserTool:new()
    local obj = BaseTool:new("eraser", "eraser")
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function EraserTool:OnPress(col, row, state, layerId, tileMap, GRID_COLS, GRID_ROWS)
    self:Erase(col, row, state, layerId, tileMap, GRID_COLS, GRID_ROWS)
    return true
end

function EraserTool:OnDrag(col, row, state, layerId, tileMap, GRID_COLS, GRID_ROWS)
    self:Erase(col, row, state, layerId, tileMap, GRID_COLS, GRID_ROWS)
    return true
end

function EraserTool:Erase(col, row, state, layerId, tileMap, GRID_COLS, GRID_ROWS)
    local size = state.brushSize
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

return EraserTool
