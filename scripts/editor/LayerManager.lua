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

function LayerManager:IsLayerVisible(index)
    return self.layers[index] and self.layers[index].visible
end

function LayerManager:IsLayerEditable(index)
    return self.layers[index] and self.layers[index].editable
end

function LayerManager:GetLayerCount()
    return #self.layers
end

return LayerManager
