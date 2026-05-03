local UndoRedo = {
    history = {},
    currentIndex = 0,
    maxHistory = 50,
}

local function CloneGrid(grid, cols, rows)
    local snapshot = {}
    for row = 1, rows do
        snapshot[row] = {}
        for col = 1, cols do
            snapshot[row][col] = grid[row][col]
        end
    end
    return snapshot
end

local function CloneDecorations(decorations)
    local snapshot = {}
    for i, dec in ipairs(decorations) do
        snapshot[i] = {
            x = dec.x,
            y = dec.y,
            type = dec.type,
            scale = dec.scale,
            swayPhase = dec.swayPhase,
        }
    end
    return snapshot
end

local function RestoreGrid(target, snapshot, cols, rows)
    for row = 1, rows do
        for col = 1, cols do
            target[row][col] = snapshot[row][col]
        end
    end
end

local function RestoreDecorations(target, snapshot)
    while #target > 0 do
        table.remove(target)
    end

    for i, dec in ipairs(snapshot) do
        target[i] = {
            x = dec.x,
            y = dec.y,
            type = dec.type,
            scale = dec.scale,
            swayPhase = dec.swayPhase,
        }
    end
end

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

function UndoRedo:Push(tileMap, collisionMap, decorations, GRID_COLS, GRID_ROWS)
    local snapshot = {
        ground = CloneGrid(tileMap, GRID_COLS, GRID_ROWS),
        collision = CloneGrid(collisionMap, GRID_COLS, GRID_ROWS),
        decorations = CloneDecorations(decorations),
    }

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

function UndoRedo:Undo(tileMap, collisionMap, decorations, GRID_COLS, GRID_ROWS)
    if self.currentIndex <= 1 then
        return false
    end

    self.currentIndex = self.currentIndex - 1
    local snapshot = self.history[self.currentIndex]

    RestoreGrid(tileMap, snapshot.ground, GRID_COLS, GRID_ROWS)
    RestoreGrid(collisionMap, snapshot.collision, GRID_COLS, GRID_ROWS)
    RestoreDecorations(decorations, snapshot.decorations)

    return true
end

function UndoRedo:Redo(tileMap, collisionMap, decorations, GRID_COLS, GRID_ROWS)
    if self.currentIndex >= #self.history then
        return false
    end

    self.currentIndex = self.currentIndex + 1
    local snapshot = self.history[self.currentIndex]

    RestoreGrid(tileMap, snapshot.ground, GRID_COLS, GRID_ROWS)
    RestoreGrid(collisionMap, snapshot.collision, GRID_COLS, GRID_ROWS)
    RestoreDecorations(decorations, snapshot.decorations)

    return true
end

function UndoRedo:CanUndo()
    return self.currentIndex > 1
end

function UndoRedo:CanRedo()
    return self.currentIndex < #self.history
end

return UndoRedo
