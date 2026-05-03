local BaseTool = require("scripts/editor/tools/BaseTool")

local FillTool = setmetatable({}, { __index = BaseTool })

function FillTool:new()
    local obj = BaseTool:new("fill", "fill")
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function FillTool:OnPress(col, row, state, layerId, tileMap, GRID_COLS, GRID_ROWS)
    local targetId = tileMap[row] and tileMap[row][col]
    if targetId == nil then return false end

    local fillId = (layerId == "collision") and 1 or state.currentTileId
    if targetId == fillId then return false end

    self:FloodFill(col, row, targetId, fillId, tileMap, GRID_COLS, GRID_ROWS)
    return true
end

function FillTool:FloodFill(startCol, startRow, targetId, fillId, tileMap, GRID_COLS, GRID_ROWS)
    local queue = {}
    local visited = {}

    table.insert(queue, { col = startCol, row = startRow })
    visited[startCol .. "," .. startRow] = true

    local head = 1
    while head <= #queue do
        local current = queue[head]
        head = head + 1

        local c = current.col
        local r = current.row

        if r >= 1 and r <= GRID_ROWS and c >= 1 and c <= GRID_COLS then
            if tileMap[r][c] == targetId then
                tileMap[r][c] = fillId

                local neighbors = {
                    { c + 1, r },
                    { c - 1, r },
                    { c, r + 1 },
                    { c, r - 1 },
                }

                for _, n in ipairs(neighbors) do
                    local nc, nr = n[1], n[2]
                    local key = nc .. "," .. nr
                    if not visited[key] then
                        visited[key] = true
                        table.insert(queue, { col = nc, row = nr })
                    end
                end
            end
        end
    end
end

return FillTool
