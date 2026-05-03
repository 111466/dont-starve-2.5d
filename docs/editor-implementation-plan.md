# 可视化地图编辑器 - 分步实施计划

## 文档信息

- **版本**: 1.0
- **日期**: 2026-05-03
- **状态**: 实施计划
- **预估总工期**: 15-20 天
- **依赖文档**: [visual-editor-development.md](visual-editor-development.md)

---

## 实施策略

采用**增量开发**策略，每个阶段产出可运行的版本，逐步叠加功能。

```
阶段 1: 基础框架 ──► 阶段 2: 核心编辑 ──► 阶段 3: 高级功能 ──► 阶段 4:  polish
   (3-4天)           (4-5天)             (4-5天)              (3-4天)
```

---

## 阶段 1: 基础框架搭建（第 1-4 天）

### 目标
建立编辑器模块结构，实现模式切换和基础相机控制。

### 第 1 天: 项目结构搭建

**任务清单**:
- [ ] 创建 `scripts/editor/` 目录
- [ ] 创建空模块文件框架
- [ ] 修改 `main.lua` 添加编辑器引入点

**文件变更**:
```
scripts/
├── main.lua                          [修改]
└── editor/
    ├── EditorCore.lua                [新建 - 空框架]
    ├── EditorState.lua               [新建 - 空框架]
    ├── EditorCamera.lua              [新建 - 空框架]
    └── EditorUI.lua                  [新建 - 空框架]
```

**代码实现**:
```lua
-- scripts/editor/EditorCore.lua (Day 1 版本)
local EditorCore = {
    enabled = false,
}

function EditorCore:Toggle()
    self.enabled = not self.enabled
    print("[Editor] " .. (self.enabled and "Enabled" or "Disabled"))
end

return EditorCore
```

**验证标准**:
- [ ] 按 F12 能在控制台看到切换日志
- [ ] 游戏正常运行不受影响

---

### 第 2 天: 编辑器相机系统

**任务清单**:
- [ ] 实现 `EditorCamera` 类
- [ ] 支持 WASD 平移
- [ ] 支持滚轮缩放
- [ ] 坐标转换函数

**代码实现**:
```lua
-- scripts/editor/EditorCamera.lua
local EditorCamera = {
    position = { x = 0, y = 0 },
    zoom = 1.0,
    minZoom = 0.3,
    maxZoom = 3.0,
    panSpeed = 300,
}

function EditorCamera:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function EditorCamera:Update(dt)
    local speed = self.panSpeed * dt / self.zoom
    
    if input:GetKeyDown(KEY_W) then self.position.y = self.position.y - speed end
    if input:GetKeyDown(KEY_S) then self.position.y = self.position.y + speed end
    if input:GetKeyDown(KEY_A) then self.position.x = self.position.x - speed end
    if input:GetKeyDown(KEY_D) then self.position.x = self.position.x + speed end
end

function EditorCamera:HandleZoom()
    -- 滚轮缩放逻辑
end

function EditorCamera:WorldToScreen(wx, wy)
    local rx = wx - self.position.x
    local ry = wy - self.position.y
    return logicalW / 2 + rx * self.zoom, logicalH / 2 + ry * ISO_Y_SCALE * self.zoom
end

function EditorCamera:ScreenToWorld(sx, sy)
    local rx = (sx - logicalW / 2) / self.zoom
    local ry = (sy - logicalH / 2) / self.zoom / ISO_Y_SCALE
    return self.position.x + rx, self.position.y + ry
end

return EditorCamera
```

**验证标准**:
- [ ] 进入编辑模式后 WASD 能移动视角
- [ ] 滚轮能缩放视角
- [ ] 坐标转换正确（点击瓦片能正确识别）

---

### 第 3 天: 编辑器状态管理

**任务清单**:
- [ ] 实现 `EditorState` 类
- [ ] 记录当前瓦片、笔刷大小、悬停位置
- [ ] 实现状态持久化

**代码实现**:
```lua
-- scripts/editor/EditorState.lua
local EditorState = {
    currentTileId = 0,
    brushSize = 1,
    hoverCol = 0,
    hoverRow = 0,
    hoverWorldX = 0,
    hoverWorldY = 0,
    showGrid = true,
    paletteOpen = true,
}

function EditorState:new()
    local obj = {}
    for k, v in pairs(self) do
        obj[k] = v
    end
    setmetatable(obj, self)
    self.__index = self
    return obj
end

return EditorState
```

