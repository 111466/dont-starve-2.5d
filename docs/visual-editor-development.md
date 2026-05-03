# 饥荒风格 2.5D 游戏 - 可视化地图编辑器开发文档

## 文档信息

- **版本**: 1.0
- **日期**: 2026-05-03
- **状态**: 设计阶段
- **目标**: 实现游戏内运行时可视化瓦片地图编辑器

---

## 1. 概述

### 1.1 目标

开发一个集成在游戏内的运行时可视化地图编辑器，提供类似 Unity Tilemap 的核心编辑能力，包括：

- 可视化瓦片绘制与擦除
- 多层地图编辑
- 瓦片调色板与选择
- 地图序列化保存/加载
- 实时预览游戏效果

### 1.2 设计原则

| 原则 | 说明 |
|------|------|
| **运行时编辑** | 在游戏运行状态下直接编辑，所见即所得 |
| **非侵入式** | 编辑器作为独立模块，不影响游戏核心逻辑 |
| **配置驱动** | 瓦片类型、工具配置通过数据文件定义 |
| **扩展友好** | 支持自定义工具、笔刷、瓦片类型 |

---

## 2. 功能需求

### 2.1 核心功能

```
┌─────────────────────────────────────────────────────────────┐
│                      编辑器功能矩阵                          │
├─────────────────────────────────────────────────────────────┤
│ 功能模块        │ 功能点              │ 优先级 │ 状态      │
├─────────────────────────────────────────────────────────────┤
│ 基础编辑        │ 单瓦片绘制          │ P0     │ 待实现    │
│                │ 单瓦片擦除          │ P0     │ 待实现    │
│                │ 矩形区域填充        │ P1     │ 待实现    │
│                │ 圆形笔刷绘制        │ P1     │ 待实现    │
│                │ 区域选择/移动       │ P2     │ 待实现    │
├─────────────────────────────────────────────────────────────┤
│ 多层编辑        │ 地面层编辑          │ P0     │ 待实现    │
│                │ 装饰层编辑          │ P1     │ 待实现    │
│                │ 碰撞层编辑          │ P1     │ 待实现    │
│                │ 层可见性切换        │ P1     │ 待实现    │
│                │ 层锁定/解锁         │ P2     │ 待实现    │
├─────────────────────────────────────────────────────────────┤
│ 瓦片系统        │ 瓦片调色板          │ P0     │ 待实现    │
│                │ 瓦片属性编辑        │ P1     │ 待实现    │
│                │ 瓦片旋转/翻转       │ P1     │ 待实现    │
│                │ 自定义瓦片类型      │ P2     │ 待实现    │
├─────────────────────────────────────────────────────────────┤
│ 地图操作        │ 新建地图            │ P0     │ 待实现    │
│                │ 保存地图(JSON)      │ P0     │ 待实现    │
│                │ 加载地图            │ P0     │ 待实现    │
│                │ 地图尺寸调整        │ P1     │ 待实现    │
│                │ 导出图片            │ P2     │ 待实现    │
├─────────────────────────────────────────────────────────────┤
│ 视图控制        │ 相机平移            │ P0     │ 待实现    │
│                │ 相机缩放            │ P0     │ 待实现    │
│                │ 网格显示/隐藏       │ P1     │ 待实现    │
│                │ 坐标显示            │ P1     │ 待实现    │
├─────────────────────────────────────────────────────────────┤
│ 实体编辑        │ 放置装饰物          │ P1     │ 待实现    │
│                │ 移动实体            │ P1     │ 待实现    │
│                │ 删除实体            │ P1     │ 待实现    │
│                │ 实体属性编辑        │ P2     │ 待实现    │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 快捷键设计

| 按键 | 功能 | 模式 |
|------|------|------|
| `F12` | 切换编辑器/游戏模式 | 全局 |
| `F1` | 切换工具（画笔/橡皮/填充） | 编辑器 |
| `F2` | 保存地图 | 编辑器 |
| `F3` | 加载地图 | 编辑器 |
| `W/A/S/D` | 移动编辑相机 | 编辑器 |
| `鼠标左键` | 绘制/选择 | 编辑器 |
| `鼠标右键` | 擦除/平移 | 编辑器 |
| `鼠标滚轮` | 缩放视图 | 编辑器 |
| `Q/E` | 切换瓦片类型 | 编辑器 |
| `+/-` | 调整笔刷大小 | 编辑器 |
| `Ctrl+Z` | 撤销 | 编辑器 |
| `Ctrl+Y` | 重做 | 编辑器 |
| `Delete` | 删除选中 | 编辑器 |

---

## 3. 系统架构

### 3.1 模块结构

```
editor/
├── EditorCore.lua              # 编辑器核心控制器
├── EditorState.lua             # 编辑器状态管理
├── MapEditor.lua               # 地图编辑模块
├── TilePalette.lua             # 瓦片调色板
├── BrushSystem.lua             # 笔刷系统
├── LayerManager.lua            # 图层管理
├── EntityEditor.lua            # 实体编辑器
├── EditorUI.lua                # UI 渲染
├── EditorCamera.lua            # 编辑器相机
├── UndoRedo.lua                # 撤销重做系统
├── MapSerializer.lua           # 地图序列化
└── tools/                      # 工具插件目录
    ├── BaseTool.lua            # 工具基类
    ├── BrushTool.lua           # 画笔工具
    ├── EraserTool.lua          # 橡皮工具
    ├── FillTool.lua            # 填充工具
    ├── SelectTool.lua          # 选择工具
    └── EntityTool.lua          # 实体工具
