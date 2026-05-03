local EditorUI = {
    paletteWidth = 220,
    toolbarHeight = 44,
    statusbarHeight = 32,
    tilePalette = nil,
    vg = nil,
    imageEntries = nil,
    selectedSourceId = nil,
    paletteExpanded = false,
    atlasConfigOpen = false,
    atlasTileSizeOptions = { 8, 16, 24, 32 },
}

local TOOL_ORDER = { "brush", "eraser", "fill", "entity", "select" }

local TOOL_ICONS = {
    brush = "画笔",
    eraser = "橡皮",
    fill = "填充",
    entity = "实体",
    select = "选择",
}

local function CloneValue(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for k, v in pairs(value) do
        result[k] = CloneValue(v)
    end
    return result
end

function EditorUI:new()
    local obj = {}
    for k, v in pairs(self) do
        obj[k] = CloneValue(v)
    end
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function EditorUI:Init(vg, imageEntries)
    self.vg = vg
    self.imageEntries = imageEntries or {}
    self.tilePalette = require("scripts/editor/TilePalette")
    self:ReloadPalette()
end

function EditorUI:ReloadPalette()
    self.tilePalette:InitFromImageEntries(self.imageEntries)
    local sources = self.tilePalette:GetSources()
    if not self.selectedSourceId and #sources > 0 then
        self.selectedSourceId = sources[1].id
    end
end

function EditorUI:SetSourceTileSize(sourceId, tileSize)
    if not self.tilePalette:SetSourceTileSize(sourceId, tileSize) then
        return false
    end
    self.atlasConfigOpen = false
    self.paletteExpanded = tileSize ~= nil
    return true
end

function EditorUI:IsPointInRect(px, py, rect)
    return px >= rect.x and px <= rect.x + rect.w and py >= rect.y and py <= rect.y + rect.h
end

function EditorUI:IsPointInCircle(px, py, cx, cy, radius)
    local dx = px - cx
    local dy = py - cy
    return dx * dx + dy * dy <= radius * radius
end

function EditorUI:GetFittedImageRect(container, imageW, imageH, padding)
    padding = padding or 0
    local innerW = math.max(1, container.w - padding * 2)
    local innerH = math.max(1, container.h - padding * 2)
    local scale = math.min(innerW / imageW, innerH / imageH)
    local drawW = imageW * scale
    local drawH = imageH * scale
    return {
        x = container.x + (container.w - drawW) / 2,
        y = container.y + (container.h - drawH) / 2,
        w = drawW,
        h = drawH,
    }
end

function EditorUI:GetPaletteBounds()
    return {
        x = 0,
        y = self.toolbarHeight,
        w = self.paletteWidth,
        h = self.logicalH - self.toolbarHeight - self.statusbarHeight,
    }
end

function EditorUI:GetPaletteLayout(isAtlas)
    local bounds = self:GetPaletteBounds()
    local margin = 10
    local headerY = bounds.y + 10
    local listItemH = 44
    local listGap = 6
    local maxListH = 176
    local sourceCount = #(self.tilePalette and self.tilePalette:GetSources() or {})
    local listH = math.min(maxListH, math.max(listItemH, sourceCount * (listItemH + listGap)))
    local listY = bounds.y + 30
    local cardY = listY + listH + 10
    local cardH = isAtlas and 192 or 160

    local layout = {
        bounds = bounds,
        margin = margin,
        headerY = headerY,
        sourceList = {
            x = bounds.x + margin,
            y = listY,
            w = bounds.w - margin * 2,
            h = listH,
            itemH = listItemH,
            gap = listGap,
        },
        card = {
            x = bounds.x + margin,
            y = cardY,
            w = bounds.w - margin * 2,
            h = cardH,
        },
    }

    layout.preview = {
        x = layout.card.x + 8,
        y = layout.card.y + 30,
        w = layout.card.w - 16,
        h = isAtlas and 100 or 78,
    }
    layout.configButton = {
        x = layout.card.x + layout.card.w - 54,
        y = layout.card.y + 6,
        w = 46,
        h = 20,
    }
    layout.popup = {
        x = layout.card.x + layout.card.w - 96,
        y = layout.configButton.y + layout.configButton.h + 4,
        w = 88,
        h = (#self.atlasTileSizeOptions + 1) * 24 + 8,
    }
    layout.grid = {
        x = bounds.x + margin,
        y = layout.card.y + layout.card.h + 10,
        w = bounds.w - margin * 2,
        h = math.max(0, bounds.y + bounds.h - (layout.card.y + layout.card.h + 18)),
    }

    return layout
end

function EditorUI:GetSelectedSource(state)
    local tile = self.tilePalette and self.tilePalette:GetById(state.currentTileId) or nil
    if tile and tile.sourceId then
        self.selectedSourceId = tile.sourceId
    end

    if self.selectedSourceId then
        local source = self.tilePalette:GetSourceById(self.selectedSourceId)
        if source then
            return source
        end
    end

    local sources = self.tilePalette and self.tilePalette:GetSources() or {}
    if #sources > 0 then
        self.selectedSourceId = sources[1].id
        return sources[1]
    end

    return nil
end

function EditorUI:GetLayerPanelLayout(layerManager)
    local w = 180
    local x = self.logicalW - w - 10
    local y = self.toolbarHeight + 10
    local padding = 8
    local titleH = 24
    local itemH = 32
    local addButtonH = 28

    local layout = {
        x = x,
        y = y,
        w = w,
        h = padding + titleH + layerManager:GetLayerCount() * itemH + addButtonH + padding,
        padding = padding,
        titleH = titleH,
        itemH = itemH,
        addButtonH = addButtonH,
        items = {},
    }

    for i = 1, layerManager:GetLayerCount() do
        local itemY = y + padding + titleH + (i - 1) * itemH
        layout.items[i] = {
            row = { x = x + padding, y = itemY, w = w - padding * 2, h = itemH - 4 },
            visibleCircle = { x = x + padding + 10, y = itemY + 12, r = 6 },
            editableCircle = { x = x + padding + 30, y = itemY + 12, r = 6 },
            textX = x + padding + 44,
            textY = itemY + 12,
        }
    end

    layout.addButton = {
        x = x + padding,
        y = y + padding + titleH + layerManager:GetLayerCount() * itemH + 4,
        w = w - padding * 2,
        h = addButtonH - 4,
    }

    return layout
end

function EditorUI:EnsureValidSelectedTile(state)
    local items = self.tilePalette and self.tilePalette:GetItems() or nil
    if not items or #items == 0 then
        state.currentTileId = 0
        return
    end

    for _, tile in ipairs(items) do
        if tile.id == state.currentTileId then
            return
        end
    end

    state.currentTileId = items[1].id
end

function EditorUI:Render(vg, logicalW, logicalH, state, camera, layerManager)
    self.logicalW = logicalW
    self.logicalH = logicalH
    self:EnsureValidSelectedTile(state)

    self:DrawToolbar(vg, state)
    self:DrawPalette(vg, state)
    self:DrawLayerPanel(vg, layerManager)
    self:DrawStatusBar(vg, state, camera)
end

function EditorUI:DrawToolbar(vg, state)
    local h = self.toolbarHeight

    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, self.logicalW, h)
    nvgFillColor(vg, nvgRGBA(35, 38, 45, 240))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgRect(vg, 0, h - 1, self.logicalW, 1)
    nvgFillColor(vg, nvgRGBA(80, 85, 100, 200))
    nvgFill(vg)

    nvgFontFaceId(vg, -1)
    nvgFontSize(vg, 15)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 240))
    nvgText(vg, 12, h / 2, "地图编辑器", nil)

    local toolX = 110
    for _, toolName in ipairs(TOOL_ORDER) do
        local toolLabel = TOOL_ICONS[toolName]
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
    if not self.tilePalette then return end

    local currentSource = self:GetSelectedSource(state)
    local isAtlas = currentSource and self.tilePalette:IsSourceAtlas(currentSource.id) or false
    local layout = self:GetPaletteLayout(isAtlas)
    local bounds = layout.bounds
    local sources = self.tilePalette:GetSources()

    nvgBeginPath(vg)
    nvgRect(vg, bounds.x, bounds.y, bounds.w, bounds.h)
    nvgFillColor(vg, nvgRGBA(30, 32, 38, 235))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgRect(vg, bounds.x + bounds.w - 1, bounds.y, 1, bounds.h)
    nvgFillColor(vg, nvgRGBA(60, 65, 75, 200))
    nvgFill(vg)

    nvgFontFaceId(vg, -1)
    nvgFontSize(vg, 12)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 200))
    nvgText(vg, bounds.x + bounds.w / 2, layout.headerY, "瓦片素材", nil)

    self:DrawSourceList(vg, layout.sourceList, sources)

    if currentSource then
        self:DrawMaterialDetailCard(vg, state, layout, currentSource)
    end
