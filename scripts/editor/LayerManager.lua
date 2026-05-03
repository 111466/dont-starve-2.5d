local LayerManager = {
    layers = {
        { name = "地面", visible = true, editable = true, id = "ground" },
        { name = "装饰", visible = true, editable = false, id = "decoration" },
        { name = "碰撞", visible = false, editable = false, id = "collision" },
    },
    currentLayer = 1,
}

function LayerManager:new()
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

function LayerManager:GetCurrentLayer()
    return self.layers[self.currentLayer]
end

function LayerManager:SetCurrentLayer(index)
    if index >= 1 and index <= #self.layers then
        self.currentLayer = index
    end
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

function LayerManager:IsLayerEditable(index)
    return self.layers[index] and self.layers[index].editable
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
