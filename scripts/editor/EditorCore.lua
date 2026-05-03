local EditorCore = {
    enabled = false,
    camera = nil,
    state = nil,
    ui = nil,
    undoRedo = nil,
    serializer = nil,
    layerManager = nil,
    tools = {},
    collisionMap = nil,
}

local function IsMiddleMouseButton(button)
    return button == 3 or button == 4
end

local function CreateGrid(cols, rows, defaultValue)
    local grid = {}
    for row = 1, rows do
        grid[row] = {}
        for col = 1, cols do
            grid[row][col] = defaultValue or 0
        end
    end
    return grid
end

function EditorCore:Init(vg, logicalW, logicalH, dpr, fontId, tileMap, GRID_COLS, GRID_ROWS, TILE_SIZE, ISO_Y_SCALE, tileSprites, tileImageEntries, decorations)
    self.vg = vg
    self.logicalW = logicalW
    self.logicalH = logicalH
    self.dpr = dpr
    self.tileMap = tileMap
    self.GRID_COLS = GRID_COLS
    self.GRID_ROWS = GRID_ROWS
    self.TILE_SIZE = TILE_SIZE
    self.ISO_Y_SCALE = ISO_Y_SCALE
    self.tileSprites = tileSprites
    self.tileImageEntries = tileImageEntries or {}
    self.decorations = decorations or {}
    self.collisionMap = CreateGrid(GRID_COLS, GRID_ROWS, 0)

    self.camera = require("scripts/editor/EditorCamera"):new()
    self.state = require("scripts/editor/EditorState"):new()
    self.ui = require("scripts/editor/EditorUI"):new()
    self.ui:Init(vg, self.tileImageEntries, fontId)
    self.undoRedo = require("scripts/editor/UndoRedo"):new()
    self.serializer = require("scripts/editor/MapSerializer")
    self.layerManager = require("scripts/editor/LayerManager"):new()

    self.tools["brush"] = require("scripts/editor/tools/BrushTool"):new()
    self.tools["eraser"] = require("scripts/editor/tools/EraserTool"):new()
    self.tools["fill"] = require("scripts/editor/tools/FillTool"):new()
    self.tools["entity"] = require("scripts/editor/tools/EntityTool"):new()
    self.tools["select"] = require("scripts/editor/tools/SelectTool"):new()

    self.undoRedo:Push(self.tileMap, self.collisionMap, self.decorations, self.GRID_COLS, self.GRID_ROWS)

    print("[Editor] Core initialized")
end

function EditorCore:SetTool(toolName)
    if self.tools[toolName] then
        self.state.currentTool = toolName
    end
end

function EditorCore:GetCurrentLayerId()
    return self.layerManager and self.layerManager:GetCurrentLayerId() or "ground"
end

function EditorCore:GetActiveGridLayer()
    local layerId = self:GetCurrentLayerId()
    if layerId == "ground" then
        return self.tileMap
    elseif layerId == "collision" then
        return self.collisionMap
    end
    return nil
end

function EditorCore:CanUseCurrentToolOnLayer(layerId)
    if layerId == "decoration" then
        return self.state.currentTool == "entity"
    end
    if layerId == "ground" or layerId == "collision" then
        return self.state.currentTool ~= "entity"
    end
    return false
end

function EditorCore:HasVisibleContentLayer()
    return self.layerManager:IsLayerVisibleById("ground")
        or self.layerManager:IsLayerVisibleById("decoration")
        or self.layerManager:IsLayerVisibleById("collision")
end

function EditorCore:Toggle()
    self.enabled = not self.enabled
    print("[Editor] " .. (self.enabled and "Enabled" or "Disabled"))
end

function EditorCore:Update(dt, input, logicalW, logicalH)
    if not self.enabled then return end

    self.logicalW = logicalW
    self.logicalH = logicalH

    self.camera:Update(dt, input)
end

