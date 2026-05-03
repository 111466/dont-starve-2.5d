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
-- 角色精灵图
-- ============================================================================
local spriteIdle = -1               -- idle 站立帧
local spriteWalk = {}               -- walk 动画帧数组 (4帧)
local WALK_FRAME_DURATION = 0.15    -- 每帧持续时间(秒)
local SPRITE_DRAW_W = 64            -- 绘制宽度(逻辑像素)
local SPRITE_DRAW_H = 80            -- 绘制高度(逻辑像素)

-- ============================================================================
-- 瓦片贴图
-- ============================================================================
local tileSprites = {
    grass1 = -1,
    grass2 = -1,
    dirt   = -1,
    stone  = -1,
}
-- 贴图实际像素尺寸 (129x72)，按菱形瓦片大小缩放绘制
local TILE_IMG_W = 0   -- 绘制宽度，在 Start 中根据 TILE_SIZE 计算
local TILE_IMG_H = 0   -- 绘制高度

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

-- 角色参数
local CHAR_SPEED = 120      -- 移动速度 (像素/秒)

-- 日夜循环
local DAY_DURATION = 60     -- 一天时长(秒)

-- ============================================================================
-- 游戏状态
-- ============================================================================
local gameTime = 0          -- 总游戏时间
local dayTime = 0.3         -- 当天时间 (0~1, 0.25=日出, 0.5=正午, 0.75=日落)

-- 相机
local camX, camY = 0, 0     -- 相机世界坐标(中心点)

-- 角色
local player = {
    worldX = GRID_COLS * TILE_SIZE / 2,   -- 世界坐标
    worldY = GRID_ROWS * TILE_SIZE / 2,
    facing = 1,           -- 朝向: 1=右, -1=左
    moving = false,
    moveAngle = 0,        -- 移动方向角度(弧度)
    animTime = 0,         -- 动画计时
    bobPhase = 0,         -- 走路弹跳相位
}

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

    -- 加载角色精灵图
    LoadCharacterSprites()

    -- 加载瓦片贴图
    LoadTileSprites()

    -- 计算瓦片贴图绘制尺寸 (菱形宽 = TILE_SIZE, 高 = TILE_SIZE * ISO_Y_SCALE)
    TILE_IMG_W = TILE_SIZE
    TILE_IMG_H = TILE_SIZE * ISO_Y_SCALE

    -- 初始化分辨率
    RecalcResolution()

    -- 生成地图
    GenerateMap()

    -- 初始化相机到玩家位置
    camX = player.worldX
    camY = player.worldY

    -- 初始化编辑器
    -- 如果要使用图集模式，取消下面一行的注释并指定图集路径和瓦片尺寸
    -- local atlasPath = "image/tile_atlas.png"
    -- local atlasTileSize = 16
    local atlasPath = nil
    local atlasTileSize = nil
    EditorCore:Init(vg, logicalW, logicalH, dpr, tileMap, GRID_COLS, GRID_ROWS, TILE_SIZE, ISO_Y_SCALE, tileSprites, atlasPath, atlasTileSize)

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
    print("WASD 移动角色")
    print("F12 切换编辑器模式")
end

function Stop()
    if vg ~= nil then
        nvgDelete(vg)
        vg = nil
    end
end

-- ============================================================================
-- 角色精灵图加载
-- ============================================================================

function LoadCharacterSprites()
    -- idle 帧
    spriteIdle = nvgCreateImage(vg, "image/char_idle_20260501123258.png", 0)
    if spriteIdle == -1 then
        print("WARNING: Failed to load idle sprite")
    else
        print("Loaded idle sprite, handle =", spriteIdle)
    end

    -- walk 帧 (4帧循环)
    local walkFiles = {
        "image/char_walk1_20260501123320.png",
        "image/char_walk2_20260501123309.png",
        "image/char_walk3_20260501123256.png",
        "image/char_walk4_20260501123306.png",
    }
    for i, path in ipairs(walkFiles) do
        local handle = nvgCreateImage(vg, path, 0)
        if handle == -1 then
            print("WARNING: Failed to load walk sprite " .. i)
        else
            print("Loaded walk sprite " .. i .. ", handle =", handle)
        end
        spriteWalk[i] = handle
    end