```

### 3.2 类图设计

```
┌─────────────────────────────────────────────────────────────┐
│                     EditorCore                              │
│  ─────────────────────────────────────────────────────────  │
│  - enabled: bool                                            │
│  - currentTool: BaseTool                                    │
│  - tools: table<BaseTool>                                   │
│  - state: EditorState                                       │
│  - camera: EditorCamera                                     │
│  - layerManager: LayerManager                               │
│  - undoRedo: UndoRedo                                       │
│  ─────────────────────────────────────────────────────────  │
│  + Initialize()                                             │
│  + Shutdown()                                               │
│  + Enable()                                                 │
│  + Disable()                                                │
│  + Update(dt)                                               │
│  + Render()                                                 │
│  + SetTool(toolType)                                        │
│  + HandleInput(input)                                       │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  EditorState  │    │  BaseTool     │    │ EditorCamera  │
├───────────────┤    ├───────────────┤    ├───────────────┤
│ - mode        │◄───│ - name        │    │ - position    │
│ - currentTile │    │ - icon        │    │ - zoom        │
│ - brushSize   │    │ - cursor      │    │ - bounds      │
│ - currentLayer│    ├───────────────┤    ├───────────────┤
│ - hoverPos    │    │ + OnPress()   │    │ + Pan(dx,dy)  │
│ - isDragging  │    │ + OnDrag()    │    │ + Zoom(factor)│
├───────────────┤    │ + OnRelease() │    │ + ScreenToWorld│
│ + SetMode()   │    │ + OnRender()  │    │ + WorldToScreen│
│ + SetTile()   │    │ + CanUse()    │    │ + GetVisibleBounds│
└───────────────┘    └───────────────┘    └───────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  BrushTool    │    │  EraserTool   │    │  FillTool     │
├───────────────┤    ├───────────────┤    ├───────────────┤
│ - brushShape  │    │ - brushSize   │    │ - tolerance   │
│ - brushSize   │    │ - affectLayers│    │ - fillMode    │
├───────────────┤    ├───────────────┤    ├───────────────┤
│ + Paint()     │    │ + Erase()     │    │ + FloodFill() │
│ + Preview()   │    │ + Preview()   │    │ + Preview()   │
└───────────────┘    └───────────────┘    └───────────────┘
```

---

## 4. 详细设计

### 4.1 编辑器核心 (EditorCore)

```lua
-- EditorCore.lua
local EditorCore = {
    -- 配置
    CONFIG = {
        ENABLE_HOTKEY = KEY_F12,
        DEFAULT_BRUSH_SIZE = 1,
        MAX_BRUSH_SIZE = 5,
        MIN_ZOOM = 0.3,
        MAX_ZOOM = 3.0,
        GRID_COLOR = { r = 255, g = 255, b = 255, a = 30 },
        PREVIEW_COLOR = { r = 255, g = 255, b = 100, a = 150 },
    },
    
    -- 状态
    enabled = false,
    initialized = false,
    
    -- 子系统
    state = nil,
    camera = nil,
    tools = {},
    currentTool = nil,
    layerManager = nil,
    undoRedo = nil,
    ui = nil,
}

function EditorCore:Initialize()
    if self.initialized then return end
    
    -- 初始化子系统
    self.state = EditorState:new()
    self.camera = EditorCamera:new()
    self.layerManager = LayerManager:new()
    self.undoRedo = UndoRedo:new()
    self.ui = EditorUI:new()
    
    -- 注册工具
    self:RegisterTool(BrushTool:new())
    self:RegisterTool(EraserTool:new())
    self:RegisterTool(FillTool:new())
    self:RegisterTool(SelectTool:new())
    self:RegisterTool(EntityTool:new())
    
    -- 默认工具
    self:SetTool("brush")
    
    self.initialized = true
    print("[Editor] Initialized")
end

function EditorCore:Enable()
    if not self.initialized then
        self:Initialize()
    end
    
    self.enabled = true
    
    -- 保存游戏相机状态
    self.savedCamera = {
        x = camX,
        y = camY,
        zoom = 1.0,
    }
    
    -- 切换到编辑相机
    self.camera:Reset()
    self.camera.position = { x = camX, y = camY }
    
    -- 暂停游戏逻辑
    timeScale = 0
    
    print("[Editor] Enabled")
