local BrushSystem = {}

function BrushSystem:GetAffectedTiles(col, row, size, shape)
    shape = shape or "square"
    local tiles = {}
    local half = math.floor(size / 2)

    if shape == "square" then
        for dc = -half, half do
            for dr = -half, half do
                table.insert(tiles, { col = col + dc, row = row + dr })
            end
        end
    elseif shape == "circle" then
        for dc = -half, half do
            for dr = -half, half do
                local dist = math.sqrt(dc * dc + dr * dr)
                if dist <= half + 0.5 then
                    table.insert(tiles, { col = col + dc, row = row + dr })
                end
            end
        end
    elseif shape == "diamond" then
        for dc = -half, half do
            for dr = -half, half do
                if math.abs(dc) + math.abs(dr) <= half then
                    table.insert(tiles, { col = col + dc, row = row + dr })
                end
            end
        end
    end

    return tiles
end

return BrushSystem
