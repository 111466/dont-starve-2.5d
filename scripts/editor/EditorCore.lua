local EditorCore = {
    enabled = false,
    camera = nil,
    state = nil,
    ui = nil,
    undoRedo = nil,
    serializer = nil,
    layerManager = nil,
    tools = {},
}

function EditorCore:Init(vg, logicalW, logicalH, dpr, tileMap, GRID_COLS, GRID_ROWS, TILE_SIZE, ISO_Y_SCALE, tileSprites)
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

    self.camera = require("scripts/editor/EditorCamera"):new()
    self.state = require("scripts/editor/EditorState"):new()
    self.ui = require("scripts/editor/EditorUI"):new()
    self.ui:Init(tileSprites)
    self.undoRedo = require("scripts/editor/UndoRedo"):new()
    self.serializer = require("scripts/editor/MapSerializer")
    self.layerManager = require("scripts/editor/LayerManager"):new()

    self.tools["brush"] = require("scripts/editor/tools/BrushTool"):new()
    self.tools["eraser"] = require("scripts/editor/tools/EraserTool"):new()
    self.tools["fill"] = require("scripts/editor/tools/FillTool"):new()
    self.tools["entity"] = require("scripts/editor/tools/EntityTool"):new()
    self.tools["select"] = require("scripts/editor/tools/SelectTool"):new()

    self.undoRedo:Push(self.tileMap, self.GRID_COLS, self.GRID_ROWS)

    print("[Editor] Core initialized")
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
    self.state:Update(mx, my, self.camera, self.logicalW, self.logicalH, self.TILE_SIZE, self.ISO_Y_SCALE, self.GRID_COLS, self.GRID_ROWS)
end

function EditorCore:Render(vg, logicalW, logicalH)
    if not self.enabled then return end

    self.logicalW = logicalW
    self.logicalH = logicalH

    -- 绘制编辑器背景
    self:DrawBackground()

    -- 绘制地图瓦片
    self:DrawMap()

    -- 绘制UI (工具栏、调色板等)
    self.ui:Render(vg, logicalW, logicalH, self.state, self.camera, self.layerManager)

    -- 绘制网格和高亮
    if self.state.showGrid then
        self:DrawGrid()
    end
    self:DrawHoverHighlight()
    self:DrawBrushPreview()
    self:DrawEntitySelection()
    self:DrawSelectionRect()
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

            -- 选择瓦片贴图
            local spriteHandle = -1
            if tileType == 0 then
                if (col * 7 + row * 13) % 2 == 0 then
                    spriteHandle = self.tileSprites.grass1
                else
                    spriteHandle = self.tileSprites.grass2
                end
            elseif tileType == 1 then
                spriteHandle = self.tileSprites.dirt
            else
                spriteHandle = self.tileSprites.stone
            end

            local w = TILE_IMG_W * cam.zoom
            local h = TILE_IMG_H * cam.zoom

            if spriteHandle ~= -1 then
                local drawX = sx - w / 2
                local drawY = sy - h / 2
                local imgPaint = nvgImagePattern(vg, drawX, drawY, w, h, 0, spriteHandle, 1.0)
                nvgBeginPath(vg)
                nvgRect(vg, drawX, drawY, w, h)
                nvgFillPaint(vg, imgPaint)
                nvgFill(vg)
            else
                local hw = self.TILE_SIZE / 2 * cam.zoom
                local hh = self.TILE_SIZE * self.ISO_Y_SCALE / 2 * cam.zoom
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

                if st.currentTool == "eraser" then
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
    local tool = self.tools["entity"]
    if not tool or not tool.selectedEntityIndex then return end

    local vg = self.vg
    local dec = decorations[tool.selectedEntityIndex]
    if not dec then return end

    local sx, sy = self.camera:WorldToScreen(dec.x, dec.y, self.logicalW, self.logicalH, self.ISO_Y_SCALE)

    nvgBeginPath(vg)
    nvgCircle(vg, sx, sy, 15 * self.camera.zoom)
    nvgStrokeColor(vg, nvgRGBA(255, 200, 50, 255))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)
end

