-- Account-wide snapshots store normalized coordinates for different UI sizes.
ForeverBagMoverPresets = {}

local function Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function ValidKey(key)
    return type(key) == "string" and (key == "combined" or key == "keyring" or key:match("^bag%d+$"))
end

-- Glue offsets are UI pixels, like bag sizes, so they are not normalized.
local function CopyGlue(glue)
    if ForeverBagMoverLayout.ValidGlue(glue) then
        return {h = glue.h, v = glue.v, dx = glue.dx, dy = glue.dy}
    end
end

function ForeverBagMoverPresets.Capture(positions, width, height)
    local snapshot = {version = 1, positions = {}}
    for key, position in pairs(positions) do
        if ValidKey(key) and type(position) == "table" and Finite(position.x) and Finite(position.y) then
            snapshot.positions[key] = {x = position.x / width, y = position.y / height,
                glue = CopyGlue(position.glue)}
        end
    end
    return snapshot
end

function ForeverBagMoverPresets.Restore(snapshot, width, height)
    if type(snapshot) ~= "table" or snapshot.version ~= 1 or type(snapshot.positions) ~= "table" then
        return nil
    end
    local positions = {}
    for key, position in pairs(snapshot.positions) do
        if ValidKey(key) and type(position) == "table" and Finite(position.x) and Finite(position.y) then
            positions[key] = {
                x = math.max(0, math.min(1, position.x)) * width,
                y = math.max(0, math.min(1, position.y)) * height,
                glue = CopyGlue(position.glue),
            }
        else
            return nil
        end
    end
    return positions
end

function ForeverBagMoverPresets.Name(value)
    local name = value:match("^%s*(.-)%s*$")
    if name == "" or #name > 40 or name:find("[%c|]") then return nil end
    return name
end

function ForeverBagMoverPresets.Names(entries, excluded)
    local names = {}
    for name in pairs(entries) do
        if type(name) == "string" and name ~= excluded then table.insert(names, name) end
    end
    table.sort(names)
    return names
end
