local EditorUI = {
    paletteWidth = 160,
    toolbarHeight = 44,
    statusbarHeight = 32,
    tilePalette = nil,
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

function EditorUI:Init(vg, tileSprites, atlasPath, atlasTileSize)
    self.tilePalette = require("scripts/editor/TilePalette")
    if atlasPath and atlasPath ~= "" then
        self.tilePalette:InitFromAtlas(vg, atlasPath, atlasTileSize or 16)
    else
        self.tilePalette:InitFromSprites(tileSprites)
    end
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

    -- 工具栏背景
    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, self.logicalW, h)
    nvgFillColor(vg, nvgRGBA(35, 38, 45, 240))
    nvgFill(vg)

    -- 底部分割线
    nvgBeginPath(vg)
    nvgRect(vg, 0, h - 1, self.logicalW, 1)
    nvgFillColor(vg, nvgRGBA(80, 85, 100, 200))
    nvgFill(vg)

    -- 标题文字
    nvgFontSize(vg, 15)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 240))
    nvgText(vg, 12, h / 2, "地图编辑器", nil)

    -- 工具按钮
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

    -- 快捷键提示
    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_RIGHT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(180, 180, 180, 180))
    nvgText(vg, self.logicalW - 10, h / 2, "1-5切换工具 | F2保存 F3加载 | Ctrl+Z撤销", nil)
end

function EditorUI:DrawPalette(vg, state)
    if not state.paletteOpen then return end
    if not self.tilePalette then return end

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

    local items = self.tilePalette:GetItems()
    local isAtlas = self.tilePalette:IsAtlasMode()

    if isAtlas then
        self:DrawAtlasPalette(vg, state, x, y, w, h, items)
    else
        self:DrawSimplePalette(vg, state, x, y, w, items)
    end
end

function EditorUI:DrawAtlasPalette(vg, state, x, y, w, h, items)
    local atlasInfo = self.tilePalette:GetAtlasInfo()
    local tileDisplaySize = 32
    local padding = 6
    local cols = math.floor((w - padding * 2) / (tileDisplaySize + padding))
    if cols < 1 then cols = 1 end

    local startY = y + 34
    local totalItems = #items
    local rows = math.ceil(totalItems / cols)

    nvgFontSize(vg, 10)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(180, 180, 180, 180))
    nvgText(vg, x + padding, startY - 14,
        string.format("%dx%d 共%d个", atlasInfo.cols, atlasInfo.rows, totalItems), nil)

    for i, tile in ipairs(items) do
        local colIndex = (i - 1) % cols
        local rowIndex = math.floor((i - 1) / cols)
        local ix = x + padding + colIndex * (tileDisplaySize + padding)
        local iy = startY + rowIndex * (tileDisplaySize + padding)

        if iy + tileDisplaySize > y + h then break end

        local isSelected = (state.currentTileId == tile.id)

        if isSelected then
            nvgBeginPath(vg)
            nvgRoundedRect(vg, ix - 2, iy - 2, tileDisplaySize + 4, tileDisplaySize + 4, 3)
            nvgStrokeColor(vg, nvgRGBA(255, 200, 50, 255))
            nvgStrokeWidth(vg, 2)
            nvgStroke(vg)
        end

        if tile.handle and tile.handle ~= -1 then
            local scaleX = tileDisplaySize / tile.uvW
            local scaleY = tileDisplaySize / tile.uvH
            local imgPaint = nvgImagePattern(vg,
                ix - tile.uvX * scaleX,
                iy - tile.uvY * scaleY,
                atlasInfo.width * scaleX,
                atlasInfo.height * scaleY,
                0, tile.handle, 1.0)
            nvgBeginPath(vg)
            nvgRoundedRect(vg, ix, iy, tileDisplaySize, tileDisplaySize, 2)
            nvgFillPaint(vg, imgPaint)
            nvgFill(vg)
        else
            nvgBeginPath(vg)
            nvgRoundedRect(vg, ix, iy, tileDisplaySize, tileDisplaySize, 2)
            nvgFillColor(vg, nvgRGBA(tile.color[1], tile.color[2], tile.color[3], 255))
            nvgFill(vg)
        end

        nvgFontSize(vg, 9)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_BOTTOM)
        nvgFillColor(vg, nvgRGBA(255, 255, 255, 200))
        nvgText(vg, ix + tileDisplaySize / 2, iy + tileDisplaySize - 2, tostring(tile.id), nil)
    end
end

function EditorUI:DrawSimplePalette(vg, state, x, y, w, items)
    local itemH = 50
    local itemMargin = 6
    local startY = y + 34

    for i, tile in ipairs(items) do
        local iy = startY + (i - 1) * (itemH + itemMargin)
        local ix = x + itemMargin
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

        if tile.handle and tile.handle ~= -1 then
            local imgPaint = nvgImagePattern(vg, ix, iy, iw, ih, 0, tile.handle, 1.0)
            nvgBeginPath(vg)
            nvgRoundedRect(vg, ix, iy, iw, ih, 3)
            nvgFillPaint(vg, imgPaint)
            nvgFill(vg)
        else
            nvgBeginPath(vg)
            nvgRoundedRect(vg, ix, iy, iw, ih, 3)
            nvgFillColor(vg, nvgRGBA(tile.color[1], tile.color[2], tile.color[3], 255))
            nvgFill(vg)
        end

        nvgFontSize(vg, 11)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(255, 255, 255, 230))
        nvgText(vg, ix + iw / 2, iy + ih / 2, tile.name, nil)
    end
end

