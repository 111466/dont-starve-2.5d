local LayerManager = {
    layers = {
        { name = "地面", visible = true, editable = true, id = "ground" },
        { name = "装饰", visible = true, editable = true, id = "decoration" },
        { name = "碰撞", visible = false, editable = true, id = "collision" },
    },
    currentLayer = 1,
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

function LayerManager:new()
    local obj = CloneValue(self)
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function LayerManager:GetCurrentLayer()
    return self.layers[self.currentLayer]
end

function LayerManager:SetCurrentLayer(index)
    if index >= 1 and index <= #self.layers then
        self.currentLayer = index
    end
end

function LayerManager:GetCurrentLayerId()
    local layer = self:GetCurrentLayer()
    return layer and layer.id or nil
end

function LayerManager:GetLayer(index)
    return self.layers[index]
end

function LayerManager:GetLayerById(layerId)
    for _, layer in ipairs(self.layers) do
        if layer.id == layerId then
            return layer
        end
    end
    return nil
end

function LayerManager:ToggleVisibility(index)
    if index >= 1 and index <= #self.layers then
        self.layers[index].visible = not self.layers[index].visible
    end
end

function LayerManager:ToggleEditable(index)
    if index >= 1 and index <= #self.layers then
        self.layers[index].editable = not self.layers[index].editable
    end
end

function LayerManager:IsLayerVisible(index)
    return self.layers[index] and self.layers[index].visible
end

function LayerManager:IsLayerVisibleById(layerId)
    local layer = self:GetLayerById(layerId)
    return layer and layer.visible or false
end

function LayerManager:IsLayerEditable(index)
    return self.layers[index] and self.layers[index].editable
end

function LayerManager:IsLayerEditableById(layerId)
    local layer = self:GetLayerById(layerId)
    return layer and layer.editable or false
end

function LayerManager:CanEditCurrentLayer()
    local layer = self:GetCurrentLayer()
    return layer and layer.editable or false
end

function LayerManager:GetLayerCount()
    return #self.layers
end

-- 添加自定义图层
function LayerManager:AddLayer(name)
    local newId = "layer_" .. tostring(#self.layers + 1) .. "_" .. tostring(os.time())
    table.insert(self.layers, {
        name = name or "新图层",
        visible = true,
        editable = true,
        id = newId
    })
    return #self.layers
end

-- 删除图层
function LayerManager:RemoveLayer(index)
    if index >= 1 and index <= #self.layers and #self.layers > 1 then
        table.remove(self.layers, index)
        if self.currentLayer > #self.layers then
            self.currentLayer = #self.layers
        end
        return true
    end
    return false
end

-- 重命名图层
function LayerManager:RenameLayer(index, newName)
    if index >= 1 and index <= #self.layers then
        self.layers[index].name = newName or self.layers[index].name
        return true
    end
    return false
end

return LayerManager