**验证标准**:
- [ ] 状态对象能正确创建和访问
- [ ] 悬停坐标实时更新

---

### 第 4 天: 基础 UI 框架

**任务清单**:
- [ ] 实现 `EditorUI` 基础类
- [ ] 渲染顶部工具栏背景
- [ ] 渲染底部状态栏
- [ ] 显示基础信息（坐标、工具）

**验证标准**:
- [ ] 进入编辑模式能看到 UI 覆盖层
- [ ] UI 不阻挡鼠标事件传递
- [ ] 退出编辑模式 UI 消失

**阶段 1 完成标志**:
- 按 F12 进入编辑模式
- 看到网格和 UI 覆盖层
- WASD 移动相机，滚轮缩放
- 控制台显示当前悬停瓦片坐标

---

## 阶段 2: 核心编辑功能（第 5-9 天）

### 目标
实现瓦片绘制、擦除、调色板、保存/加载。

### 第 5 天: 瓦片调色板

**任务清单**:
- [ ] 定义 `TILE_PALETTE` 配置
- [ ] 实现左侧调色板 UI
- [ ] 支持点击选择瓦片
- [ ] Q/E 快捷键切换

**代码实现**:
```lua
-- 瓦片调色板配置
local TILE_PALETTE = {
    { id = 0, name = "草地1", color = {85, 150, 65}, sprite = "grass1" },
    { id = 1, name = "草地2", color = {75, 140, 60}, sprite = "grass2" },
    { id = 2, name = "泥土",  color = {150, 115, 75}, sprite = "dirt" },
    { id = 3, name = "石头",  color = {160, 155, 145}, sprite = "stone" },
}
```

**验证标准**:
- [ ] 左侧显示彩色瓦片按钮
- [ ] 点击选中后有高亮边框
- [ ] Q/E 能循环切换选中瓦片

---

### 第 6 天: 画笔工具

**任务清单**:
- [ ] 实现 `BaseTool` 基类
- [ ] 实现 `BrushTool` 画笔工具
- [ ] 支持鼠标左键绘制
- [ ] 支持笔刷大小调整

**代码实现**:
```lua
-- scripts/editor/tools/BaseTool.lua
local BaseTool = {
    name = "base",
    icon = "",
    cursor = "crosshair",
}

function BaseTool:new(name, icon)
    local obj = { name = name, icon = icon }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function BaseTool:OnActivate() end
function BaseTool:OnDeactivate() end
function BaseTool:OnPress(col, row) end
function BaseTool:OnDrag(col, row) end
function BaseTool:OnRelease(col, row) end

return BaseTool
```

```lua
-- scripts/editor/tools/BrushTool.lua
local BrushTool = setmetatable({}, { __index = BaseTool })

function BrushTool:new()
    local obj = BaseTool:new("brush", "🖌️")
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function BrushTool:OnPress(col, row)
    self:Paint(col, row)
end

function BrushTool:OnDrag(col, row)
    self:Paint(col, row)
end

function BrushTool:Paint(col, row)
    local tileId = EditorCore.state.currentTileId
    local size = EditorCore.state.brushSize
    
    -- 获取笔刷影响范围
    local tiles = BrushSystem:GetAffectedTiles(col, row, size, "circle")
    
    for _, tile in ipairs(tiles) do
        if tile.row >= 1 and tile.row <= GRID_ROWS and
           tile.col >= 1 and tile.col <= GRID_COLS then
            tileMap[tile.row][tile.col] = tileId
        end
    end
end

return BrushTool
```

**验证标准**:
- [ ] 鼠标左键能在地图上绘制瓦片
- [ ] 绘制的瓦片类型与选中一致
- [ ] 笔刷大小影响绘制范围

---

### 第 7 天: 橡皮工具与笔刷系统

**任务清单**:
- [ ] 实现 `EraserTool`
- [ ] 完善 `BrushSystem`
- [ ] 支持方形/圆形/菱形笔刷
- [ ] 右键快速擦除

**验证标准**:
- [ ] 橡皮工具能清除瓦片
- [ ] 不同笔刷形状正确生效
- [ ] 右键可直接擦除（无需切换工具）

---

### 第 8 天: 地图序列化

**任务清单**:
- [ ] 实现 `MapSerializer` 类
- [ ] JSON 格式保存
- [ ] JSON 格式加载
- [ ] 集成 F2/F3 快捷键