end

function EditorUI:DrawSourceList(vg, listRect, sources)
    nvgBeginPath(vg)
    nvgRoundedRect(vg, listRect.x, listRect.y, listRect.w, listRect.h, 6)
    nvgFillColor(vg, nvgRGBA(42, 45, 52, 225))
    nvgFill(vg)

    nvgFontFaceId(vg, -1)
    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(210, 210, 210, 220))
    nvgText(vg, listRect.x + 8, listRect.y + 6, "全部图片", nil)

    for index, source in ipairs(sources) do
        local iy = listRect.y + 24 + (index - 1) * (listRect.itemH + listRect.gap)
        local itemRect = { x = listRect.x + 6, y = iy, w = listRect.w - 12, h = listRect.itemH }
        local isSelected = source.id == self.selectedSourceId

        if itemRect.y + itemRect.h > listRect.y + listRect.h then
            break
        end

        nvgBeginPath(vg)
        nvgRoundedRect(vg, itemRect.x, itemRect.y, itemRect.w, itemRect.h, 5)
        nvgFillColor(vg, isSelected and nvgRGBA(60, 130, 220, 160) or nvgRGBA(28, 30, 36, 220))
        nvgFill(vg)

        local thumbRect = { x = itemRect.x + 6, y = itemRect.y + 6, w = 44, h = itemRect.h - 12 }
        self:DrawPreviewFrame(vg, thumbRect)
        self:DrawSourceImage(vg, source, thumbRect, 2)

        nvgFontSize(vg, 10)
        nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
        nvgFillColor(vg, nvgRGBA(255, 255, 255, 230))
        nvgText(vg, itemRect.x + 58, itemRect.y + 8, source.name, nil)

        nvgFillColor(vg, nvgRGBA(190, 190, 190, 200))
        local desc = source.tileSize and string.format("图集 %dx%d", source.tileSize, source.tileSize) or "原图"
        nvgText(vg, itemRect.x + 58, itemRect.y + 23, desc, nil)
    end
