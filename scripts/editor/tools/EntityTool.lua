local BaseTool = require("scripts/editor/tools/BaseTool")

local EntityTool = setmetatable({}, { __index = BaseTool })

function EntityTool:new()
    local obj = BaseTool:new("entity", "entity")
    obj.selectedEntityIndex = nil
    obj.entityType = 1
    obj.isDragging = false
    obj.dragOffsetX = 0
    obj.dragOffsetY = 0
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function EntityTool:OnPress(col, row, state, tileMap, GRID_COLS, GRID_ROWS, decorations, camera, logicalW, logicalH)
    local mx, my = input:GetMousePosition()
    local wx, wy = camera:ScreenToWorld(mx, my, logicalW, logicalH, 0.55)

    local found = false
    for i = #decorations, 1, -1 do
        local dec = decorations[i]
        local dx = dec.x - wx
        local dy = dec.y - wy
        if math.sqrt(dx * dx + dy * dy) < 30 then
            self.selectedEntityIndex = i
            self.isDragging = true
            self.dragOffsetX = dx
            self.dragOffsetY = dy
            found = true
            break
        end
    end

    if not found then
        self.selectedEntityIndex = nil
        self:PlaceEntity(wx, wy, decorations)
    end

    return true
end

function EntityTool:OnDrag(col, row, state, tileMap, GRID_COLS, GRID_ROWS, decorations, camera, logicalW, logicalH)
    if self.isDragging and self.selectedEntityIndex then
        local mx, my = input:GetMousePosition()
        local wx, wy = camera:ScreenToWorld(mx, my, logicalW, logicalH, 0.55)
        local dec = decorations[self.selectedEntityIndex]
        if dec then
            dec.x = wx - self.dragOffsetX
            dec.y = wy - self.dragOffsetY
        end
        return true
    end
    return false
end

function EntityTool:OnRelease(col, row, state, tileMap, GRID_COLS, GRID_ROWS, decorations)
    self.isDragging = false
    return true
end

function EntityTool:PlaceEntity(wx, wy, decorations)
    table.insert(decorations, {
        x = wx,
        y = wy,
        type = self.entityType,
        scale = 0.7 + math.random() * 0.6,
        swayPhase = math.random() * math.pi * 2,
    })
end

function EntityTool:DeleteSelected(decorations)
    if self.selectedEntityIndex then
        table.remove(decorations, self.selectedEntityIndex)
        self.selectedEntityIndex = nil
        return true
    end
    return false
end

function EntityTool:CycleEntityType()
    self.entityType = self.entityType % 4 + 1
end

return EntityTool