end

function EditorCore:Disable()
    self.enabled = false
    
    -- 恢复游戏相机
    camX = self.savedCamera.x
    camY = self.savedCamera.y
    
    -- 恢复游戏逻辑
    timeScale = 1
    
    print("[Editor] Disabled")
end

function EditorCore:Toggle()
    if self.enabled then
        self:Disable()
    else
        self:Enable()
    end
end

function EditorCore:Update(dt)
    if not self.enabled then return end
    
    -- 更新相机
    self.camera:Update(dt)
    
    -- 更新当前工具
    if self.currentTool then
        self.currentTool:Update(dt)
    end
    
    -- 更新状态
    self:UpdateHoverPosition()
end

function EditorCore:Render()
    if not self.enabled then return end
    
    -- 渲染网格
    self:RenderGrid()
    
    -- 渲染地图（使用编辑相机）
    self:RenderMap()
    
    -- 渲染工具预览
    if self.currentTool then
        self.currentTool:RenderPreview()
    end
    
    -- 渲染 UI
    self.ui:Render()
end

function EditorCore:HandleInput(input)
    if not self.enabled then return false end
    
    -- 全局快捷键
    if input:GetKeyPress(self.CONFIG.ENABLE_HOTKEY) then
        self:Toggle()
        return true
    end
    
    -- 工具快捷键
    if input:GetKeyPress(KEY_F1) then
        self:CycleTool()
        return true
    end
    
    if input:GetKeyPress(KEY_F2) then
        self:SaveMap()
        return true
    end
    
    if input:GetKeyPress(KEY_F3) then
        self:LoadMap()
        return true
    end
    
    -- 传递给当前工具
    if self.currentTool then
        return self.currentTool:HandleInput(input)
    end
    
    return false
end

function EditorCore:RegisterTool(tool)
    self.tools[tool.name] = tool
    tool.editor = self
end

function EditorCore:SetTool(toolName)
    local tool = self.tools[toolName]
    if not tool then
        print("[Editor] Unknown tool: " .. toolName)
        return
    end
    
    if self.currentTool then
        self.currentTool:OnDeactivate()
    end
    
    self.currentTool = tool
    self.state.currentTool = toolName
    tool:OnActivate()
    
    print("[Editor] Tool changed: " .. toolName)
end