end

function EditorUI:DrawCardBackground(vg, rect)
    nvgBeginPath(vg)
    nvgRoundedRect(vg, rect.x, rect.y, rect.w, rect.h, 6)
    nvgFillColor(vg, nvgRGBA(42, 45, 52, 235))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgRoundedRect(vg, rect.x, rect.y, rect.w, rect.h, 6)
    nvgStrokeColor(vg, nvgRGBA(80, 85, 100, 170))
    nvgStrokeWidth(vg, 1)
    nvgStroke(vg)
end

function EditorUI:DrawPreviewFrame(vg, rect)
    nvgBeginPath(vg)
    nvgRoundedRect(vg, rect.x, rect.y, rect.w, rect.h, 5)
    nvgFillColor(vg, nvgRGBA(20, 22, 28, 235))
    nvgFill(vg)
end

function EditorUI:DrawSourceImage(vg, source, rect, padding)
    if not source or not source.handle or source.handle == -1 or source.width <= 0 or source.height <= 0 then
        return
    end
    local imageRect = self:GetFittedImageRect(rect, source.width, source.height, padding or 0)
    local imgPaint = nvgImagePattern(vg, imageRect.x, imageRect.y, imageRect.w, imageRect.h, 0, source.handle, 1.0)
    nvgBeginPath(vg)
    nvgRoundedRect(vg, imageRect.x, imageRect.y, imageRect.w, imageRect.h, 3)
    nvgFillPaint(vg, imgPaint)
    nvgFill(vg)
end

