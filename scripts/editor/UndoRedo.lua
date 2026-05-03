local UndoRedo = {
    history = {},
    currentIndex = 0,
    maxHistory = 50,
}

function UndoRedo:new()
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

function UndoRedo:Push(tileMap, GRID_COLS, GRID_ROWS)
    local snapshot = {}
    for row = 1, GRID_ROWS do
        snapshot[row] = {}
        for col = 1, GRID_COLS do
            snapshot[row][col] = tileMap[row][col]
        end
    end

    while #self.history > self.currentIndex do
        table.remove(self.history)
    end

    table.insert(self.history, snapshot)

    if #self.history > self.maxHistory then
        table.remove(self.history, 1)
    else
        self.currentIndex = self.currentIndex + 1
    end
end

function UndoRedo:Undo(tileMap, GRID_COLS, GRID_ROWS)
    if self.currentIndex <= 1 then
        return false
    end

    self.currentIndex = self.currentIndex - 1
    local snapshot = self.history[self.currentIndex]

    for row = 1, GRID_ROWS do
        for col = 1, GRID_COLS do
            tileMap[row][col] = snapshot[row][col]
        end
    end

    return true
end

function UndoRedo:Redo(tileMap, GRID_COLS, GRID_ROWS)
    if self.currentIndex >= #self.history then
        return false
    end

    self.currentIndex = self.currentIndex + 1
    local snapshot = self.history[self.currentIndex]

    for row = 1, GRID_ROWS do
        for col = 1, GRID_COLS do
            tileMap[row][col] = snapshot[row][col]
        end
    end

    return true
end

function UndoRedo:CanUndo()
    return self.currentIndex > 1
end

function UndoRedo:CanRedo()
    return self.currentIndex < #self.history
end

return UndoRedo