function EditorCore:CycleTool()
    local toolNames = { "brush", "eraser", "fill", "select", "entity" }
    local currentIndex = 1
    
    for i, name in ipairs(toolNames) do
        if name == self.state.currentTool then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = (currentIndex % #toolNames) + 1
    self:SetTool(toolNames[nextIndex])
end

function EditorCore:UpdateHoverPosition()
    local mousePos = input:GetMousePosition()
    local mx = mousePos.x / dpr
    local my = mousePos.y / dpr
    
    -- 屏幕坐标转世界坐标
    local worldPos = self.camera:ScreenToWorld(mx, my)
    
    -- 世界坐标转瓦片坐标
    self.state.hoverCol = math.floor(worldPos.x / TILE_SIZE) + 1
    self.state.hoverRow = math.floor(worldPos.y / TILE_SIZE) + 1
    self.state.hoverWorldX = worldPos.x
    self.state.hoverWorldY = worldPos.y
end

function EditorCore:RenderGrid()
    if not self.state.showGrid then return end
    
    local bounds = self.camera:GetVisibleBounds()
    local startCol = math.max(1, math.floor(bounds.left / TILE_SIZE))
    local endCol = math.min(GRID_COLS, math.ceil(bounds.right / TILE_SIZE))
    local startRow = math.max(1, math.floor(bounds.top / TILE_SIZE))
    local endRow = math.min(GRID_ROWS, math.ceil(bounds.bottom / TILE_SIZE))
    
    nvgStrokeColor(vg, nvgRGBA(
        self.CONFIG.GRID_COLOR.r,
        self.CONFIG.GRID_COLOR.g,
        self.CONFIG.GRID_COLOR.b,
        self.CONFIG.GRID_COLOR.a
    ))
    nvgStrokeWidth(vg, 1)
    
    for row = startRow, endRow do
        for col = startCol, endCol do
            local wx = (col - 1) * TILE_SIZE + TILE_SIZE / 2
            local wy = (row - 1) * TILE_SIZE + TILE_SIZE / 2
            local sx, sy = self.camera:WorldToScreen(wx, wy)
            
            local hw = TILE_SIZE * self.camera.zoom / 2
            local hh = TILE_SIZE * ISO_Y_SCALE * self.camera.zoom / 2
            
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

function EditorCore:RenderMap()
    -- 使用编辑相机渲染地图
    local oldCamX, oldCamY = camX, camY
    camX = self.camera.position.x
    camY = self.camera.position.y
    
    -- 调用原有地图渲染
    DrawGround()
    
    -- 恢复游戏相机
    camX, camY = oldCamX, oldCamY
end

function EditorCore:SaveMap(filename)
    filename = filename or "map_save.json"
    local success = MapSerializer:Save(tileMap, decorations, filename)
    if success then
        print("[Editor] Map saved: " .. filename)
    else
        print("[Editor] Failed to save map")
    end
end

function EditorCore:LoadMap(filename)
    filename = filename or "map_save.json"
    local data = MapSerializer:Load(filename)
    if data then
        tileMap = data.tileMap
        decorations = data.decorations
        print("[Editor] Map loaded: " .. filename)
    else
        print("[Editor] Failed to load map")
    end
end

return EditorCore
```

### 4.2 笔刷系统 (BrushSystem)

```lua
-- BrushSystem.lua
local BrushSystem = {
    -- 笔刷形状定义
    SHAPES = {
        SQUARE = "square",
        CIRCLE = "circle",
        DIAMOND = "diamond",
    },
    
    -- 笔刷大小预览
    SIZE_COLORS = {
        { r = 255, g = 255, b = 100, a = 100 },  -- 大小 1
        { r = 255, g = 200, b = 50, a = 100 },   -- 大小 2
        { r = 255, g = 150, b = 0, a = 100 },    -- 大小 3
        { r = 255, g = 100, b = 0, a = 100 },    -- 大小 4
        { r = 255, g = 50, b = 0, a = 100 },     -- 大小 5
    },
}

-- 获取笔刷影响的瓦片坐标列表
function BrushSystem:GetAffectedTiles(centerCol, centerRow, size, shape)
    local tiles = {}
    local radius = math.floor(size / 2)
    
    for dy = -radius, radius do
        for dx = -radius, radius do
            local col = centerCol + dx
            local row = centerRow + dy
            
            -- 根据形状过滤
            local include = false
            
            if shape == BrushSystem.SHAPES.SQUARE then
                include = true
            elseif shape == BrushSystem.SHAPES.CIRCLE then
                include = (dx * dx + dy * dy) <= (radius * radius + 0.5)
            elseif shape == BrushSystem.SHAPES.DIAMOND then
                include = (math.abs(dx) + math.abs(dy)) <= radius
            end
            
            if include then
                table.insert(tiles, { col = col, row = row })
            end
        end
    end
    
    return tiles
end

-- 预览笔刷范围
function BrushSystem:RenderPreview(centerCol, centerRow, size, shape, color)
    local tiles = self:GetAffectedTiles(centerCol, centerRow, size, shape)
    
    nvgFillColor(vg, nvgRGBA(color.r, color.g, color.b, color.a))
    
    for _, tile in ipairs(tiles) do
        if tile.row >= 1 and tile.row <= GRID_ROWS and 
           tile.col >= 1 and tile.col <= GRID_COLS then
            
            local wx = (tile.col - 1) * TILE_SIZE + TILE_SIZE / 2
            local wy = (tile.row - 1) * TILE_SIZE + TILE_SIZE / 2
            local sx, sy = EditorCore.camera:WorldToScreen(wx, wy)
            
            local hw = TILE_SIZE * EditorCore.camera.zoom / 2
            local hh = TILE_SIZE * ISO_Y_SCALE * EditorCore.camera.zoom / 2
            
            nvgBeginPath(vg)
            nvgMoveTo(vg, sx, sy - hh)
            nvgLineTo(vg, sx + hw, sy)
            nvgLineTo(vg, sx, sy + hh)
            nvgLineTo(vg, sx - hw, sy)
            nvgClosePath(vg)
            nvgFill(vg)
        end
    end
end

return BrushSystem
```

### 4.3 撤销重做系统 (UndoRedo)

```lua
-- UndoRedo.lua
local UndoRedo = {
    MAX_HISTORY = 50,          -- 最大历史记录数
    
    history = {},              -- 操作历史
    currentIndex = 0,          -- 当前位置
}

-- 操作类型定义
UndoRedo.ACTION_TYPES = {
    PAINT_TILES = "paint_tiles",
    ERASE_TILES = "erase_tiles",
    MOVE_ENTITY = "move_entity",
    ADD_ENTITY = "add_entity",
    REMOVE_ENTITY = "remove_entity",
}

function UndoRedo:new()
    local obj = {
        history = {},
        currentIndex = 0,
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- 记录操作
function UndoRedo:RecordAction(actionType, data)
    -- 删除当前位置之后的历史
    while #self.history > self.currentIndex do
        table.remove(self.history)
    end
    
    -- 添加新操作
    local action = {
        type = actionType,
        data = DeepCopy(data),    -- 深拷贝数据
        timestamp = os.time(),
    }
    
    table.insert(self.history, action)
    self.currentIndex = self.currentIndex + 1
    
    -- 限制历史记录数量
    if #self.history > self.MAX_HISTORY then
        table.remove(self.history, 1)
        self.currentIndex = self.currentIndex - 1
    end
end

-- 撤销
function UndoRedo:Undo()
    if self.currentIndex <= 0 then
        print("[UndoRedo] Nothing to undo")
        return false
    end
    
    local action = self.history[self.currentIndex]
    self:RevertAction(action)
    
    self.currentIndex = self.currentIndex - 1
    print("[UndoRedo] Undid: " .. action.type)
    return true
end

-- 重做
function UndoRedo:Redo()
    if self.currentIndex >= #self.history then
        print("[UndoRedo] Nothing to redo")
        return false
    end
    
    self.currentIndex = self.currentIndex + 1
    local action = self.history[self.currentIndex]
    self:ApplyAction(action)
    
    print("[UndoRedo] Redid: " .. action.type)
    return true
end

-- 应用操作（用于重做）
function UndoRedo:ApplyAction(action)
    if action.type == self.ACTION_TYPES.PAINT_TILES then
        for _, tile in ipairs(action.data.tiles) do
            tileMap[tile.row][tile.col] = tile.newValue
        end
    elseif action.type == self.ACTION_TYPES.ERASE_TILES then
        for _, tile in ipairs(action.data.tiles) do
            tileMap[tile.row][tile.col] = tile.newValue
        end
    end
end

-- 回滚操作（用于撤销）
function UndoRedo:RevertAction(action)
    if action.type == self.ACTION_TYPES.PAINT_TILES then
        for _, tile in ipairs(action.data.tiles) do
            tileMap[tile.row][tile.col] = tile.oldValue
        end
    elseif action.type == self.ACTION_TYPES.ERASE_TILES then
        for _, tile in ipairs(action.data.tiles) do
            tileMap[tile.row][tile.col] = tile.oldValue
        end
    end
end

-- 清空历史
function UndoRedo:Clear()
    self.history = {}
    self.currentIndex = 0
end

return UndoRedo
```

### 4.4 地图序列化 (MapSerializer)

```lua
-- MapSerializer.lua
local MapSerializer = {
    VERSION = "1.0",
    SAVE_DIR = "Data/Maps/",
}

-- 序列化地图为 JSON
function MapSerializer:Save(tileMapData, decorationsData, filename)
    local mapData = {
        version = self.VERSION,
        created = os.date("%Y-%m-%d %H:%M:%S"),
        width = GRID_COLS,
        height = GRID_ROWS,
        tileSize = TILE_SIZE,
        
        -- 瓦片数据（使用紧凑格式）
        tiles = self:SerializeTiles(tileMapData),
        
        -- 装饰物数据
        decorations = decorationsData,
        
        -- 元数据
        metadata = {
            tileTypes = TILE_PALETTE,
            layers = {
                { name = "ground", visible = true },
            },
        },
    }
    
    -- 转换为 JSON 字符串
    local jsonStr = self:EncodeJSON(mapData)
    
    -- 写入文件
    local filepath = self.SAVE_DIR .. filename
    local success = self:WriteFile(filepath, jsonStr)
    
    return success
end

-- 反序列化地图
function MapSerializer:Load(filename)
    local filepath = self.SAVE_DIR .. filename
    local jsonStr = self:ReadFile(filepath)
    
    if not jsonStr then
        print("[MapSerializer] File not found: " .. filepath)
        return nil
    end
    
    local mapData = self:DecodeJSON(jsonStr)
    
    -- 版本检查
    if mapData.version ~= self.VERSION then
        print("[MapSerializer] Version mismatch: " .. mapData.version .. " vs " .. self.VERSION)
    end
    
    -- 还原瓦片数据
    local restoredTileMap = self:DeserializeTiles(mapData.tiles, mapData.width, mapData.height)
    
    return {
        tileMap = restoredTileMap,
        decorations = mapData.decorations or {},
        metadata = mapData.metadata,
    }
end

-- 紧凑序列化瓦片数据
function MapSerializer:SerializeTiles(tileMapData)
    -- 使用 Run-Length Encoding 减少数据量
    local tiles = {}
    
    for row = 1, GRID_ROWS do
        local rowData = {}
        local currentValue = tileMapData[row][1]
        local count = 1
        
        for col = 2, GRID_COLS do
            if tileMapData[row][col] == currentValue then
                count = count + 1
            else
                table.insert(rowData, { v = currentValue, c = count })
                currentValue = tileMapData[row][col]
                count = 1
            end
        end
        
        table.insert(rowData, { v = currentValue, c = count })
        table.insert(tiles, rowData)
    end
    
    return tiles
end

-- 反序列化瓦片数据
function MapSerializer:DeserializeTiles(tilesData, width, height)
    local tileMap = {}
    
    for rowIndex, rowData in ipairs(tilesData) do
        tileMap[rowIndex] = {}
        local colIndex = 1
        
        for _, run in ipairs(rowData) do
            for i = 1, run.c do
                tileMap[rowIndex][colIndex] = run.v
                colIndex = colIndex + 1
            end
        end
    end
    
    return tileMap
end

-- 简单的 JSON 编码（实际项目中可使用外部库）
function MapSerializer:EncodeJSON(data)
    -- 简化实现，实际应使用完整 JSON 库
    local function serialize(val, indent)
        local t = type(val)
        
        if t == "nil" then
            return "null"
        elseif t == "boolean" or t == "number" then
            return tostring(val)
        elseif t == "string" then
            return string.format("%q", val)
        elseif t == "table" then
            local isArray = #val > 0
            local parts = {}
            local newIndent = indent .. "  "
            
            if isArray then
                for _, v in ipairs(val) do
                    table.insert(parts, newIndent .. serialize(v, newIndent))
                end
                return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
            else
                for k, v in pairs(val) do
                    table.insert(parts, newIndent .. string.format("%q", k) .. ": " .. serialize(v, newIndent))
                end
                return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
            end
        end
        
        return "null"
    end
    
    return serialize(data, "")
end

-- 简单的 JSON 解码
function MapSerializer:DecodeJSON(jsonStr)
    -- 简化实现，实际应使用完整 JSON 库
    -- 这里使用 Lua 的 loadstring 作为替代方案
    local func = loadstring("return " .. jsonStr:gsub('"', '"'))
    if func then
        return func()
    end
    return nil
end

-- 文件操作
function MapSerializer:WriteFile(filepath, content)
    -- 使用 Urho3D 的文件系统 API
    local file = FileSystem:GetProgramDir() .. filepath
    -- 实际实现...
    return true
end

function MapSerializer:ReadFile(filepath)
    -- 使用 Urho3D 的文件系统 API
    local file = FileSystem:GetProgramDir() .. filepath
    -- 实际实现...
    return nil
end

return MapSerializer
```

### 4.5 编辑器 UI (EditorUI)

```lua
-- EditorUI.lua
local EditorUI = {
    -- 布局配置
    LAYOUT = {
        TOP_BAR_HEIGHT = 40,
        SIDE_PANEL_WIDTH = 200,
        BOTTOM_BAR_HEIGHT = 30,
        PADDING = 10,
    },
    
    -- 颜色主题
    THEME = {
        background = { 30, 30, 40, 220 },
        panel = { 40, 40, 50, 200 },
        text = { 255, 255, 255, 230 },
        textDim = { 200, 200, 200, 150 },
        accent = { 255, 200, 100, 255 },
        button = { 60, 60, 70, 255 },
        buttonHover = { 80, 80, 90, 255 },
        buttonActive = { 100, 100, 110, 255 },
    },
}

function EditorUI:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function EditorUI:Render()
    -- 渲染顶部工具栏
    self:RenderTopBar()
    
    -- 渲染左侧调色板
    self:RenderPalette()
    
    -- 渲染底部状态栏
    self:RenderStatusBar()
    
    -- 渲染工具提示
    self:RenderTooltip()
end

function EditorUI:RenderTopBar()
    local h = self.LAYOUT.TOP_BAR_HEIGHT
    
    -- 背景
    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, logicalW, h)
    nvgFillColor(vg, nvgRGBA(unpack(self.THEME.background)))
    nvgFill(vg)
    
    -- 标题
    nvgFontSize(vg, 16)
    nvgFontFaceId(vg, fontNormal)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(unpack(self.THEME.accent)))
    nvgText(vg, 15, h / 2, "🗺️ 地图编辑器", nil)
    
    -- 工具按钮
    local tools = {
        { name = "brush", icon = "🖌️", tooltip = "画笔 (F1)" },
        { name = "eraser", icon = "🧹", tooltip = "橡皮" },
        { name = "fill", icon = "🪣", tooltip = "填充" },
        { name = "select", icon = "🔲", tooltip = "选择" },
        { name = "entity", icon = "📦", tooltip = "实体" },
    }
    
    local btnX = 140
    local btnSize = 28
    local btnGap = 5
    
    for _, tool in ipairs(tools) do
        local isActive = EditorCore.state.currentTool == tool.name
        local color = isActive and self.THEME.buttonActive or self.THEME.button
        
        -- 按钮背景
        nvgBeginPath(vg)
        nvgRoundedRect(vg, btnX, (h - btnSize) / 2, btnSize, btnSize, 4)
        nvgFillColor(vg, nvgRGBA(unpack(color)))
        nvgFill(vg)
        
        -- 图标
        nvgFontSize(vg, 14)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(unpack(self.THEME.text)))
        nvgText(vg, btnX + btnSize / 2, h / 2, tool.icon, nil)
        
        btnX = btnX + btnSize + btnGap
    end
    
    -- 画笔大小控制
    btnX = btnX + 20
    nvgFontSize(vg, 12)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(unpack(self.THEME.textDim)))
    nvgText(vg, btnX, h / 2, "大小: " .. EditorCore.state.brushSize, nil)
    
    -- 保存/加载按钮
    local actionX = logicalW - 100
    self:RenderButton(actionX, (h - 24) / 2, 40, 24, "保存", function() EditorCore:SaveMap() end)
    self:RenderButton(actionX + 50, (h - 24) / 2, 40, 24, "加载", function() EditorCore:LoadMap() end)