function EditorUI:DrawMaterialDetailCard(vg, state, layout, source)
    local card = layout.card
    local preview = layout.preview
    local isAtlas = self.tilePalette:IsSourceAtlas(source.id)

    self:DrawCardBackground(vg, card)

    nvgFontFaceId(vg, -1)
    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 210))
    nvgText(vg, card.x + 8, card.y + 8, source.name, nil)

    nvgBeginPath(vg)
    nvgRoundedRect(vg, layout.configButton.x, layout.configButton.y, layout.configButton.w, layout.configButton.h, 10)
    nvgFillColor(vg, nvgRGBA(72, 78, 90, 230))
    nvgFill(vg)
    nvgFontSize(vg, 10)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 220))
    nvgText(vg, layout.configButton.x + layout.configButton.w / 2, layout.configButton.y + layout.configButton.h / 2, "尺寸", nil)

    self:DrawPreviewFrame(vg, preview)
    self:DrawSourceImage(vg, source, preview, 6)

    nvgFontSize(vg, 10)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(190, 190, 190, 200))

    if isAtlas then
        local atlasInfo = self.tilePalette:GetSourceAtlasInfo(source.id)
        nvgText(vg, card.x + 8, preview.y + preview.h + 8,
            string.format("当前切片: %dx%d | %dx%d", atlasInfo.tileSize, atlasInfo.tileSize, atlasInfo.cols, atlasInfo.rows), nil)
        nvgText(vg, card.x + 8, preview.y + preview.h + 24,
            self.paletteExpanded and "点击预览可收起调色板" or "点击预览可展开调色板", nil)
    else
        nvgText(vg, card.x + 8, preview.y + preview.h + 8,
            string.format("原图尺寸: %dx%d", source.width, source.height), nil)
        nvgText(vg, card.x + 8, preview.y + preview.h + 24,
            "右上角配置尺寸后按图集切片", nil)
    end

    if self.atlasConfigOpen then
        self:DrawAtlasConfigPopup(vg, layout, source)
    end

    if isAtlas and self.paletteExpanded then
        local items = self.tilePalette:GetItemsForSource(source.id)
        self:DrawAtlasPaletteGrid(vg, state, layout.grid, items)
    end
end

function EditorUI:DrawAtlasConfigPopup(vg, layout, source)
    local popup = layout.popup

    nvgBeginPath(vg)
    nvgRoundedRect(vg, popup.x, popup.y, popup.w, popup.h, 6)
    nvgFillColor(vg, nvgRGBA(20, 22, 28, 245))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgRoundedRect(vg, popup.x, popup.y, popup.w, popup.h, 6)
    nvgStrokeColor(vg, nvgRGBA(90, 95, 110, 200))
    nvgStrokeWidth(vg, 1)
    nvgStroke(vg)

    nvgFontFaceId(vg, -1)
    nvgFontSize(vg, 10)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)

    local isOriginal = not source.tileSize
    if isOriginal then
        nvgBeginPath(vg)
        nvgRoundedRect(vg, popup.x + 4, popup.y + 4, popup.w - 8, 20, 4)
        nvgFillColor(vg, nvgRGBA(60, 130, 220, 180))
        nvgFill(vg)
    end
    nvgFillColor(vg, nvgRGBA(255, 255, 255, isOriginal and 255 or 210))
    nvgText(vg, popup.x + popup.w / 2, popup.y + 14, "原图", nil)

    for index, tileSize in ipairs(self.atlasTileSizeOptions) do
        local optionY = popup.y + 28 + (index - 1) * 24
        local isActive = (tileSize == source.tileSize)

        if isActive then
            nvgBeginPath(vg)
            nvgRoundedRect(vg, popup.x + 4, optionY, popup.w - 8, 20, 4)
            nvgFillColor(vg, nvgRGBA(60, 130, 220, 180))
            nvgFill(vg)
        end

        nvgFillColor(vg, nvgRGBA(255, 255, 255, isActive and 255 or 210))
        nvgText(vg, popup.x + popup.w / 2, optionY + 10, string.format("%dx%d", tileSize, tileSize), nil)
    end
end

function EditorUI:DrawAtlasPaletteGrid(vg, state, gridRect, items)
    nvgFontFaceId(vg, -1)
    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 200))
    nvgText(vg, gridRect.x, gridRect.y, "瓦片调色板", nil)
    local tileDisplaySize = 32
    local padding = 6
    local startY = gridRect.y + 20
    local cols = math.floor((gridRect.w - padding) / (tileDisplaySize + padding))
    if cols < 1 then cols = 1 end

    for i, tile in ipairs(items) do
        local colIndex = (i - 1) % cols
        local rowIndex = math.floor((i - 1) / cols)
        local ix = gridRect.x + colIndex * (tileDisplaySize + padding)
        local iy = startY + rowIndex * (tileDisplaySize + padding)

        if iy + tileDisplaySize > gridRect.y + gridRect.h then
            break
        end

        local isSelected = (state.currentTileId == tile.id)
        if isSelected then
            nvgBeginPath(vg)
            nvgRoundedRect(vg, ix - 2, iy - 2, tileDisplaySize + 4, tileDisplaySize + 4, 4)
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
                tile.atlasWidth * scaleX,
                tile.atlasHeight * scaleY,
                0, tile.handle, 1.0)
            nvgBeginPath(vg)
            nvgRoundedRect(vg, ix, iy, tileDisplaySize, tileDisplaySize, 3)
            nvgFillPaint(vg, imgPaint)
            nvgFill(vg)
        else
            nvgBeginPath(vg)
            nvgRoundedRect(vg, ix, iy, tileDisplaySize, tileDisplaySize, 3)
            nvgFillColor(vg, nvgRGBA(tile.color[1], tile.color[2], tile.color[3], 255))
            nvgFill(vg)
        end
    end