end

-- ============================================================================
-- 瓦片贴图加载
-- ============================================================================

function LoadTileSprites()
    local tileFiles = {
        { key = "grass1", path = "image/tile_grass1_20260502235946.png" },
        { key = "grass2", path = "image/tile_grass2_20260502235944.png" },
        { key = "dirt",   path = "image/tile_dirt_20260502235945.png" },
        { key = "stone",  path = "image/tile_stone_20260503000116.png" },
    }
    for _, item in ipairs(tileFiles) do
        local handle = nvgCreateImage(vg, item.path, 0)
        if handle == -1 then
            print("WARNING: Failed to load tile sprite: " .. item.path)
        else
            print("Loaded tile sprite [" .. item.key .. "], handle =", handle)
        end
        tileSprites[item.key] = handle
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
-- 地图生成
-- ============================================================================

function GenerateMap()
    math.randomseed(12345)

    -- 生成瓦片
    for row = 1, GRID_ROWS do
        tileMap[row] = {}
        for col = 1, GRID_COLS do
            -- 中心区域为泥土路径, 外围为草地
            local cx = col - GRID_COLS / 2
            local cy = row - GRID_ROWS / 2
            local dist = math.sqrt(cx * cx + cy * cy)

            if dist < 3 then
                tileMap[row][col] = 2  -- 石头路(中心)
            elseif dist < 5 and math.random() < 0.6 then
                tileMap[row][col] = 1  -- 泥土
            else
                tileMap[row][col] = 0  -- 草地
            end
        end
    end

    -- 生成装饰物(草丛、花、小石头)
    decorations = {}
    for i = 1, 80 do
        local dx = math.random() * GRID_COLS * TILE_SIZE
        local dy = math.random() * GRID_ROWS * TILE_SIZE
        -- 不在中心太密集
        local cx = dx - GRID_COLS * TILE_SIZE / 2
        local cy = dy - GRID_ROWS * TILE_SIZE / 2
        if math.sqrt(cx * cx + cy * cy) > 120 then
            local dtype = math.random(1, 4)  -- 1=高草, 2=花, 3=小石头, 4=蘑菇
            table.insert(decorations, {
                x = dx, y = dy,
                type = dtype,
                scale = 0.7 + math.random() * 0.6,
                swayPhase = math.random() * math.pi * 2,
            })
        end
    end

    print("Map generated: " .. GRID_COLS .. "x" .. GRID_ROWS .. " tiles, " .. #decorations .. " decorations")
end

-- ============================================================================
-- 游戏逻辑更新
-- ============================================================================

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()
    gameTime = gameTime + dt

    -- 日夜循环
    dayTime = (gameTime / DAY_DURATION) % 1.0

    -- 处理输入
    if not EditorCore.enabled then
        UpdatePlayerInput(dt)
    end

    -- 编辑器更新
    EditorCore:Update(dt, input, logicalW, logicalH)

    -- 相机平滑跟随
    if not EditorCore.enabled then
        local camLerp = 1 - math.pow(0.001, dt)
        camX = camX + (player.worldX - camX) * camLerp
        camY = camY + (player.worldY - camY) * camLerp
    end
end

function UpdatePlayerInput(dt)
    local dx, dy = 0, 0

    if input:GetKeyDown(KEY_W) or input:GetKeyDown(KEY_UP) then dy = dy - 1 end
    if input:GetKeyDown(KEY_S) or input:GetKeyDown(KEY_DOWN) then dy = dy + 1 end
    if input:GetKeyDown(KEY_A) or input:GetKeyDown(KEY_LEFT) then dx = dx - 1 end
    if input:GetKeyDown(KEY_D) or input:GetKeyDown(KEY_RIGHT) then dx = dx + 1 end

    player.moving = (dx ~= 0 or dy ~= 0)

    if player.moving then
        -- 归一化方向
        local len = math.sqrt(dx * dx + dy * dy)
        dx = dx / len
        dy = dy / len

        player.moveAngle = math.atan(dy, dx)

        -- 更新朝向 (左/右)
        if dx > 0.1 then
            player.facing = 1
        elseif dx < -0.1 then
            player.facing = -1
        end

        -- 移动
        player.worldX = player.worldX + dx * CHAR_SPEED * dt
        player.worldY = player.worldY + dy * CHAR_SPEED * dt

        -- 限制在地图范围内
        local margin = 20
        player.worldX = math.max(margin, math.min(GRID_COLS * TILE_SIZE - margin, player.worldX))
        player.worldY = math.max(margin, math.min(GRID_ROWS * TILE_SIZE - margin, player.worldY))

        -- 动画计时
        player.animTime = player.animTime + dt
        player.bobPhase = player.bobPhase + dt * 10
    else
        player.animTime = 0
        -- 缓慢回到静止弹跳
        player.bobPhase = player.bobPhase * 0.9
    end
end

-- ============================================================================
-- 坐标转换: 世界坐标 → 屏幕坐标
-- ============================================================================

function WorldToScreen(wx, wy)
    -- 相对于相机
    local rx = wx - camX
    local ry = wy - camY
    -- 等距投影: Y 轴压缩
    local sx = logicalW / 2 + rx
    local sy = logicalH / 2 + ry * ISO_Y_SCALE
    return sx, sy
end

-- ============================================================================
-- NanoVG 渲染
-- ============================================================================

function HandleNanoVGRender(eventType, eventData)
    if vg == nil then return end

    nvgBeginFrame(vg, logicalW, logicalH, dpr)

    if EditorCore.enabled then
        -- 编辑器模式: 使用编辑器自己的渲染
        EditorCore:Render(vg, logicalW, logicalH)
    else
        -- 游戏模式
        -- 1. 天空背景(日夜循环)
        DrawSky()

        -- 2. 地面瓦片
        DrawGround()

        -- 3. 收集需要排序的可绘制对象(按 Y 排序实现遮挡)
        local drawables = {}

        -- 装饰物
        for i, dec in ipairs(decorations) do
            table.insert(drawables, {
                y = dec.y,
                type = "decoration",
                data = dec,
            })
        end

        -- 玩家
        table.insert(drawables, {
            y = player.worldY,
            type = "player",
        })

        -- Y 排序
        table.sort(drawables, function(a, b) return a.y < b.y end)

        -- 4. 按顺序绘制
        for _, obj in ipairs(drawables) do
            if obj.type == "decoration" then
                DrawDecoration(obj.data)
            elseif obj.type == "player" then
                DrawPlayer()
            end
        end

        -- 5. 日夜光照叠加
        DrawLighting()

        -- 6. HUD
        DrawHUD()
    end

    nvgEndFrame(vg)
end

-- ============================================================================
-- 天空绘制
-- ============================================================================

function DrawSky()
    -- 根据 dayTime 计算天空颜色
    local r, g, b = GetSkyColor(dayTime)
    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, logicalW, logicalH)
    nvgFillColor(vg, nvgRGBA(r, g, b, 255))
    nvgFill(vg)