end

function EditorUI:RenderPalette()
    if not EditorCore.state.paletteOpen then return end
    
    local x = self.LAYOUT.PADDING
    local y = self.LAYOUT.TOP_BAR_HEIGHT + self.LAYOUT.PADDING
    local w = 160
    local tileSize = 36
    local gap = 5
    
    -- 面板背景
    local panelH = #TILE_PALETTE * (tileSize + gap) + 40
    nvgBeginPath(vg)
    nvgRoundedRect(vg, x - 5, y - 5, w + 10, panelH, 5)
    nvgFillColor(vg, nvgRGBA(unpack(self.THEME.panel)))
    nvgFill(vg)
    
    -- 标题
    nvgFontSize(vg, 12)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(unpack(self.THEME.textDim)))
    nvgText(vg, x, y, "瓦片调色板", nil)
    
    -- 瓦片按钮
    local tileY = y + 20
    for i, tile in ipairs(TILE_PALETTE) do
        local isSelected = (i - 1) == EditorCore.state.currentTileId
        
        -- 选中高亮
        if isSelected then
            nvgBeginPath(vg)
            nvgRoundedRect(vg, x - 3, tileY - 3, tileSize + 6, tileSize + 6, 3)
            nvgStrokeColor(vg, nvgRGBA(unpack(self.THEME.accent)))
            nvgStrokeWidth(vg, 2)
            nvgStroke(vg)
        end
        
        -- 瓦片预览
        nvgBeginPath(vg)
        nvgRoundedRect(vg, x, tileY, tileSize, tileSize, 3)
        nvgFillColor(vg, nvgRGBA(tile.color[1], tile.color[2], tile.color[3], 255))
        nvgFill(vg)
        
        -- 边框
        nvgStrokeColor(vg, nvgRGBA(100, 100, 100, 200))
        nvgStrokeWidth(vg, 1)
        nvgStroke(vg)
        
        -- 名称
        nvgFontSize(vg, 10)
        nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(unpack(self.THEME.text)))
        nvgText(vg, x + tileSize + 8, tileY + tileSize / 2, tile.name, nil)
        
        tileY = tileY + tileSize + gap
    end