end

function EditorUI:DrawLayerPanel(vg, layerManager)
    local layout = self:GetLayerPanelLayout(layerManager)

    nvgBeginPath(vg)
    nvgRoundedRect(vg, layout.x, layout.y, layout.w, layout.h, 6)
    nvgFillColor(vg, nvgRGBA(30, 32, 38, 220))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgRoundedRect(vg, layout.x, layout.y, layout.w, layout.h, 6)
    nvgStrokeColor(vg, nvgRGBA(80, 85, 100, 180))
    nvgStrokeWidth(vg, 1)
    nvgStroke(vg)

    nvgFontFaceId(vg, -1)
    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 180))
    nvgText(vg, layout.x + layout.w / 2, layout.y + 8, "图层管理", nil)

    for i = 1, layerManager:GetLayerCount() do
        local layer = layerManager.layers[i]
        local item = layout.items[i]
        local isCurrent = (i == layerManager.currentLayer)

        if isCurrent then
            nvgBeginPath(vg)
            nvgRoundedRect(vg, item.row.x, item.row.y, item.row.w, item.row.h, 4)
            nvgFillColor(vg, nvgRGBA(60, 130, 220, 150))
            nvgFill(vg)
        end

        local visColor = layer.visible and nvgRGBA(100, 220, 100, 220) or nvgRGBA(150, 150, 150, 150)
        nvgBeginPath(vg)
        nvgCircle(vg, item.visibleCircle.x, item.visibleCircle.y, item.visibleCircle.r)
        nvgFillColor(vg, visColor)
        nvgFill(vg)

        local editColor = layer.editable and nvgRGBA(255, 200, 50, 220) or nvgRGBA(150, 150, 150, 150)
        nvgBeginPath(vg)
        nvgCircle(vg, item.editableCircle.x, item.editableCircle.y, item.editableCircle.r)
        nvgFillColor(vg, editColor)
        nvgFill(vg)

        nvgFontSize(vg, 10)
        nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, layer.visible and nvgRGBA(255, 255, 255, 220) or nvgRGBA(150, 150, 150, 150))
        nvgText(vg, item.textX, item.textY, layer.name, nil)
    end

    nvgBeginPath(vg)
    nvgRoundedRect(vg, layout.addButton.x, layout.addButton.y, layout.addButton.w, layout.addButton.h, 4)
    nvgFillColor(vg, nvgRGBA(60, 130, 220, 180))
    nvgFill(vg)

    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 230))
    nvgText(vg, layout.addButton.x + layout.addButton.w / 2, layout.addButton.y + layout.addButton.h / 2, "+ 添加图层", nil)
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

    nvgFontFaceId(vg, -1)
    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 200))
    nvgText(vg, 10, y + self.statusbarHeight / 2, info, nil)
end