**验证标准**:
- [ ] F2 能将地图保存到文件
- [ ] F3 能从文件加载地图
- [ ] 保存的地图数据完整正确

---

### 第 9 天: 网格与预览

**任务清单**:
- [ ] 实现网格渲染
- [ ] 实现笔刷预览（半透明覆盖）
- [ ] 实现悬停高亮
- [ ] 网格显示/隐藏切换

**验证标准**:
- [ ] 网格清晰显示瓦片边界
- [ ] 鼠标悬停时显示笔刷范围预览
- [ ] G 键能切换网格显示

**阶段 2 完成标志**:
- 能选择不同瓦片类型
- 能绘制和擦除瓦片
- 能保存和加载地图
- 有网格和预览辅助

---

## 阶段 3: 高级功能（第 10-14 天）

### 目标
实现撤销重做、填充工具、实体编辑、多层系统。

### 第 10 天: 撤销重做系统

**任务清单**:
- [ ] 实现 `UndoRedo` 类
- [ ] 记录绘制操作
- [ ] 支持 Ctrl+Z 撤销
- [ ] 支持 Ctrl+Y 重做

**验证标准**:
- [ ] 绘制后能撤销恢复
- [ ] 撤销后能重做
- [ ] 历史记录限制在 50 步

---

### 第 11 天: 填充工具

**任务清单**:
- [ ] 实现 `FillTool`
- [ ] 泛洪填充算法
- [ ] 支持相似值填充
- [ ] 预览填充范围

**验证标准**:
- [ ] 点击区域能填充相连的同类型瓦片
- [ ] 大面积填充不卡顿

---

### 第 12 天: 实体编辑器基础

**任务清单**:
- [ ] 实现 `EntityTool`
- [ ] 显示现有装饰物
- [ ] 点击选择实体
- [ ] Delete 键删除实体

**验证标准**:
- [ ] 能看到实体选中框
- [ ] 能删除选中的实体

---

### 第 13 天: 实体放置与移动

**任务清单**:
- [ ] 从预设列表选择实体类型
- [ ] 点击放置新实体
- [ ] 拖拽移动实体
- [ ] 实体属性基础编辑

**验证标准**:
- [ ] 能放置新的装饰物
- [ ] 能拖拽改变位置
- [ ] 属性修改实时生效

---

### 第 14 天: 多层系统

**任务清单**:
- [ ] 实现 `LayerManager`
- [ ] 支持地面层/装饰层/碰撞层
- [ ] 层可见性切换
- [ ] 当前层指示器

**验证标准**:
- [ ] 能切换编辑不同层
- [ ] 能单独显示/隐藏某层
- [ ] 保存加载保留层信息

**阶段 3 完成标志**:
- 有撤销重做功能
- 能填充大面积区域
- 能编辑实体
- 支持多层编辑

---

## 阶段 4: 优化与完善（第 15-18 天）

### 目标
UI 美化、性能优化、工具完善。

### 第 15 天: UI 美化

**任务清单**:
- [ ] 设计统一视觉风格
- [ ] 美化调色板
- [ ] 添加工具图标
- [ ] 添加过渡动画

**验证标准**:
- [ ] UI 视觉风格统一
- [ ] 交互有视觉反馈

---

### 第 16 天: 性能优化

**任务清单**:
- [ ] 视锥裁剪优化
- [ ] 脏矩形更新
- [ ] 大地图测试 (100x100)
- [ ] 内存占用分析

**验证标准**:
- [ ] 100x100 地图编辑流畅
- [ ] 内存占用合理

---

### 第 17 天: 选择工具

**任务清单**:
- [ ] 实现 `SelectTool`
- [ ] 框选多个瓦片
- [ ] 复制/粘贴
- [ ] 移动选区

**验证标准**:
- [ ] 能框选区域
- [ ] 能复制粘贴选区

---

### 第 18 天: 测试与修复

**任务清单**:
- [ ] 完整功能测试
- [ ] 边界情况测试
- [ ] 修复发现的问题
- [ ] 代码清理和注释

**验证标准**:
- [ ] 所有功能正常工作
- [ ] 无已知严重 Bug

**阶段 4 完成标志**:
- UI 美观易用
- 性能满足需求
- 功能完整稳定

---

## 每日工作流程