end

function GetSkyColor(t)
    -- t: 0~1, 0.25=日出, 0.5=正午, 0.75=日落
    -- 颜色过渡: 夜晚→日出→白天→日落→夜晚
    local colors = {
        {0.00, 15, 15, 35},      -- 午夜
        {0.20, 25, 20, 50},      -- 凌晨
        {0.25, 120, 80, 60},     -- 日出
        {0.35, 135, 185, 220},   -- 上午
        {0.50, 145, 200, 235},   -- 正午
        {0.65, 135, 185, 220},   -- 下午
        {0.75, 150, 90, 50},     -- 日落
        {0.82, 40, 30, 60},      -- 黄昏
        {1.00, 15, 15, 35},      -- 午夜
    }

    -- 找到区间并插值
    for i = 1, #colors - 1 do
        if t >= colors[i][1] and t < colors[i + 1][1] then
            local frac = (t - colors[i][1]) / (colors[i + 1][1] - colors[i][1])
            local r = math.floor(colors[i][2] + (colors[i + 1][2] - colors[i][2]) * frac)
            local g = math.floor(colors[i][3] + (colors[i + 1][3] - colors[i][3]) * frac)
            local b = math.floor(colors[i][4] + (colors[i + 1][4] - colors[i][4]) * frac)
            return r, g, b
        end
    end
    return 15, 15, 35