end

function EditorUI:RenderStatusBar()
    local y = logicalH - self.LAYOUT.BOTTOM_BAR_HEIGHT
    
    -- 背景
    nvgBeginPath(vg)
    nvgRect(vg, 0, y, logicalW, self.LAYOUT.BOTTOM_BAR_HEIGHT)
    nvgFillColor(vg, nvgRGBA(unpack(self.THEME.background)))
    nvgFill(vg)
    
    -- 坐标信息
    local hoverCol = EditorCore.state.hoverCol or 0
    local hoverRow = EditorCore.state.hoverRow or 0
    local info = string.format("坐标: (%d, %d) | 世界: (%.1f, %.1f) | 缩放: %.1fx",
        hoverCol, hoverRow,
        EditorCore.state.hoverWorldX or 0,
        EditorCore.state.hoverWorldY or 0,
        EditorCore.camera and EditorCore.camera.zoom or 1.0
    )
    
    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(unpack(self.THEME.textDim)))
    nvgText(vg, 10, y + self.LAYOUT.BOTTOM_BAR_HEIGHT / 2, info, nil)
    
    -- 操作提示
    local hints = "F12:退出编辑器 | WASD:移动相机 | 滚轮:缩放 | Q/E:切换瓦片 | +/-:调整大小"
    nvgTextAlign(vg, NVG_ALIGN_RIGHT + NVG_ALIGN_MIDDLE)
    nvgText(vg, logicalW - 10, y + self.LAYOUT.BOTTOM_BAR_HEIGHT / 2, hints, nil)