function EditorCore:UpdateMouse(mx, my)
    if not self.enabled then return end
    self.camera:UpdatePan(mx, my, self.ISO_Y_SCALE)
    self.state:Update(mx, my, self.camera, self.logicalW, self.logicalH, self.TILE_SIZE, self.ISO_Y_SCALE, self.GRID_COLS, self.GRID_ROWS)
end

function EditorCore:Render(vg, logicalW, logicalH)
    if not self.enabled then return end

    self.logicalW = logicalW
    self.logicalH = logicalH

    -- 绘制编辑器背景
    self:DrawBackground()

    if self.layerManager:IsLayerVisibleById("ground") then
        self:DrawMap()
    end

    if self.layerManager:IsLayerVisibleById("decoration") then
        self:DrawDecorations()
    end

    if self.layerManager:IsLayerVisibleById("collision") then
        self:DrawCollisionLayer()
    end

    -- 绘制UI (工具栏、调色板等)
    self.ui:Render(vg, logicalW, logicalH, self.state, self.camera, self.layerManager)

    -- 绘制网格和高亮
    if self.state.showGrid and self:HasVisibleContentLayer() then
        self:DrawGrid()
    end
    if self:HasVisibleContentLayer() then
        self:DrawHoverHighlight()
        self:DrawBrushPreview()
        if self.layerManager:IsLayerVisibleById("decoration") then
            self:DrawEntitySelection()
        end
        self:DrawSelectionRect()
    end
end

function EditorCore:DrawBackground()
    local vg = self.vg
    -- 深色背景
    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, self.logicalW, self.logicalH)
    nvgFillColor(vg, nvgRGBA(25, 28, 35, 255))
    nvgFill(vg)
end