end

-- ============================================================================
-- 地面绘制
-- ============================================================================

function DrawGround()
    -- 计算可见范围
    local margin = TILE_SIZE * 2
    local startCol = math.max(1, math.floor((camX - logicalW / 2 - margin) / TILE_SIZE) + 1)
    local endCol = math.min(GRID_COLS, math.ceil((camX + logicalW / 2 + margin) / TILE_SIZE) + 1)
    local startRow = math.max(1, math.floor((camY - logicalH / ISO_Y_SCALE / 2 - margin) / TILE_SIZE) + 1)
    local endRow = math.min(GRID_ROWS, math.ceil((camY + logicalH / ISO_Y_SCALE / 2 + margin) / TILE_SIZE) + 1)

    for row = startRow, endRow do
        for col = startCol, endCol do
            local tileType = tileMap[row] and tileMap[row][col] or 0
            local wx = (col - 1) * TILE_SIZE + TILE_SIZE / 2
            local wy = (row - 1) * TILE_SIZE + TILE_SIZE / 2
            local sx, sy = WorldToScreen(wx, wy)

            DrawTile(sx, sy, tileType, col, row)
        end
    end
end

function DrawTile(sx, sy, tileType, col, row)
    -- 选择瓦片贴图
    local spriteHandle = -1

    if tileType == 0 then
        -- 草地: 基于坐标哈希选择 grass1 或 grass2
        if (col * 7 + row * 13) % 2 == 0 then
            spriteHandle = tileSprites.grass1
        else
            spriteHandle = tileSprites.grass2
        end
    elseif tileType == 1 then
        spriteHandle = tileSprites.dirt
    else
        spriteHandle = tileSprites.stone
    end

    -- 绘制尺寸: 菱形瓦片的外接矩形
    local w = TILE_IMG_W
    local h = TILE_IMG_H

    if spriteHandle ~= -1 then
        -- 用贴图绘制
        local drawX = sx - w / 2
        local drawY = sy - h / 2

        local imgPaint = nvgImagePattern(vg, drawX, drawY, w, h, 0, spriteHandle, 1.0)
        nvgBeginPath(vg)
        nvgRect(vg, drawX, drawY, w, h)
        nvgFillPaint(vg, imgPaint)
        nvgFill(vg)
    else
        -- 贴图加载失败时的 fallback: 程序化纯色菱形
        local hw = TILE_SIZE / 2
        local hh = TILE_SIZE * ISO_Y_SCALE / 2
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

-- ============================================================================
-- 装饰物绘制
-- ============================================================================

function DrawDecoration(dec)
    local sx, sy = WorldToScreen(dec.x, dec.y)

    -- 可见性裁剪
    if sx < -50 or sx > logicalW + 50 or sy < -50 or sy > logicalH + 50 then
        return
    end

    local s = dec.scale
    -- 风吹摇摆
    local sway = math.sin(gameTime * 1.5 + dec.swayPhase) * 2 * s

    if dec.type == 1 then
        -- 高草
        DrawTallGrass(sx, sy, s, sway)
    elseif dec.type == 2 then
        -- 花
        DrawFlower(sx, sy, s, sway)
    elseif dec.type == 3 then
        -- 小石头
        DrawSmallRock(sx, sy, s)
    elseif dec.type == 4 then
        -- 蘑菇
        DrawMushroom(sx, sy, s, sway)
    end
end