end

function EditorUI:RenderButton(x, y, w, h, text, onClick)
    -- 简化的按钮渲染
    nvgBeginPath(vg)
    nvgRoundedRect(vg, x, y, w, h, 4)
    nvgFillColor(vg, nvgRGBA(unpack(self.THEME.button)))
    nvgFill(vg)
    
    nvgFontSize(vg, 11)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(unpack(self.THEME.text)))
    nvgText(vg, x + w / 2, y + h / 2, text, nil)
end

function EditorUI:RenderTooltip()
    -- 鼠标悬停提示
    -- 实现略...
end

return EditorUI
```

---

## 5. 集成指南

### 5.1 与现有代码集成

```lua
-- main.lua 修改

-- 1. 引入编辑器模块
require "scripts/editor/EditorCore"

-- 2. 修改 HandleUpdate 函数
function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()
    
    -- F12 切换编辑器
    if input:GetKeyPress(KEY_F12) then
        EditorCore:Toggle()
        return
    end
    
    -- 编辑器模式
    if EditorCore.enabled then
        EditorCore:Update(dt)
        return
    end
    
    -- 正常游戏更新（原有代码）
    gameTime = gameTime + dt
    dayTime = (gameTime / DAY_DURATION) % 1.0
    UpdatePlayerInput(dt)
    
    local camLerp = 1 - math.pow(0.001, dt)
    camX = camX + (player.worldX - camX) * camLerp
    camY = camY + (player.worldY - camY) * camLerp
