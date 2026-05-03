local BaseTool = {
    name = "base",
    icon = "",
    cursor = "crosshair",
}

function BaseTool:new(name, icon)
    local obj = { name = name or "base", icon = icon or "", cursor = "crosshair" }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function BaseTool:OnActivate() end
function BaseTool:OnDeactivate() end
function BaseTool:OnPress(col, row, tileMap, GRID_COLS, GRID_ROWS) return false end
function BaseTool:OnDrag(col, row, tileMap, GRID_COLS, GRID_ROWS) return false end
function BaseTool:OnRelease(col, row, tileMap, GRID_COLS, GRID_ROWS) return false end

return BaseTool
