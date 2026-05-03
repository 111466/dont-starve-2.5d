-- ====================================================================
-- 饥荒风格 2.5D 游戏框架
-- ====================================================================
-- 技术栈: 纯 NanoVG 矢量绘图, 无 3D 模型
-- 风格: Q版赛璐璐 (粗描边 + 平涂 + 明暗分区)
-- 视角: 2.5D 俯视 3/4 角度
-- 分辨率: 模式 B (系统逻辑分辨率 + DPR 修正)
-- ====================================================================

require "LuaScripts/Utilities/Sample"

-- ============================================================================
-- 编辑器
-- ============================================================================
local EditorCore = require("scripts/editor/EditorCore")

-- ============================================================================
-- NanoVG 上下文 & 字体
-- ============================================================================
local vg = nil
local fontNormal = -1

-- ============================================================================
-- 瓦片贴图
-- ============================================================================
local tileSprites = {
    grass1 = -1,
    grass2 = -1,
    dirt   = -1,
    stone  = -1,
}
local tileImageEntries = {}

local IMAGE_EXTENSIONS = {
    png = true,
    jpg = true,
    jpeg = true,
    gif = true,
    webp = true,
}

-- ============================================================================
-- 分辨率变量 (模式 B)
-- ============================================================================
local physW, physH = 0, 0
local dpr = 1.0
local logicalW, logicalH = 0, 0

-- ============================================================================
-- 游戏世界常量
-- ============================================================================

-- 等距投影参数 (2.5D)
-- Y 轴压缩比例, 饥荒风格大约 0.5~0.6
local ISO_Y_SCALE = 0.55

-- 地面瓦片
local TILE_SIZE = 64        -- 世界空间瓦片大小(像素)
local GRID_COLS = 24        -- 地图列数
local GRID_ROWS = 24        -- 地图行数

-- 地图数据: 0=草地, 1=泥土, 2=石头路
local tileMap = {}

-- 装饰物 (草丛、花等)
local decorations = {}

-- ============================================================================
-- 初始化
-- ============================================================================

function Start()
    SampleStart()

    -- 创建 NanoVG 上下文
    vg = nvgCreate(1)
    if vg == nil then
        print("ERROR: Failed to create NanoVG context")
        return
    end
    print("NanoVG context created")

    -- 加载字体
    fontNormal = nvgCreateFont(vg, "sans", "Fonts/MiSans-Regular.ttf")
    if fontNormal == -1 then
        print("ERROR: Failed to load font")
        return
    end
    print("Font loaded, fontId =", fontNormal)

    -- 加载瓦片贴图
    LoadTileSprites()

    -- 初始化分辨率
    RecalcResolution()

    -- 初始化空地图数据
    InitializeMapData()

    -- 初始化编辑器
    EditorCore:Init(vg, logicalW, logicalH, dpr, fontNormal, tileMap, GRID_COLS, GRID_ROWS, TILE_SIZE, ISO_Y_SCALE, tileSprites, tileImageEntries, decorations)

    -- 鼠标模式
    SampleInitMouseMode(MM_FREE)

    -- 订阅事件
    SubscribeToEvent(vg, "NanoVGRender", "HandleNanoVGRender")
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("ScreenMode", "HandleScreenMode")
    SubscribeToEvent("MouseButtonDown", "HandleMouseButtonDown")
    SubscribeToEvent("MouseButtonUp", "HandleMouseButtonUp")
    SubscribeToEvent("MouseMove", "HandleMouseMove")
    SubscribeToEvent("KeyDown", "HandleKeyDown")

    print("=== 饥荒风格 2.5D 游戏已启动 ===")
    print("当前只保留地图编辑器渲染")
    print("F12 切换编辑器模式")
end

function Stop()
    if vg ~= nil then
        nvgDelete(vg)
        vg = nil
    end
end

-- ============================================================================
-- 瓦片贴图加载
-- ============================================================================