```
┌─────────────────────────────────────────────────────────┐
│                    每日开发流程                          │
├─────────────────────────────────────────────────────────┤
│  1. 开始                                                │
│     └─ 查看今日任务清单                                  │
│     └─ 从昨日断点继续或新建分支                          │
│                                                         │
│  2. 实现                                                │
│     └─ 编写代码（遵循现有代码风格）                       │
│     └─ 每完成一个子任务进行测试                          │
│                                                         │
│  3. 验证                                                │
│     └─ 运行游戏测试功能                                  │
│     └─ 检查控制台错误日志                                │
│     └─ 确认不破坏现有功能                                │
│                                                         │
│  4. 提交                                                │
│     └─ 代码审查（自审）                                  │
│     └─ 更新任务状态                                      │
│     └─ 记录遇到的问题和解决方案                          │
└─────────────────────────────────────────────────────────┘
```

---

## 风险与应对

| 风险 | 可能性 | 影响 | 应对措施 |
|------|--------|------|----------|
| NanoVG UI 性能瓶颈 | 中 | 高 | 优化绘制调用，减少每帧 UI 元素 |
| 鼠标坐标转换错误 | 高 | 高 | 早期重点测试，添加调试图形 |
| 撤销重做内存泄漏 | 中 | 中 | 限制历史长度，定期清理 |
| 地图数据格式不兼容 | 低 | 高 | 版本号控制，提供迁移工具 |
| 与游戏逻辑冲突 | 中 | 高 | 严格模式隔离，暂停游戏时间 |

---

## 检查清单

### 阶段 1 完成检查
- [ ] F12 切换编辑器模式
- [ ] 编辑器相机 WASD 控制
- [ ] 滚轮缩放功能
- [ ] 基础 UI 显示

### 阶段 2 完成检查
- [ ] 瓦片调色板工作
- [ ] 画笔绘制功能
- [ ] 橡皮擦除功能
- [ ] 地图保存/加载

### 阶段 3 完成检查
- [ ] 撤销重做功能
- [ ] 填充工具
- [ ] 实体编辑
- [ ] 多层系统

### 阶段 4 完成检查
- [ ] UI 美观
- [ ] 性能达标
- [ ] 选择工具
- [ ] 无严重 Bug

---

## 附录

### A. 开发顺序图

```
Day 1-4:   [框架] ████████████████████
Day 5-9:   [核心]          ████████████████████
Day 10-14: [高级]                   ████████████████████
Day 15-18: [优化]                            ████████████████████
           ─────┬────────────────────────────────────────────────
                1    5    9   13   17   21
```

### B. 文件创建顺序

```
Day 1:  editor/EditorCore.lua (框架)
        editor/EditorState.lua (框架)
        editor/EditorCamera.lua (框架)
        editor/EditorUI.lua (框架)

Day 2:  editor/EditorCamera.lua (实现)

Day 3:  editor/EditorState.lua (实现)

Day 4:  editor/EditorUI.lua (实现)

Day 5:  editor/TilePalette.lua

Day 6:  editor/tools/BaseTool.lua
        editor/tools/BrushTool.lua

Day 7:  editor/tools/EraserTool.lua
        editor/BrushSystem.lua

Day 8:  editor/MapSerializer.lua

Day 9:  editor/EditorCore.lua (完善)

Day 10: editor/UndoRedo.lua

Day 11: editor/tools/FillTool.lua

Day 12: editor/tools/EntityTool.lua (基础)

Day 13: editor/tools/EntityTool.lua (完善)

Day 14: editor/LayerManager.lua

Day 15-18: 优化和测试
```

### C. 测试地图

```lua
-- 用于测试的简单地图配置
local TEST_MAP = {
    width = 10,
    height = 10,
    tiles = {
        {0,0,0,0,0,0,0,0,0,0},
        {0,1,1,0,0,0,1,1,1,0},
        {0,1,0,0,2,2,0,1,0,0},
        {0,0,0,2,2,2,2,0,0,0},
        {0,0,2,2,3,3,2,2,0,0},
        {0,0,2,2,3,3,2,2,0,0},
        {0,0,0,2,2,2,2,0,0,0},
        {0,1,0,0,2,2,0,0,1,0},
        {0,1,1,0,0,0,1,1,1,0},
        {0,0,0,0,0,0,0,0,0,0},
    }
}
```

---

*文档版本: 1.0*
*最后更新: 2026-05-03*
*状态: 实施计划，待执行*
