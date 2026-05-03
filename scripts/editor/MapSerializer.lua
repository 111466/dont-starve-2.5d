local MapSerializer = {}

function MapSerializer:Save(tileMap, GRID_COLS, GRID_ROWS, decorations, filepath)
    filepath = filepath or "map_save.json"

    local data = {
        version = 1,
        width = GRID_COLS,
        height = GRID_ROWS,
        tiles = {},
        decorations = {},
    }

    for row = 1, GRID_ROWS do
        data.tiles[row] = {}
        for col = 1, GRID_COLS do
            data.tiles[row][col] = tileMap[row][col]
        end
    end

    for i, dec in ipairs(decorations) do
        table.insert(data.decorations, {
            x = dec.x,
            y = dec.y,
            type = dec.type,
            scale = dec.scale,
        })
    end

    local json = self:ToJson(data)
    local file = io.open(filepath, "w")
    if file then
        file:write(json)
        file:close()
        print("[Editor] Map saved to " .. filepath)
        return true
    else
        print("[Editor] Failed to save map to " .. filepath)
        return false
    end
end

function MapSerializer:Load(tileMap, decorations, filepath)
    filepath = filepath or "map_save.json"

    local file = io.open(filepath, "r")
    if not file then
        print("[Editor] No save file found: " .. filepath)
        return false
    end

    local content = file:read("*all")
    file:close()

    local data = self:FromJson(content)
    if not data or not data.tiles then
        print("[Editor] Invalid save file")
        return false
    end

    for row = 1, math.min(#data.tiles, #tileMap) do
        for col = 1, math.min(#data.tiles[row], #tileMap[row]) do
            tileMap[row][col] = data.tiles[row][col]
        end
    end

    decorations = {}
    if data.decorations then
        for i, dec in ipairs(data.decorations) do
            table.insert(decorations, {
                x = dec.x,
                y = dec.y,
                type = dec.type,
                scale = dec.scale or 1.0,
                swayPhase = math.random() * math.pi * 2,
            })
        end
    end

    print("[Editor] Map loaded from " .. filepath)
    return true, decorations
end

function MapSerializer:ToJson(data)
    local function serialize(val, indent)
        indent = indent or 0
        local t = type(val)
        if t == "number" then
            return tostring(val)
        elseif t == "boolean" then
            return val and "true" or "false"
        elseif t == "string" then
            return string.format("%q", val)
        elseif t == "table" then
            local isArray = true
            local maxIndex = 0
            for k, v in pairs(val) do
                if type(k) ~= "number" or k <= 0 then
                    isArray = false
                    break
                end
                maxIndex = math.max(maxIndex, k)
            end

            local parts = {}
            local innerIndent = string.rep("  ", indent + 1)
            local closeIndent = string.rep("  ", indent)

            if isArray then
                for i = 1, maxIndex do
                    table.insert(parts, innerIndent .. serialize(val[i], indent + 1))
                end
                return "[\n" .. table.concat(parts, ",\n") .. "\n" .. closeIndent .. "]"
            else
                for k, v in pairs(val) do
                    table.insert(parts, innerIndent .. string.format("%q", k) .. ": " .. serialize(v, indent + 1))
                end
                return "{\n" .. table.concat(parts, ",\n") .. "\n" .. closeIndent .. "}"
            end
        else
            return "null"
        end
    end

    return serialize(data)
end

function MapSerializer:FromJson(str)
    local func, err = load("return " .. str, "json", "t", {})
    if not func then
        print("[Editor] JSON parse error: " .. tostring(err))
        return nil
    end
    return func()
end

return MapSerializer
