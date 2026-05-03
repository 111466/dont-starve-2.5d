local EditorCamera = {
    position = { x = 0, y = 0 },
    zoom = 1.0,
    minZoom = 0.3,
    maxZoom = 3.0,
    panSpeed = 300,
    isPanning = false,
    panStartX = 0,
    panStartY = 0,
    panStartCamX = 0,
    panStartCamY = 0,
}

function EditorCamera:new()
    local obj = {}
    for k, v in pairs(self) do
        if type(v) == "table" then
            obj[k] = {}
            for kk, vv in pairs(v) do
                obj[k][kk] = vv
            end
        else
            obj[k] = v
        end
    end
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function EditorCamera:Update(dt, input)
    local speed = self.panSpeed * dt / self.zoom

    if input:GetKeyDown(KEY_W) or input:GetKeyDown(KEY_UP) then self.position.y = self.position.y - speed end
    if input:GetKeyDown(KEY_S) or input:GetKeyDown(KEY_DOWN) then self.position.y = self.position.y + speed end
    if input:GetKeyDown(KEY_A) or input:GetKeyDown(KEY_LEFT) then self.position.x = self.position.x - speed end
    if input:GetKeyDown(KEY_D) or input:GetKeyDown(KEY_RIGHT) then self.position.x = self.position.x + speed end

    local wheel = input:GetMouseMoveWheel()
    if wheel ~= 0 then
        local zoomFactor = 1.1
        if wheel > 0 then
            self.zoom = math.min(self.maxZoom, self.zoom * zoomFactor)
        else
            self.zoom = math.max(self.minZoom, self.zoom / zoomFactor)
        end
    end
end

function EditorCamera:StartPan(mx, my)
    self.isPanning = true
    self.panStartX = mx
    self.panStartY = my
    self.panStartCamX = self.position.x
    self.panStartCamY = self.position.y
end

function EditorCamera:UpdatePan(mx, my, ISO_Y_SCALE)
    if not self.isPanning then return end
    local dx = (mx - self.panStartX) / self.zoom
    local dy = (my - self.panStartY) / self.zoom / ISO_Y_SCALE
    self.position.x = self.panStartCamX - dx
    self.position.y = self.panStartCamY - dy
end

function EditorCamera:EndPan()
    self.isPanning = false
end

function EditorCamera:WorldToScreen(wx, wy, logicalW, logicalH, ISO_Y_SCALE)
    local rx = wx - self.position.x
    local ry = wy - self.position.y
    return logicalW / 2 + rx * self.zoom, logicalH / 2 + ry * ISO_Y_SCALE * self.zoom
end

function EditorCamera:ScreenToWorld(sx, sy, logicalW, logicalH, ISO_Y_SCALE)
    local rx = (sx - logicalW / 2) / self.zoom
    local ry = (sy - logicalH / 2) / self.zoom / ISO_Y_SCALE
    return self.position.x + rx, self.position.y + ry
end

-- 改进的 ScreenToWorld，考虑等距投影的精确转换
function EditorCamera:ScreenToWorldIso(sx, sy, logicalW, logicalH, TILE_SIZE, ISO_Y_SCALE)
    -- 先转换为世界坐标
    local rx = (sx - logicalW / 2) / self.zoom
    local ry = (sy - logicalH / 2) / self.zoom / ISO_Y_SCALE
    
    -- 考虑瓦片中心偏移，使高亮与瓦片中心对齐
    local wx = self.position.x + rx
    local wy = self.position.y + ry
    
    return wx, wy
end

return EditorCamera
