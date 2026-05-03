local MapSerializer = {}

local function CopyGrid(source, cols, rows)
    local result = {}
    for row = 1, rows do
        result[row] = {}
        for col = 1, cols do
            result[row][col] = source[row][col]
        end
    end
    return result
end

local function EncodeLuaValue(value, indent)
    indent = indent or 0
    local valueType = type(value)
    if valueType == "number" then
        return tostring(value)
    elseif valueType == "boolean" then
        return value and "true" or "false"
    elseif valueType == "string" then
        return string.format("%q", value)
    elseif valueType ~= "table" then
        return "nil"
    end

    local isArray = true
    local maxIndex = 0
    for key, _ in pairs(value) do
        if type(key) ~= "number" or key <= 0 or math.floor(key) ~= key then
            isArray = false
            break
        end
        if key > maxIndex then
            maxIndex = key
        end
    end

    local innerIndent = string.rep("  ", indent + 1)
    local closeIndent = string.rep("  ", indent)
    local parts = {}

    if isArray then
        for i = 1, maxIndex do
            parts[#parts + 1] = innerIndent .. EncodeLuaValue(value[i], indent + 1)
        end
    else
        for key, itemValue in pairs(value) do
            parts[#parts + 1] = innerIndent
                .. "["
                .. string.format("%q", tostring(key))
                .. "] = "
                .. EncodeLuaValue(itemValue, indent + 1)
        end
    end

    if #parts == 0 then
        return "{}"
    end

    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. closeIndent .. "}"
end

function MapSerializer:Save(tileMap, collisionMap, GRID_COLS, GRID_ROWS, decorations, filepath)
    filepath = filepath or "map_save.json"

    local data = {
        version = 2,
        width = GRID_COLS,
        height = GRID_ROWS,
        groundTiles = CopyGrid(tileMap, GRID_COLS, GRID_ROWS),
        collisionTiles = CopyGrid(collisionMap, GRID_COLS, GRID_ROWS),
        decorations = {},
    }

    for i, dec in ipairs(decorations) do
        table.insert(data.decorations, {
            x = dec.x,
            y = dec.y,
            type = dec.type,
            scale = dec.scale,
            swayPhase = dec.swayPhase,
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

function MapSerializer:Load(tileMap, collisionMap, decorations, filepath)
    filepath = filepath or "map_save.json"

    local file = io.open(filepath, "r")
    if not file then
        print("[Editor] No save file found: " .. filepath)
        return false
    end

    local content = file:read("*all")
    file:close()

    local data = self:FromJson(content)
    if not data then
        print("[Editor] Invalid save file")
        return false
    end

    local groundTiles = data.groundTiles or data.tiles
    if not groundTiles then
        print("[Editor] Save file missing ground tile data")
        return false
    end

    for row = 1, math.min(#groundTiles, #tileMap) do
        for col = 1, math.min(#groundTiles[row], #tileMap[row]) do
            tileMap[row][col] = groundTiles[row][col]
        end
    end

    if data.collisionTiles then
        for row = 1, math.min(#data.collisionTiles, #collisionMap) do
            for col = 1, math.min(#data.collisionTiles[row], #collisionMap[row]) do
                collisionMap[row][col] = data.collisionTiles[row][col]
            end
        end
    else
        for row = 1, #collisionMap do
            for col = 1, #collisionMap[row] do
                collisionMap[row][col] = 0
            end
        end
    end

    while #decorations > 0 do
        table.remove(decorations)
    end

    if data.decorations then
        for _, dec in ipairs(data.decorations) do
            decorations[#decorations + 1] = {
                x = dec.x,
                y = dec.y,
                type = dec.type,
                scale = dec.scale or 1.0,
                swayPhase = dec.swayPhase or math.random() * math.pi * 2,
            }
        end
    end

    print("[Editor] Map loaded from " .. filepath)
    return true, decorations
end

function MapSerializer:ToJson(data)
    return EncodeLuaValue(data, 0)
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