function LoadTileSprites()
    tileImageEntries = {}
    tileSprites.grass1 = -1
    tileSprites.grass2 = -1
    tileSprites.dirt = -1
    tileSprites.stone = -1

    local function GuessKeyFromFilename(filename)
        local lower = string.lower(filename)
        if string.find(lower, "grass1", 1, true) then
            return "grass1", 0, {85, 150, 65}, "草地1"
        elseif string.find(lower, "dirt", 1, true) then
            return "dirt", 1, {150, 115, 75}, "泥土"
        elseif string.find(lower, "stone", 1, true) then
            return "stone", 2, {160, 155, 145}, "石头"
        elseif string.find(lower, "grass2", 1, true) then
            return "grass2", 3, {75, 140, 60}, "草地2"
        end
        return nil, nil, {128, 128, 128}, filename
    end

    local function MakeDisplayName(filename)
        local name = filename:gsub("%.[^%.]+$", "")
        name = name:gsub("_%d+$", "")
        name = name:gsub("_", " ")
        name = name:gsub("-", " ")
        return name
    end

    local function ExtractFilename(resourcePath)
        return resourcePath:match("([^/\\]+)$") or resourcePath
    end

    local function AddTileImage(resourcePath, seenPaths)
        if seenPaths[resourcePath] then
            return false
        end

        local handle = nvgCreateImage(vg, resourcePath, 0)
        if handle == -1 then
            return false
        end

        seenPaths[resourcePath] = true

        local filename = ExtractFilename(resourcePath)
        local width, height = nvgImageSize(vg, handle)
        local key, tileId, color, guessedName = GuessKeyFromFilename(filename)
        local displayName = guessedName
        if not key then
            displayName = MakeDisplayName(filename)
        end

        table.insert(tileImageEntries, {
            key = key,
            name = displayName,
            path = resourcePath,
            handle = handle,
            width = width,
            height = height,
            tileId = tileId,
            color = color,
        })

        if key and tileSprites[key] == -1 then
            tileSprites[key] = handle
        end

        print("Loaded editor image [" .. filename .. "], handle =", handle)
        return true
    end

    local knownTilePaths = {
        "image/tile_grass1_20260502235946.png",
        "image/tile_grass1_20260502235438.png",
        "image/tile_grass2_20260502235944.png",
        "image/tile_grass2_20260502235931.png",
        "image/tile_dirt_20260502235945.png",
        "image/tile_dirt_20260502235434.png",
        "image/tile_stone_20260503000116.png",
        "image/tile_stone_20260502235433.png",
    }

    local seenPaths = {}
    for _, resourcePath in ipairs(knownTilePaths) do
        AddTileImage(resourcePath, seenPaths)
    end

    if #tileImageEntries == 0 then
        print("WARNING: No tile images loaded; using fallback colors for ground and palette")
    end
end

-- ============================================================================
-- 分辨率处理
-- ============================================================================

function RecalcResolution()
    physW = graphics:GetWidth()
    physH = graphics:GetHeight()
    dpr = graphics:GetDPR()
    logicalW = physW / dpr
    logicalH = physH / dpr
    print("Resolution: physical=" .. physW .. "x" .. physH .. " dpr=" .. dpr .. " logical=" .. logicalW .. "x" .. logicalH)
end

function HandleScreenMode(eventType, eventData)
    RecalcResolution()
end

-- ============================================================================
-- 地图数据初始化
-- ============================================================================

function InitializeMapData()
    for row = 1, GRID_ROWS do
        tileMap[row] = {}
        for col = 1, GRID_COLS do
            tileMap[row][col] = 0
        end
    end

    decorations = {}
    print("Map initialized: " .. GRID_COLS .. "x" .. GRID_ROWS .. " empty tiles")
end

-- ============================================================================
-- 游戏逻辑更新
-- ============================================================================

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()

    -- 编辑器更新
    EditorCore:Update(dt, input, logicalW, logicalH)
end

-- ============================================================================
-- NanoVG 渲染
-- ============================================================================

function HandleNanoVGRender(eventType, eventData)
    if vg == nil then return end

    nvgBeginFrame(vg, logicalW, logicalH, dpr)

    if EditorCore.enabled then
        EditorCore:Render(vg, logicalW, logicalH)
    else
        DrawEditorPrompt()
    end

    nvgEndFrame(vg)
end

-- ============================================================================
-- 非编辑器提示
-- ============================================================================

function DrawEditorPrompt()
    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, logicalW, logicalH)
    nvgFillColor(vg, nvgRGBA(22, 24, 30, 255))
    nvgFill(vg)
    nvgFontFaceId(vg, fontNormal)
    nvgFontSize(vg, 18)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 220))
    nvgText(vg, logicalW / 2, logicalH / 2 - 10, "当前无主场景地图直绘", nil)

    nvgFontSize(vg, 14)
    nvgFillColor(vg, nvgRGBA(200, 200, 200, 180))
    nvgText(vg, logicalW / 2, logicalH / 2 + 18, "按 F12 进入地图编辑器", nil)
end

local function ToLogicalMousePosition(x, y)
    if dpr == nil or dpr == 0 then
        return x, y
    end
    return x / dpr, y / dpr
end

-- ============================================================================
-- 输入事件处理
-- ============================================================================

function HandleMouseButtonDown(eventType, eventData)
    local button = eventData["Button"]:GetInt()
    local x = eventData["X"]:GetInt()
    local y = eventData["Y"]:GetInt()
    x, y = ToLogicalMousePosition(x, y)

    if EditorCore.enabled then
        EditorCore:UpdateMouse(x, y)
        EditorCore:HandleMousePress(x, y, button)
    end
end

function HandleMouseMove(eventType, eventData)
    local x = eventData["X"]:GetInt()
    local y = eventData["Y"]:GetInt()
    local buttons = eventData["Buttons"]:GetInt()
    x, y = ToLogicalMousePosition(x, y)

    if EditorCore.enabled then
        EditorCore:UpdateMouse(x, y)
        if buttons ~= 0 then
            EditorCore:HandleMouseDrag(x, y, buttons)
        end
    end
end

function HandleMouseButtonUp(eventType, eventData)
    local button = eventData["Button"]:GetInt()
    local x = eventData["X"]:GetInt()
    local y = eventData["Y"]:GetInt()
    x, y = ToLogicalMousePosition(x, y)

    if EditorCore.enabled then
        EditorCore:HandleMouseRelease(x, y, button)
    end
end

function HandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()

    if key == KEY_F12 then
        EditorCore:Toggle()
        return
    end

    if EditorCore.enabled then
        EditorCore:HandleKeyPress(key)
    end
end