function EditorCore:DrawMap()
    local vg = self.vg
    local cam = self.camera

    -- 计算可见范围
    local margin = self.TILE_SIZE * 2
    local startCol = math.max(1, math.floor((cam.position.x - self.logicalW / 2 / cam.zoom - margin) / self.TILE_SIZE) + 1)
    local endCol = math.min(self.GRID_COLS, math.ceil((cam.position.x + self.logicalW / 2 / cam.zoom + margin) / self.TILE_SIZE) + 1)
    local startRow = math.max(1, math.floor((cam.position.y - self.logicalH / 2 / cam.zoom / self.ISO_Y_SCALE - margin) / self.TILE_SIZE) + 1)
    local endRow = math.min(self.GRID_ROWS, math.ceil((cam.position.y + self.logicalH / 2 / cam.zoom / self.ISO_Y_SCALE + margin) / self.TILE_SIZE) + 1)

    local TILE_IMG_W = self.TILE_SIZE
    local TILE_IMG_H = self.TILE_SIZE * self.ISO_Y_SCALE

    for row = startRow, endRow do
        for col = startCol, endCol do
            local tileType = self.tileMap[row] and self.tileMap[row][col] or 0
            local wx = (col - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
            local wy = (row - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
            local sx, sy = cam:WorldToScreen(wx, wy, self.logicalW, self.logicalH, self.ISO_Y_SCALE)

            local w = TILE_IMG_W * cam.zoom
            local h = TILE_IMG_H * cam.zoom
            local drawX = sx - w / 2
            local drawY = sy - h / 2
            self:DrawTileByPalette(vg, tileType, col, row, sx, sy, w, h, drawX, drawY)
        end
    end
end

function EditorCore:DrawDecorations()
    local drawables = {}
    for _, dec in ipairs(self.decorations) do
        drawables[#drawables + 1] = dec
    end

    table.sort(drawables, function(a, b)
        return a.y < b.y
    end)

    for _, dec in ipairs(drawables) do
        DrawDecoration(dec)
    end
end

function EditorCore:DrawCollisionLayer()
    local vg = self.vg
    local cam = self.camera
    local margin = self.TILE_SIZE * 2
    local startCol = math.max(1, math.floor((cam.position.x - self.logicalW / 2 / cam.zoom - margin) / self.TILE_SIZE) + 1)
    local endCol = math.min(self.GRID_COLS, math.ceil((cam.position.x + self.logicalW / 2 / cam.zoom + margin) / self.TILE_SIZE) + 1)
    local startRow = math.max(1, math.floor((cam.position.y - self.logicalH / 2 / cam.zoom / self.ISO_Y_SCALE - margin) / self.TILE_SIZE) + 1)
    local endRow = math.min(self.GRID_ROWS, math.ceil((cam.position.y + self.logicalH / 2 / cam.zoom / self.ISO_Y_SCALE + margin) / self.TILE_SIZE) + 1)

    for row = startRow, endRow do
        for col = startCol, endCol do
            if self.collisionMap[row][col] ~= 0 then
                local wx = (col - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
                local wy = (row - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
                local sx, sy = cam:WorldToScreen(wx, wy, self.logicalW, self.logicalH, self.ISO_Y_SCALE)
                local hw = self.TILE_SIZE / 2 * cam.zoom
                local hh = self.TILE_SIZE * self.ISO_Y_SCALE / 2 * cam.zoom

                nvgBeginPath(vg)
                nvgMoveTo(vg, sx, sy - hh)
                nvgLineTo(vg, sx + hw, sy)
                nvgLineTo(vg, sx, sy + hh)
                nvgLineTo(vg, sx - hw, sy)
                nvgClosePath(vg)
                nvgFillColor(vg, nvgRGBA(220, 70, 70, 90))
                nvgFill(vg)
                nvgStrokeColor(vg, nvgRGBA(255, 90, 90, 180))
                nvgStrokeWidth(vg, 1)
                nvgStroke(vg)
            end
        end
    end
end

function EditorCore:DrawAtlasTile(vg, tile, drawX, drawY, w, h)
    if tile and tile.handle ~= -1 then
        local scaleX = w / tile.uvW
        local scaleY = h / tile.uvH
        local imgPaint = nvgImagePattern(vg,
            drawX - tile.uvX * scaleX,
            drawY - tile.uvY * scaleY,
            tile.atlasWidth * scaleX,
            tile.atlasHeight * scaleY,
            0, tile.handle, 1.0)
        nvgBeginPath(vg)
        nvgRect(vg, drawX, drawY, w, h)
        nvgFillPaint(vg, imgPaint)
        nvgFill(vg)
    else
        local hw = w / 2
        local hh = h / 2
        nvgBeginPath(vg)
        nvgMoveTo(vg, drawX + w / 2, drawY)
        nvgLineTo(vg, drawX + w, drawY + hh)
        nvgLineTo(vg, drawX + w / 2, drawY + h)
        nvgLineTo(vg, drawX, drawY + hh)
        nvgClosePath(vg)
        nvgFillColor(vg, nvgRGBA(85, 150, 65, 255))
        nvgFill(vg)
    end
end

function EditorCore:DrawSimpleTile(vg, tile, tileType, sx, sy, w, h, drawX, drawY)
    local spriteHandle = tile and tile.handle or -1

    if spriteHandle and spriteHandle ~= -1 then
        local imgPaint = nvgImagePattern(vg, drawX, drawY, w, h, 0, spriteHandle, 1.0)
        nvgBeginPath(vg)
        nvgRect(vg, drawX, drawY, w, h)
        nvgFillPaint(vg, imgPaint)
        nvgFill(vg)
    else
        local hw = self.TILE_SIZE / 2
        local hh = self.TILE_SIZE * self.ISO_Y_SCALE / 2
        local r, g, b
        if tileType == 0 then
            r, g, b = 85, 150, 65
        elseif tileType == 1 then
            r, g, b = 150, 115, 75
        else
            r, g, b = 160, 155, 145
        end
        nvgBeginPath(vg)
        nvgMoveTo(vg, sx, sy - hh)
        nvgLineTo(vg, sx + hw, sy)
        nvgLineTo(vg, sx, sy + hh)
        nvgLineTo(vg, sx - hw, sy)
        nvgClosePath(vg)
        nvgFillColor(vg, nvgRGBA(r, g, b, 255))
        nvgFill(vg)
    end
end

function EditorCore:DrawTileByPalette(vg, tileType, col, row, sx, sy, w, h, drawX, drawY)
    local tile = self.ui.tilePalette and self.ui.tilePalette:GetById(tileType) or nil
    if tile and tile.isAtlas then
        self:DrawAtlasTile(vg, tile, drawX, drawY, w, h)
    else
        self:DrawSimpleTile(vg, tile, tileType, sx, sy, w, h, drawX, drawY)
    end
end

function EditorCore:DrawGrid()
    local vg = self.vg
    local cam = self.camera

    nvgStrokeColor(vg, nvgRGBA(255, 255, 255, 40))
    nvgStrokeWidth(vg, 1)

    local margin = self.TILE_SIZE * 2
    local startCol = math.max(1, math.floor((cam.position.x - self.logicalW / 2 / cam.zoom - margin) / self.TILE_SIZE) + 1)
    local endCol = math.min(self.GRID_COLS, math.ceil((cam.position.x + self.logicalW / 2 / cam.zoom + margin) / self.TILE_SIZE) + 1)
    local startRow = math.max(1, math.floor((cam.position.y - self.logicalH / 2 / cam.zoom / self.ISO_Y_SCALE - margin) / self.TILE_SIZE) + 1)
    local endRow = math.min(self.GRID_ROWS, math.ceil((cam.position.y + self.logicalH / 2 / cam.zoom / self.ISO_Y_SCALE + margin) / self.TILE_SIZE) + 1)

    for row = startRow, endRow do
        for col = startCol, endCol do
            local wx = (col - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
            local wy = (row - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
            local sx, sy = cam:WorldToScreen(wx, wy, self.logicalW, self.logicalH, self.ISO_Y_SCALE)

            local hw = self.TILE_SIZE / 2 * cam.zoom
            local hh = self.TILE_SIZE * self.ISO_Y_SCALE / 2 * cam.zoom

            nvgBeginPath(vg)
            nvgMoveTo(vg, sx, sy - hh)
            nvgLineTo(vg, sx + hw, sy)
            nvgLineTo(vg, sx, sy + hh)
            nvgLineTo(vg, sx - hw, sy)
            nvgClosePath(vg)
            nvgStroke(vg)
        end
    end
end

function EditorCore:DrawHoverHighlight()
    local vg = self.vg
    local cam = self.camera
    local st = self.state
    local layerId = self:GetCurrentLayerId()

    if not self.layerManager:IsLayerVisibleById(layerId) then
        return
    end

    if st.hoverCol < 1 or st.hoverCol > self.GRID_COLS or st.hoverRow < 1 or st.hoverRow > self.GRID_ROWS then
        return
    end

    local wx = (st.hoverCol - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
    local wy = (st.hoverRow - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
    local sx, sy = cam:WorldToScreen(wx, wy, self.logicalW, self.logicalH, self.ISO_Y_SCALE)

    local hw = self.TILE_SIZE / 2 * cam.zoom
    local hh = self.TILE_SIZE * self.ISO_Y_SCALE / 2 * cam.zoom

    nvgBeginPath(vg)
    nvgMoveTo(vg, sx, sy - hh)
    nvgLineTo(vg, sx + hw, sy)
    nvgLineTo(vg, sx, sy + hh)
    nvgLineTo(vg, sx - hw, sy)
    nvgClosePath(vg)
    nvgStrokeColor(vg, nvgRGBA(255, 255, 0, 200))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)
end

function EditorCore:DrawBrushPreview()
    local vg = self.vg
    local cam = self.camera
    local st = self.state
    local layerId = self:GetCurrentLayerId()

    if not self.layerManager:IsLayerVisibleById(layerId) then
        return
    end
    if st.currentTool == "entity" or st.currentTool == "select" then
        return
    end

    if st.hoverCol < 1 or st.hoverCol > self.GRID_COLS or st.hoverRow < 1 or st.hoverRow > self.GRID_ROWS then
        return
    end

    local size = st.brushSize
    local half = math.floor(size / 2)

    for dc = -half, half do
        for dr = -half, half do
            local tc = st.hoverCol + dc
            local tr = st.hoverRow + dr
            if tc >= 1 and tc <= self.GRID_COLS and tr >= 1 and tr <= self.GRID_ROWS then
                local wx = (tc - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
                local wy = (tr - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
                local sx, sy = cam:WorldToScreen(wx, wy, self.logicalW, self.logicalH, self.ISO_Y_SCALE)

                local hw = self.TILE_SIZE / 2 * cam.zoom
                local hh = self.TILE_SIZE * self.ISO_Y_SCALE / 2 * cam.zoom

                nvgBeginPath(vg)
                nvgMoveTo(vg, sx, sy - hh)
                nvgLineTo(vg, sx + hw, sy)
                nvgLineTo(vg, sx, sy + hh)
                nvgLineTo(vg, sx - hw, sy)
                nvgClosePath(vg)

                if layerId == "collision" then
                    nvgFillColor(vg, nvgRGBA(255, 80, 80, 70))
                elseif st.currentTool == "eraser" then
                    nvgFillColor(vg, nvgRGBA(255, 50, 50, 60))
                else
                    nvgFillColor(vg, nvgRGBA(255, 255, 0, 60))
                end
                nvgFill(vg)
            end
        end
    end
end

function EditorCore:DrawEntitySelection()
    if not self.layerManager:IsLayerVisibleById("decoration") then return end
    local tool = self.tools["entity"]
    if not tool or not tool.selectedEntityIndex then return end

    local vg = self.vg
    local dec = self.decorations[tool.selectedEntityIndex]
    if not dec then return end

    local sx, sy = self.camera:WorldToScreen(dec.x, dec.y, self.logicalW, self.logicalH, self.ISO_Y_SCALE)

    nvgBeginPath(vg)
    nvgCircle(vg, sx, sy, 15 * self.camera.zoom)
    nvgStrokeColor(vg, nvgRGBA(255, 200, 50, 255))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)
end

function EditorCore:DrawSelectionRect()
    local layerId = self:GetCurrentLayerId()
    if layerId == "decoration" then return end
    if not self.layerManager:IsLayerVisibleById(layerId) then return end
    local tool = self.tools["select"]
    if not tool or not tool.selectionStart or not tool.selectionEnd then return end

    local vg = self.vg
    local cam = self.camera

    local c1 = math.min(tool.selectionStart.col, tool.selectionEnd.col)
    local c2 = math.max(tool.selectionStart.col, tool.selectionEnd.col)
    local r1 = math.min(tool.selectionStart.row, tool.selectionEnd.row)
    local r2 = math.max(tool.selectionStart.row, tool.selectionEnd.row)

    for c = c1, c2 do
        for r = r1, r2 do
            local wx = (c - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
            local wy = (r - 1) * self.TILE_SIZE + self.TILE_SIZE / 2
            local sx, sy = cam:WorldToScreen(wx, wy, self.logicalW, self.logicalH, self.ISO_Y_SCALE)

            local hw = self.TILE_SIZE / 2 * cam.zoom
            local hh = self.TILE_SIZE * self.ISO_Y_SCALE / 2 * cam.zoom

            nvgBeginPath(vg)
            nvgMoveTo(vg, sx, sy - hh)
            nvgLineTo(vg, sx + hw, sy)
            nvgLineTo(vg, sx, sy + hh)
            nvgLineTo(vg, sx - hw, sy)
            nvgClosePath(vg)
            nvgFillColor(vg, nvgRGBA(100, 150, 255, 80))
            nvgFill(vg)
            nvgStrokeColor(vg, nvgRGBA(100, 150, 255, 200))
            nvgStrokeWidth(vg, 1)
            nvgStroke(vg)
        end
    end
end

function EditorCore:HandleMousePress(x, y, button)
    if not self.enabled then return false end

    if self.ui:HandleToolbarClick(x, y, self.state, self) then
        return true
    end

    if IsMiddleMouseButton(button) then
        self.camera:StartPan(x, y)
        return true
    end

    if self.camera.isPanning then return true end

    -- 检查是否点击了调色板
    if self.ui:HandlePaletteClick(x, y, self.state) then
        return true
    end

    if self.ui:HandleLayerPanelClick(x, y, self.layerManager) then
        return true
    end

    local layerId = self:GetCurrentLayerId()
    if not self.layerManager:CanEditCurrentLayer() then
        return false
    end
    if not self.layerManager:IsLayerVisibleById(layerId) then
        return false
    end
    if not self:CanUseCurrentToolOnLayer(layerId) then
        return false
    end

    local tool = self.tools[self.state.currentTool]
    if tool then
        if layerId == "decoration" and self.state.currentTool == "entity" then
            local result = tool:OnPress(self.state.hoverCol, self.state.hoverRow, self.state, self.tileMap, self.GRID_COLS, self.GRID_ROWS, self.decorations, self.camera, self.logicalW, self.logicalH, x, y)
            if result then
                self.undoRedo:Push(self.tileMap, self.collisionMap, self.decorations, self.GRID_COLS, self.GRID_ROWS)
            end
            return result
        end

        local activeGrid = self:GetActiveGridLayer()
        if activeGrid then
            local result = tool:OnPress(self.state.hoverCol, self.state.hoverRow, self.state, layerId, activeGrid, self.GRID_COLS, self.GRID_ROWS)
            if result then
                self.undoRedo:Push(self.tileMap, self.collisionMap, self.decorations, self.GRID_COLS, self.GRID_ROWS)
            end
            return result
        end
    end

    return self.state:HandleMousePress(x, y, button, self.tileMap, self.GRID_COLS, self.GRID_ROWS)
end

function EditorCore:HandleMouseDrag(x, y, button)
    if not self.enabled then return false end

    if self.camera.isPanning then
        return true
    end

    local layerId = self:GetCurrentLayerId()
    if not self.layerManager:CanEditCurrentLayer() then
        return false
    end
    if not self.layerManager:IsLayerVisibleById(layerId) then
        return false
    end
    if not self:CanUseCurrentToolOnLayer(layerId) then
        return false
    end

    local tool = self.tools[self.state.currentTool]
    if tool and tool.OnDrag then
        if layerId == "decoration" and self.state.currentTool == "entity" then
            return tool:OnDrag(self.state.hoverCol, self.state.hoverRow, self.state, self.tileMap, self.GRID_COLS, self.GRID_ROWS, self.decorations, self.camera, self.logicalW, self.logicalH, x, y)
        end

        local activeGrid = self:GetActiveGridLayer()
        if activeGrid then
            return tool:OnDrag(self.state.hoverCol, self.state.hoverRow, self.state, layerId, activeGrid, self.GRID_COLS, self.GRID_ROWS)
        end
    end

    return self.state:HandleMouseDrag(x, y, button, self.tileMap, self.GRID_COLS, self.GRID_ROWS)
end

function EditorCore:HandleMouseRelease(x, y, button)
    if not self.enabled then return false end

    if IsMiddleMouseButton(button) then
        self.camera:EndPan()
        return true
    end

    if self.camera.isPanning then return true end

    local layerId = self:GetCurrentLayerId()
    local tool = self.tools[self.state.currentTool]
    if tool and tool.OnRelease then
        if layerId == "decoration" and self.state.currentTool == "entity" then
            return tool:OnRelease(self.state.hoverCol, self.state.hoverRow, self.state, self.tileMap, self.GRID_COLS, self.GRID_ROWS, self.decorations)
        end

        local activeGrid = self:GetActiveGridLayer()
        if activeGrid then
            return tool:OnRelease(self.state.hoverCol, self.state.hoverRow, self.state, layerId, activeGrid, self.GRID_COLS, self.GRID_ROWS)
        end
    end
    return false
end

function EditorCore:HandleKeyPress(key)
    if not self.enabled then return false end

    if key == KEY_Z and input:GetKeyDown(KEY_CTRL) then
        self.undoRedo:Undo(self.tileMap, self.collisionMap, self.decorations, self.GRID_COLS, self.GRID_ROWS)
        return true
    elseif key == KEY_Y and input:GetKeyDown(KEY_CTRL) then
        self.undoRedo:Redo(self.tileMap, self.collisionMap, self.decorations, self.GRID_COLS, self.GRID_ROWS)
        return true
    elseif key == KEY_F2 then
        self:SaveMap()
        return true
    elseif key == KEY_F3 then
        self:LoadMap()
        return true
    elseif key == KEY_DELETE then
        local tool = self.tools["entity"]
        if tool and self.state.currentTool == "entity" and self:GetCurrentLayerId() == "decoration" then
            if tool:DeleteSelected(self.decorations) then
                self.undoRedo:Push(self.tileMap, self.collisionMap, self.decorations, self.GRID_COLS, self.GRID_ROWS)
            end
        end
        return true
    elseif key == KEY_1 then
        self:SetTool("brush")
        return true
    elseif key == KEY_2 then
        self:SetTool("eraser")
        return true
    elseif key == KEY_3 then
        self:SetTool("fill")
        return true
    elseif key == KEY_4 then
        self:SetTool("entity")
        return true
    elseif key == KEY_5 then
        self:SetTool("select")
        return true
    elseif key == KEY_TAB then
        local tool = self.tools["entity"]
        if tool and self.state.currentTool == "entity" and self:GetCurrentLayerId() == "decoration" then
            tool:CycleEntityType()
        end
        return true
    elseif key == KEY_C and input:GetKeyDown(KEY_CTRL) then
        local tool = self.tools["select"]
        local activeGrid = self:GetActiveGridLayer()
        if tool and self.state.currentTool == "select" and activeGrid and self.layerManager:IsLayerVisibleById(self:GetCurrentLayerId()) then
            tool:Copy(activeGrid)
        end
        return true
    elseif key == KEY_V and input:GetKeyDown(KEY_CTRL) then
        local tool = self.tools["select"]
        local activeGrid = self:GetActiveGridLayer()
        if tool and self.state.currentTool == "select" and activeGrid and self.layerManager:CanEditCurrentLayer()
            and self.layerManager:IsLayerVisibleById(self:GetCurrentLayerId()) then
            tool:Paste(activeGrid, self.GRID_COLS, self.GRID_ROWS, self.state.hoverCol, self.state.hoverRow)
            self.undoRedo:Push(self.tileMap, self.collisionMap, self.decorations, self.GRID_COLS, self.GRID_ROWS)
        end
        return true
    end

    return self.state:HandleKeyPress(key, self.ui.tilePalette)
end

function EditorCore:SaveMap()
    return self.serializer:Save(self.tileMap, self.collisionMap, self.GRID_COLS, self.GRID_ROWS, self.decorations, "map_save.json")
end

function EditorCore:LoadMap()
    local success = self.serializer:Load(self.tileMap, self.collisionMap, self.decorations, "map_save.json")
    if success then
        self.undoRedo:Push(self.tileMap, self.collisionMap, self.decorations, self.GRID_COLS, self.GRID_ROWS)
    end
    return success
end

return EditorCore