function EditorUI:HandlePaletteClick(x, y, state)
    if not state.paletteOpen then return false end
    if not self.tilePalette then return false end

    local source = self:GetSelectedSource(state)
    local isAtlas = source and self.tilePalette:IsSourceAtlas(source.id) or false
    local layout = self:GetPaletteLayout(isAtlas)
    local bounds = layout.bounds

    if not self:IsPointInRect(x, y, bounds) then
        self.atlasConfigOpen = false
        return false
    end

    local sources = self.tilePalette:GetSources()
    for index, sourceItem in ipairs(sources) do
        local iy = layout.sourceList.y + 24 + (index - 1) * (layout.sourceList.itemH + layout.sourceList.gap)
        local itemRect = { x = layout.sourceList.x + 6, y = iy, w = layout.sourceList.w - 12, h = layout.sourceList.itemH }
        if self:IsPointInRect(x, y, itemRect) then
            self.selectedSourceId = sourceItem.id
            self.atlasConfigOpen = false
            self.paletteExpanded = false
            local sourceItems = self.tilePalette:GetItemsForSource(sourceItem.id)
            if #sourceItems > 0 then
                state.currentTileId = sourceItems[1].id
            end
            return true
        end
    end

    if not source then
        return true
    end

    if self:IsPointInRect(x, y, layout.configButton) then
        self.atlasConfigOpen = not self.atlasConfigOpen
        return true
    end

    if self.atlasConfigOpen then
        if self:IsPointInRect(x, y, layout.popup) then
            local originalRect = { x = layout.popup.x + 4, y = layout.popup.y + 4, w = layout.popup.w - 8, h = 20 }
            if self:IsPointInRect(x, y, originalRect) then
                self:SetSourceTileSize(source.id, nil)
                local sourceItems = self.tilePalette:GetItemsForSource(source.id)
                if #sourceItems > 0 then
                    state.currentTileId = sourceItems[1].id
                end
                return true
            end

            for index, tileSize in ipairs(self.atlasTileSizeOptions) do
                local optionRect = {
                    x = layout.popup.x + 4,
                    y = layout.popup.y + 28 + (index - 1) * 24,
                    w = layout.popup.w - 8,
                    h = 20,
                }
                if self:IsPointInRect(x, y, optionRect) then
                    self:SetSourceTileSize(source.id, tileSize)
                    local sourceItems = self.tilePalette:GetItemsForSource(source.id)
                    if #sourceItems > 0 then
                        state.currentTileId = sourceItems[1].id
                    end
                    return true
                end
            end
            return true
        end
        self.atlasConfigOpen = false
    end

    if self:IsPointInRect(x, y, layout.preview) then
        if isAtlas then
            self.paletteExpanded = not self.paletteExpanded
        else
            local sourceItems = self.tilePalette:GetItemsForSource(source.id)
            if #sourceItems > 0 then
                state.currentTileId = sourceItems[1].id
            end
        end
        return true
    end

    if self.paletteExpanded then
        local items = self.tilePalette:GetItemsForSource(source.id)
        return self:HandleAtlasPaletteGridClick(x, y, layout.grid, items, state)
    end

    return true
end

function EditorUI:HandleAtlasPaletteGridClick(x, y, gridRect, items, state)
    local tileDisplaySize = 32
    local padding = 6
    local startY = gridRect.y + 20
    local cols = math.floor((gridRect.w - padding) / (tileDisplaySize + padding))
    if cols < 1 then cols = 1 end

    for i, tile in ipairs(items) do
        local colIndex = (i - 1) % cols
        local rowIndex = math.floor((i - 1) / cols)
        local ix = gridRect.x + colIndex * (tileDisplaySize + padding)
        local iy = startY + rowIndex * (tileDisplaySize + padding)

        if iy + tileDisplaySize > gridRect.y + gridRect.h then
            break
        end

        if x >= ix and x <= ix + tileDisplaySize and y >= iy and y <= iy + tileDisplaySize then
            state.currentTileId = tile.id
            print(string.format("[Editor] Selected tile id=%d (%s)", tile.id, tile.name))
            return true
        end
    end

    return true
end
function EditorUI:HandleLayerPanelClick(x, y, layerManager)
    local layout = self:GetLayerPanelLayout(layerManager)
    if not self:IsPointInRect(x, y, layout) then
        return false
    end

    if self:IsPointInRect(x, y, layout.addButton) then
        layerManager:AddLayer("新图层")
        return true
    end

    for i = 1, layerManager:GetLayerCount() do
        local item = layout.items[i]
        if self:IsPointInRect(x, y, item.row) then
            if self:IsPointInCircle(x, y, item.visibleCircle.x, item.visibleCircle.y, item.visibleCircle.r + 2) then
                layerManager:ToggleVisibility(i)
                return true
            end

            if self:IsPointInCircle(x, y, item.editableCircle.x, item.editableCircle.y, item.editableCircle.r + 2) then
                layerManager:ToggleEditable(i)
                return true
            end

            layerManager:SetCurrentLayer(i)
            return true
        end
    end

    return true
end

return EditorUI