function EditorUI:DrawLayerPanel(vg, layerManager)
    local w = 140
    local x = self.logicalW - w
    local y = self.toolbarHeight + 10
    local itemH = 28
    local addButtonH = 24
    local h = layerManager:GetLayerCount() * itemH + 40 + addButtonH

    nvgBeginPath(vg)
    nvgRoundedRect(vg, x, y, w, h, 4)
    nvgFillColor(vg, nvgRGBA(30, 32, 38, 220))
    nvgFill(vg)

    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 180))
    nvgText(vg, x + w / 2, y + 6, "图层管理", nil)

    for i = 1, layerManager:GetLayerCount() do
        local layer = layerManager.layers[i]
        local ly = y + 26 + (i - 1) * itemH
        local isCurrent = (i == layerManager.currentLayer)

        if isCurrent then
            nvgBeginPath(vg)
            nvgRoundedRect(vg, x + 4, ly - 2, w - 8, itemH - 4, 3)
            nvgFillColor(vg, nvgRGBA(60, 130, 220, 150))
            nvgFill(vg)
        end

        -- 可见性按钮
        local visColor = layer.visible and nvgRGBA(100, 220, 100, 220) or nvgRGBA(150, 150, 150, 150)
        nvgBeginPath(vg)
        nvgCircle(vg, x + 14, ly + itemH / 2 - 2, 5)
        nvgFillColor(vg, visColor)
        nvgFill(vg)

        -- 可编辑性按钮
        local editColor = layer.editable and nvgRGBA(255, 200, 50, 220) or nvgRGBA(150, 150, 150, 150)
        nvgBeginPath(vg)
        nvgCircle(vg, x + 28, ly + itemH / 2 - 2, 5)
        nvgFillColor(vg, editColor)
        nvgFill(vg)

        -- 图层名称
        nvgFontSize(vg, 10)
        nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, layer.visible and nvgRGBA(255, 255, 255, 220) or nvgRGBA(150, 150, 150, 150))
        nvgText(vg, x + 40, ly + itemH / 2 - 2, layer.name, nil)
    end

    -- 添加图层按钮
    local addY = y + 26 + layerManager:GetLayerCount() * itemH + 4
    nvgBeginPath(vg)
    nvgRoundedRect(vg, x + 4, addY, w - 8, addButtonH - 4, 3)
    nvgFillColor(vg, nvgRGBA(60, 130, 220, 180))
    nvgFill(vg)

    nvgFontSize(vg, 10)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 220))
    nvgText(vg, x + w / 2, addY + addButtonH / 2 - 2, "+ 添加图层", nil)
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

    local tileName = "无"
    if self.tilePalette then
        local tile = self.tilePalette:GetById(state.currentTileId)
        if tile then tileName = tile.name end
    end

    local info = string.format("坐标: %d,%d | 世界: %.0f,%.0f | 缩放: %.1fx | 笔刷: %dx%d | 网格: %s | 当前瓦片: %s",
        state.hoverCol, state.hoverRow,
        state.hoverWorldX, state.hoverWorldY,
        camera.zoom,
        state.brushSize, state.brushSize,
        state.showGrid and "开" or "关",
        tileName)

    nvgFontSize(vg, 11)
    nvgFontFaceId(vg, -1)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 200))
    nvgText(vg, 10, y + self.statusbarHeight / 2, info, nil)
end

function EditorUI:HandlePaletteClick(x, y, state)
    if not state.paletteOpen then return false end
    if not self.tilePalette then return false end

    local px = 0
    local py = self.toolbarHeight
    local pw = self.paletteWidth
    local ph = self.logicalH - self.toolbarHeight - self.statusbarHeight

    if x < px or x > px + pw or y < py or y > py + ph then
        return false
    end

    local items = self.tilePalette:GetItems()
    local isAtlas = self.tilePalette:IsAtlasMode()

    if isAtlas then
        return self:HandleAtlasPaletteClick(x, y, px, py, pw, ph, items, state)
    else
        return self:HandleSimplePaletteClick(x, y, px, py, items, state)
    end
end

function EditorUI:HandleAtlasPaletteClick(x, y, px, py, pw, ph, items, state)
    local tileDisplaySize = 32
    local padding = 6
    local cols = math.floor((pw - padding * 2) / (tileDisplaySize + padding))
    if cols < 1 then cols = 1 end

    local startY = py + 34

    for i, tile in ipairs(items) do
        local colIndex = (i - 1) % cols
        local rowIndex = math.floor((i - 1) / cols)
        local ix = px + padding + colIndex * (tileDisplaySize + padding)
        local iy = startY + rowIndex * (tileDisplaySize + padding)

        if iy + tileDisplaySize > py + ph then break end

        if x >= ix and x <= ix + tileDisplaySize and y >= iy and y <= iy + tileDisplaySize then
            state.currentTileId = tile.id
            print(string.format("[Editor] Selected tile id=%d (%s)", tile.id, tile.name))
            return true
        end
    end

    return true
end

function EditorUI:HandleSimplePaletteClick(x, y, px, py, items, state)
    local itemH = 50
    local itemMargin = 6
    local startY = py + 34

    for i, tile in ipairs(items) do
        local iy = startY + (i - 1) * (itemH + itemMargin)
        local ix = px + itemMargin
        local iw = self.paletteWidth - itemMargin * 2
        local ih = itemH

        if x >= ix and x <= ix + iw and y >= iy and y <= iy + ih then
            state.currentTileId = tile.id
            print(string.format("[Editor] Selected tile id=%d (%s)", tile.id, tile.name))
            return true
        end
    end

    return true
end

return EditorUI