function EditorCore:DrawSelectionRect()
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

    local tool = self.tools[self.state.currentTool]
    if tool then
        if self.state.currentTool == "entity" then
            local result = tool:OnPress(self.state.hoverCol, self.state.hoverRow, self.state, self.tileMap, self.GRID_COLS, self.GRID_ROWS, decorations, self.camera, self.logicalW, self.logicalH, x, y)
            if result then
                self.undoRedo:Push(self.tileMap, self.GRID_COLS, self.GRID_ROWS)
            end
            return result
        else
            local result = tool:OnPress(self.state.hoverCol, self.state.hoverRow, self.state, self.tileMap, self.GRID_COLS, self.GRID_ROWS)
            if result then
                self.undoRedo:Push(self.tileMap, self.GRID_COLS, self.GRID_ROWS)
            end
            return result
        end
    end

    return self.state:HandleMousePress(x, y, button, self.tileMap, self.GRID_COLS, self.GRID_ROWS)
end

function EditorCore:HandleMouseDrag(x, y, button)
    if not self.enabled then return false end

    local tool = self.tools[self.state.currentTool]
    if tool and tool.OnDrag then
        if self.state.currentTool == "entity" then
            return tool:OnDrag(self.state.hoverCol, self.state.hoverRow, self.state, self.tileMap, self.GRID_COLS, self.GRID_ROWS, decorations, self.camera, self.logicalW, self.logicalH, x, y)
        else
            return tool:OnDrag(self.state.hoverCol, self.state.hoverRow, self.state, self.tileMap, self.GRID_COLS, self.GRID_ROWS)
        end
    end

    return self.state:HandleMouseDrag(x, y, button, self.tileMap, self.GRID_COLS, self.GRID_ROWS)
end

function EditorCore:HandleMouseRelease(x, y, button)
    if not self.enabled then return false end

    local tool = self.tools[self.state.currentTool]
    if tool and tool.OnRelease then
        if self.state.currentTool == "entity" then
            return tool:OnRelease(self.state.hoverCol, self.state.hoverRow, self.state, self.tileMap, self.GRID_COLS, self.GRID_ROWS, decorations)
        end
    end
    return false
end

function EditorCore:HandleKeyPress(key)
    if not self.enabled then return false end

    if key == KEY_Z and input:GetKeyDown(KEY_CTRL) then
        self.undoRedo:Undo(self.tileMap, self.GRID_COLS, self.GRID_ROWS)
        return true
    elseif key == KEY_Y and input:GetKeyDown(KEY_CTRL) then
        self.undoRedo:Redo(self.tileMap, self.GRID_COLS, self.GRID_ROWS)
        return true
    elseif key == KEY_F2 then
        self.serializer:Save(self.tileMap, self.GRID_COLS, self.GRID_ROWS, decorations, "map_save.json")
        return true
    elseif key == KEY_F3 then
        local success, newDecorations = self.serializer:Load(self.tileMap, decorations, "map_save.json")
        if success and newDecorations then
            decorations = newDecorations
        end
        return true
    elseif key == KEY_DELETE then
        local tool = self.tools["entity"]
        if tool and self.state.currentTool == "entity" then
            tool:DeleteSelected(decorations)
        end
        return true
    elseif key == KEY_1 then
        self.state.currentTool = "brush"
        return true
    elseif key == KEY_2 then
        self.state.currentTool = "eraser"
        return true
    elseif key == KEY_3 then
        self.state.currentTool = "fill"
        return true
    elseif key == KEY_4 then
        self.state.currentTool = "entity"
        return true
    elseif key == KEY_5 then
        self.state.currentTool = "select"
        return true
    elseif key == KEY_TAB then
        local tool = self.tools["entity"]
        if tool and self.state.currentTool == "entity" then
            tool:CycleEntityType()
        end
        return true
    elseif key == KEY_C and input:GetKeyDown(KEY_CTRL) then
        local tool = self.tools["select"]
        if tool and self.state.currentTool == "select" then
            tool:Copy(self.tileMap)
        end
        return true
    elseif key == KEY_V and input:GetKeyDown(KEY_CTRL) then
        local tool = self.tools["select"]
        if tool and self.state.currentTool == "select" then
            tool:Paste(self.tileMap, self.GRID_COLS, self.GRID_ROWS, self.state.hoverCol, self.state.hoverRow)
            self.undoRedo:Push(self.tileMap, self.GRID_COLS, self.GRID_ROWS)
        end
        return true
    end

    return self.state:HandleKeyPress(key)
end

return EditorCore