function DrawTallGrass(sx, sy, s, sway)
    -- 赛璐璐风格: 粗描边, 平涂
    local bladeCount = 3
    for i = 1, bladeCount do
        local ox = (i - 2) * 5 * s
        local h = (20 + i * 4) * s

        -- 描边
        nvgBeginPath(vg)
        nvgMoveTo(vg, sx + ox, sy)
        nvgQuadTo(vg, sx + ox + sway, sy - h * 0.6, sx + ox + sway * 1.5, sy - h)
        nvgStrokeColor(vg, nvgRGBA(30, 50, 20, 255))
        nvgStrokeWidth(vg, 3 * s)
        nvgStroke(vg)

        -- 填色线
        nvgBeginPath(vg)
        nvgMoveTo(vg, sx + ox, sy)
        nvgQuadTo(vg, sx + ox + sway, sy - h * 0.6, sx + ox + sway * 1.5, sy - h)
        nvgStrokeColor(vg, nvgRGBA(80, 160, 60, 255))
        nvgStrokeWidth(vg, 1.5 * s)
        nvgStroke(vg)
    end
end

function DrawFlower(sx, sy, s, sway)
    local stemH = 18 * s
    local petalR = 4 * s

    -- 茎(描边)
    nvgBeginPath(vg)
    nvgMoveTo(vg, sx, sy)
    nvgQuadTo(vg, sx + sway * 0.5, sy - stemH * 0.6, sx + sway, sy - stemH)
    nvgStrokeColor(vg, nvgRGBA(30, 80, 20, 255))
    nvgStrokeWidth(vg, 2.5 * s)
    nvgStroke(vg)

    -- 花瓣中心位置
    local fx = sx + sway
    local fy = sy - stemH

    -- 花瓣(描边 + 填充)
    local petalColors = {
        {255, 200, 80},
        {255, 120, 100},
        {200, 150, 255},
    }
    local ci = math.floor(sx + sy) % 3 + 1
    local pc = petalColors[ci]
    local pcR, pcG, pcB = pc[1], pc[2], pc[3]

    for angle = 0, 4 do
        local a = angle * math.pi * 2 / 5
        local px = fx + math.cos(a) * petalR
        local py = fy + math.sin(a) * petalR * 0.7

        nvgBeginPath(vg)
        nvgCircle(vg, px, py, petalR * 0.6)
        nvgFillColor(vg, nvgRGBA(pcR, pcG, pcB, 255))
        nvgFill(vg)
        nvgStrokeColor(vg, nvgRGBA(40, 40, 40, 200))
        nvgStrokeWidth(vg, 1.2 * s)
        nvgStroke(vg)
    end

    -- 花心
    nvgBeginPath(vg)
    nvgCircle(vg, fx, fy, petalR * 0.4)
    nvgFillColor(vg, nvgRGBA(255, 230, 100, 255))
    nvgFill(vg)
end

function DrawSmallRock(sx, sy, s)
    -- 石头(不规则椭圆)
    nvgSave(vg)
    nvgTranslate(vg, sx, sy)
    nvgScale(vg, s, s)

    -- 阴影
    nvgBeginPath(vg)
    nvgEllipse(vg, 2, 2, 10, 5)
    nvgFillColor(vg, nvgRGBA(0, 0, 0, 40))
    nvgFill(vg)

    -- 石头本体
    nvgBeginPath(vg)
    nvgEllipse(vg, 0, -3, 9, 7)
    nvgFillColor(vg, nvgRGBA(160, 155, 145, 255))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(80, 75, 70, 255))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)

    -- 高光
    nvgBeginPath(vg)
    nvgEllipse(vg, -2, -6, 4, 2.5)
    nvgFillColor(vg, nvgRGBA(200, 195, 185, 180))
    nvgFill(vg)

    nvgRestore(vg)
end

function DrawMushroom(sx, sy, s, sway)
    nvgSave(vg)
    nvgTranslate(vg, sx, sy)
    nvgScale(vg, s, s)

    local stemH = 10
    local capR = 8

    -- 茎
    nvgBeginPath(vg)
    nvgRoundedRect(vg, -3 + sway * 0.3, -stemH, 6, stemH, 2)
    nvgFillColor(vg, nvgRGBA(230, 220, 200, 255))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(60, 50, 40, 255))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)

    -- 伞帽
    nvgBeginPath(vg)
    nvgArc(vg, sway * 0.5, -stemH, capR, math.pi, 0, 1)  -- NVG_CW = 1
    nvgClosePath(vg)
    nvgFillColor(vg, nvgRGBA(200, 50, 50, 255))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(60, 20, 20, 255))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)

    -- 白色斑点
    nvgBeginPath(vg)
    nvgCircle(vg, -3 + sway * 0.5, -stemH - 3, 2)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 220))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgCircle(vg, 3 + sway * 0.5, -stemH - 1, 1.5)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 220))
    nvgFill(vg)

    nvgRestore(vg)