end

-- 3. 修改 HandleNanoVGRender 函数
function HandleNanoVGRender(eventType, eventData)
    if vg == nil then return end
    
    nvgBeginFrame(vg, logicalW, logicalH, dpr)
    
    if EditorCore.enabled then
        -- 编辑器渲染
        DrawSky()
        EditorCore:Render()
    else
        -- 正常游戏渲染（原有代码）
        DrawSky()
        DrawGround()
        -- ... 其他绘制
        DrawHUD()
    end
    
    nvgEndFrame(vg)
end
```

### 5.2 文件结构

```
scripts/
├── main.lua                    # 入口（修改）
├── editor/                     # 编辑器模块（新增）
│   ├── EditorCore.lua
│   ├── EditorState.lua
│   ├── EditorCamera.lua
│   ├── EditorUI.lua
│   ├── BrushSystem.lua
│   ├── LayerManager.lua
│   ├── UndoRedo.lua
│   ├── MapSerializer.lua
│   └── tools/
│       ├── BaseTool.lua
│       ├── BrushTool.lua
│       ├── EraserTool.lua
│       ├── FillTool.lua
│       ├── SelectTool.lua
│       └── EntityTool.lua
└── [其他原有文件]
```

---

## 6. 开发计划

### 6.1 里程碑

| 阶段 | 功能 | 预计时间 |
|------|------|----------|
| **M1** | 基础框架 + 画笔/橡皮工具 | 3-5 天 |
| **M2** | 瓦片调色板 + 地图保存/加载 | 2-3 天 |
| **M3** | 多层编辑 + 撤销重做 | 3-4 天 |
| **M4** | 实体编辑 + 高级工具 | 4-5 天 |
| **M5** | UI 美化 + 性能优化 | 3-4 天 |

### 6.2 测试策略

- **单元测试**: 每个工具类独立测试
- **集成测试**: 完整编辑流程测试
- **性能测试**: 大地图（100x100）编辑性能
- **兼容性测试**: 不同分辨率/DPI 测试

---

## 7. 扩展性设计

### 7.1 自定义工具扩展

```lua
-- 自定义工具示例：噪声生成工具
local NoiseTool = setmetatable({}, { __index = BaseTool })

function NoiseTool:new()
    local obj = BaseTool:new("noise", "🌊", "噪声生成")
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function NoiseTool:OnPress(col, row)
    -- 使用 Simplex 噪声生成地形
    local noise = SimplexNoise:new()
    
    for dy = -5, 5 do
        for dx = -5, 5 do
            local value = noise:Sample(col + dx, row + dy)
            local tileId = value > 0.5 and 2 or (value > 0 and 1 or 0)
            EditorCore:SetTile(col + dx, row + dy, tileId)
        end
    end
end

-- 注册工具
EditorCore:RegisterTool(NoiseTool:new())
```

### 7.2 插件系统

```lua
-- 编辑器插件接口
local EditorPlugin = {
    name = "",
    version = "",
    
    OnInit = function(self) end,
    OnShutdown = function(self) end,
    OnEnable = function(self) end,
    OnDisable = function(self) end,
    OnUpdate = function(self, dt) end,
    OnRender = function(self) end,
    OnToolRegister = function(self, toolRegistry) end,
}
```

---

## 8. 性能考虑

### 8.1 优化策略

| 问题 | 解决方案 |
|------|----------|
| 大地图渲染 | 视锥裁剪 + 脏矩形更新 |
| 频繁撤销 | 操作合并（如拖拽绘制合并为一次操作） |
| UI 响应 | 异步保存/加载 |
| 内存占用 | 瓦片数据压缩存储 |

### 8.2 目标性能

- 编辑器启动时间 < 1 秒
- 瓦片绘制延迟 < 16ms
- 支持 100x100 地图流畅编辑
- 撤销历史 50 步无卡顿

---

## 9. 参考资源

- [Urho3D 输入系统文档](https://urho3d.io/documentation/1.7/_input.html)
- [NanoVG API 参考](https://github.com/memononen/nanovg)
- [Unity Tilemap 设计参考](https://docs.unity3d.com/Manual/Tilemap.html)
- [Tiled 地图编辑器](https://www.mapeditor.org/)

---

*文档版本: 1.0*
*最后更新: 2026-05-03*
*状态: 设计阶段，待实现*
