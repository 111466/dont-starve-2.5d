local EditorUI = {
    paletteWidth = 140,
    toolbarHeight = 44,
    statusbarHeight = 32,
}

local TILE_PALETTE = {
    { id = 0, name = "草地1", color = {85, 150, 65} },
    { id = 1, name = "泥土", color = {150, 115, 75} },
    { id = 2, name = "石头", color = {160, 155, 145} },
    { id = 3, name = "草地2", color = {75, 140, 60} },
}

local TOOL_ICONS = {
    brush = "画笔",
    eraser = "橡皮",
    fill = "填充",
    entity = "实体",
    select = "选择",
}

function EditorUI:new()
    local obj = {}
    for k, v in pairs(self) do
        obj[k] = v
    end
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function EditorUI:Render(vg, logicalW, logicalH, state, camera, layerManager)
    self.logicalW = logicalW
    self.logicalH = logicalH

    self:DrawToolbar(vg, state, layerManager)
    self:DrawPalette(vg, state)
    self:DrawLayerPanel(vg, layerManager)
    self:DrawStatusBar(vg, state, camera)
end

function EditorUI:DrawToolbar(vg, state, layerManager)
    local h = self.toolbarHeight

    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, self.logicalW, h)
    nvgFillColor(vg, nvgRGBA(35, 38, 45, 240))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgRect(vg, 0, h - 1, self.logicalW, 1)
    nvgFillColor(vg, nvgRGBA(80, 85, 100, 200))
    nvgFill(vg)

    nvgFontSize(vg, 15)
    nvgFontFaceId(vg, -1)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 240))
    nvgText(vg, 12, h / 2, "地图编辑器", nil)

    local toolX = 110
    for toolName, toolLabel in pairs(TOOL_ICONS) do
        local isActive = (state.currentTool == toolName)
        local tw = 50

        if isActive then
            nvgBeginPath(vg)
            nvgRoundedRect(vg, toolX - 4, 6, tw, h - 12, 4)
            nvgFillColor(vg, nvgRGBA(60, 130, 220, 200))
            nvgFill(vg)
        end

        nvgFontSize(vg, 12)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, isActive and nvgRGBA(255, 255, 255, 255) or nvgRGBA(200, 200, 200, 200))
        nvgText(vg, toolX + tw / 2, h / 2, toolLabel, nil)

        toolX = toolX + tw + 6
    end

    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_RIGHT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(180, 180, 180, 180))
    nvgText(vg, self.logicalW - 10, h / 2, "1-5切换工具 | F2保存 F3加载 | Ctrl+Z撤销", nil)
end

function EditorUI:DrawPalette(vg, state)
    if not state.paletteOpen then return end

    local x = 0
    local y = self.toolbarHeight
    local w = self.paletteWidth
    local h = self.logicalH - self.toolbarHeight - self.statusbarHeight

    nvgBeginPath(vg)
    nvgRect(vg, x, y, w, h)
    nvgFillColor(vg, nvgRGBA(30, 32, 38, 235))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgRect(vg, x + w - 1, y, 1, h)
    nvgFillColor(vg, nvgRGBA(60, 65, 75, 200))
    nvgFill(vg)

    nvgFontSize(vg, 12)
    nvgFontFaceId(vg, -1)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 200))
    nvgText(vg, w / 2, y + 10, "瓦片调色板", nil)

    local itemH = 44
    local itemMargin = 6
    local startY = y + 34

    for i, tile in ipairs(TILE_PALETTE) do
        local iy = startY + (i - 1) * (itemH + itemMargin)
        local ix = itemMargin
        local iw = w - itemMargin * 2
        local ih = itemH

        local isSelected = (state.currentTileId == tile.id)

        if isSelected then
            nvgBeginPath(vg)
            nvgRoundedRect(vg, ix - 2, iy - 2, iw + 4, ih + 4, 4)
            nvgStrokeColor(vg, nvgRGBA(255, 200, 50, 255))
            nvgStrokeWidth(vg, 2)
            nvgStroke(vg)
        end

        nvgBeginPath(vg)
        nvgRoundedRect(vg, ix, iy, iw, ih, 3)
        nvgFillColor(vg, nvgRGBA(tile.color[1], tile.color[2], tile.color[3], 255))
        nvgFill(vg)

        nvgFontSize(vg, 11)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(255, 255, 255, 230))
        nvgText(vg, ix + iw / 2, iy + ih / 2, tile.name, nil)
    end
end

function EditorUI:DrawLayerPanel(vg, layerManager)
    local w = 100
    local x = self.logicalW - w
    local y = self.toolbarHeight + 10
    local h = layerManager:GetLayerCount() * 28 + 30

    nvgBeginPath(vg)
    nvgRoundedRect(vg, x, y, w, h, 4)
    nvgFillColor(vg, nvgRGBA(30, 32, 38, 220))
    nvgFill(vg)

    nvgFontSize(vg, 11)
    nvgFontFaceId(vg, -1)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 180))
    nvgText(vg, x + w / 2, y + 6, "图层", nil)

    for i = 1, layerManager:GetLayerCount() do
        local layer = layerManager.layers[i]
        local ly = y + 24 + (i - 1) * 26
        local isCurrent = (i == layerManager.currentLayer)

        if isCurrent then
            nvgBeginPath(vg)
            nvgRoundedRect(vg, x + 4, ly - 2, w - 8, 22, 3)
            nvgFillColor(vg, nvgRGBA(60, 130, 220, 150))
            nvgFill(vg)
        end

        nvgFontSize(vg, 10)
        nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, layer.visible and nvgRGBA(255, 255, 255, 220) or nvgRGBA(150, 150, 150, 150))
        nvgText(vg, x + 10, ly + 9, (layer.visible and "[v] " or "[ ] ") .. layer.name, nil)
    end
end

function EditorUI:DrawStatusBar(vg, state, camera)
    local y = self.logicalH - self.statusbarHeight

    nvgBeginPath(vg)
    nvgRect(vg, 0, y, self.logicalW, self.statusbarHeight)
    nvgFillColor(vg, nvgRGBA(35, 38, 45, 240))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgRect(vg, 0, y, self.logicalW, 1)
    nvgFillColor(vg, nvgRGBA(80, 85, 100, 200))
    nvgFill(vg)

    local info = string.format("坐标: %d,%d | 世界: %.0f,%.0f | 缩放: %.1fx | 笔刷: %dx%d | 网格: %s",
        state.hoverCol, state.hoverRow,
        state.hoverWorldX, state.hoverWorldY,
        camera.zoom,
        state.brushSize, state.brushSize,
        state.showGrid and "开" or "关")

    nvgFontSize(vg, 11)
    nvgFontFaceId(vg, -1)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 200))
    nvgText(vg, 10, y + self.statusbarHeight / 2, info, nil)
end

return EditorUI