end

-- ============================================================================
-- 角色绘制 (精灵图帧动画)
-- ============================================================================

function DrawPlayer()
    local sx, sy = WorldToScreen(player.worldX, player.worldY)

    -- 选择当前帧
    local spriteHandle = spriteIdle
    if player.moving and #spriteWalk > 0 then
        -- 根据动画时间选择 walk 帧
        local frameIndex = math.floor(player.animTime / WALK_FRAME_DURATION) % #spriteWalk + 1
        if spriteWalk[frameIndex] and spriteWalk[frameIndex] ~= -1 then
            spriteHandle = spriteWalk[frameIndex]
        end
    end

    -- 走路弹跳偏移
    local bob = 0
    if player.moving then
        bob = math.sin(player.bobPhase) * 2
    end

    -- ---- 地面阴影 ----
    nvgBeginPath(vg)
    nvgEllipse(vg, sx, sy, 18, 7)
    nvgFillColor(vg, nvgRGBA(0, 0, 0, 50))
    nvgFill(vg)

    -- ---- 绘制精灵图 ----
    if spriteHandle ~= -1 then
        local w = SPRITE_DRAW_W
        local h = SPRITE_DRAW_H
        -- 锚点在脚底中心
        local drawX = sx - w / 2
        local drawY = sy - h + bob

        nvgSave(vg)

        -- 水平翻转: facing=-1 时镜像
        if player.facing == -1 then
            -- 以角色中心为轴翻转
            nvgTranslate(vg, sx, 0)
            nvgScale(vg, -1, 1)
            nvgTranslate(vg, -sx, 0)
        end

        -- 用 nvgImagePattern 绘制精灵
        local imgPaint = nvgImagePattern(vg, drawX, drawY, w, h, 0, spriteHandle, 1.0)
        nvgBeginPath(vg)
        nvgRect(vg, drawX, drawY, w, h)
        nvgFillPaint(vg, imgPaint)
        nvgFill(vg)

        nvgRestore(vg)
    end
end

-- ============================================================================
-- 光照系统
-- ============================================================================

function DrawLighting()
    -- 计算光照强度 (0=全暗, 1=全亮)
    local brightness = GetDayBrightness(dayTime)

    -- 全局暗化叠加
    if brightness < 1.0 then
        local darkness = math.floor((1.0 - brightness) * 180)
        nvgBeginPath(vg)
        nvgRect(vg, 0, 0, logicalW, logicalH)
        nvgFillColor(vg, nvgRGBA(10, 10, 30, darkness))
        nvgFill(vg)

        -- 玩家周围的光源(手电/火把效果)
        if brightness < 0.5 then
            local px, py = WorldToScreen(player.worldX, player.worldY)
            local lightRadius = 120 + math.sin(gameTime * 3) * 8  -- 火焰闪烁

            -- 暖色光晕
            local lightGrad = nvgRadialGradient(vg, px, py - 15, lightRadius * 0.2, lightRadius,
                nvgRGBA(255, 200, 100, math.floor((1 - brightness) * 120)),
                nvgRGBA(255, 150, 50, 0))

            nvgBeginPath(vg)
            nvgCircle(vg, px, py - 15, lightRadius)
            nvgFillPaint(vg, lightGrad)
            nvgFill(vg)

            -- 反向遮罩 - 光圈外更暗
            local maskGrad = nvgRadialGradient(vg, px, py - 15, lightRadius * 0.8, lightRadius * 2,
                nvgRGBA(0, 0, 0, 0),
                nvgRGBA(5, 5, 20, math.floor((1 - brightness) * 100)))

            nvgBeginPath(vg)
            nvgRect(vg, 0, 0, logicalW, logicalH)
            nvgFillPaint(vg, maskGrad)
            nvgFill(vg)
        end
    end

    -- 日出/日落时的暖色渐变
    if dayTime > 0.22 and dayTime < 0.3 then
        local frac = (dayTime - 0.22) / 0.08
        local alpha = math.floor(math.sin(frac * math.pi) * 40)
        nvgBeginPath(vg)
        nvgRect(vg, 0, 0, logicalW, logicalH)
        nvgFillColor(vg, nvgRGBA(255, 180, 80, alpha))
        nvgFill(vg)
    elseif dayTime > 0.72 and dayTime < 0.8 then
        local frac = (dayTime - 0.72) / 0.08
        local alpha = math.floor(math.sin(frac * math.pi) * 50)
        nvgBeginPath(vg)
        nvgRect(vg, 0, 0, logicalW, logicalH)
        nvgFillColor(vg, nvgRGBA(255, 120, 50, alpha))
        nvgFill(vg)
    end
end

function GetDayBrightness(t)
    -- 0~1 映射到亮度
    -- 白天(0.3~0.7) = 1.0
    -- 夜晚(0.85~0.15) = 0.15
    -- 过渡平滑
    if t >= 0.3 and t <= 0.7 then
        return 1.0
    elseif t >= 0.85 or t <= 0.15 then
        return 0.15
    elseif t > 0.15 and t < 0.3 then
        return 0.15 + (t - 0.15) / 0.15 * 0.85
    else
        return 1.0 - (t - 0.7) / 0.15 * 0.85
    end
end

-- ============================================================================
-- HUD 绘制
-- ============================================================================

function DrawHUD()
    nvgFontFaceId(vg, fontNormal)

    -- 时间显示(左上角)
    local hour = math.floor(dayTime * 24)
    local minute = math.floor((dayTime * 24 - hour) * 60)
    local timeStr = string.format("%02d:%02d", hour, minute)

    -- 背景框
    nvgBeginPath(vg)
    nvgRoundedRect(vg, 10, 10, 100, 36, 8)
    nvgFillColor(vg, nvgRGBA(0, 0, 0, 150))
    nvgFill(vg)

    -- 时间图标(太阳/月亮)
    local brightness = GetDayBrightness(dayTime)
    if brightness > 0.5 then
        -- 太阳
        nvgBeginPath(vg)
        nvgCircle(vg, 28, 28, 8)
        nvgFillColor(vg, nvgRGBA(255, 220, 80, 255))
        nvgFill(vg)
    else
        -- 月亮
        nvgBeginPath(vg)
        nvgCircle(vg, 28, 28, 7)
        nvgFillColor(vg, nvgRGBA(220, 220, 240, 255))
        nvgFill(vg)
        nvgBeginPath(vg)
        nvgCircle(vg, 31, 26, 5)
        nvgFillColor(vg, nvgRGBA(0, 0, 0, 150))
        nvgFill(vg)
    end

    -- 时间文字
    nvgFontSize(vg, 16)
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 230))
    nvgText(vg, 44, 28, timeStr, nil)

    -- 操作提示(底部)
    nvgFontSize(vg, 13)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_BOTTOM)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 150))
    local hintText = EditorCore.enabled and "编辑器模式: WASD移动视角 滚轮缩放 左键绘制 右键擦除 F12退出" or "WASD / 方向键 移动 | F12 编辑器"
    nvgText(vg, logicalW / 2, logicalH - 12, hintText, nil)
end

-- ============================================================================
-- 输入事件处理
-- ============================================================================

function HandleMouseButtonDown(eventType, eventData)
    local button = eventData["Button"]:GetInt()
    local x = eventData["X"]:GetInt()
    local y = eventData["Y"]:GetInt()

    if EditorCore.enabled then
        EditorCore:UpdateMouse(x, y)
        EditorCore:HandleMousePress(x, y, button)
    end
end

function HandleMouseMove(eventType, eventData)
    local x = eventData["X"]:GetInt()
    local y = eventData["Y"]:GetInt()
    local buttons = eventData["Buttons"]:GetInt()

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
