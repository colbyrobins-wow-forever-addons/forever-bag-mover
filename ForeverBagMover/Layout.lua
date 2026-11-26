-- Geometry is expressed in UIParent coordinates.
ForeverBagMoverLayout = {}

function ForeverBagMoverLayout.Translate(bags, dx, dy, width, height)
    local minX, maxX, minY, maxY = -math.huge, math.huge, -math.huge, math.huge
    for _, bag in ipairs(bags) do
        minX = math.max(minX, bag.w - bag.x)
        maxX = math.min(maxX, width - bag.x)
        minY = math.max(minY, bag.h - bag.y)
        maxY = math.min(maxY, height - bag.y)
    end
    if minX > maxX or minY > maxY then return nil end
    dx = math.max(minX, math.min(maxX, dx))
    dy = math.max(minY, math.min(maxY, dy))
    local result = {}
    for _, bag in ipairs(bags) do
        result[bag.key] = {x = bag.x + dx, y = bag.y + dy}
    end
    return result
end

function ForeverBagMoverLayout.Arrange(bags, mode, gap, width, height)
    local columns = mode == "row" and #bags or (mode == "column" and 1 or math.ceil(math.sqrt(#bags)))
    local result = {}
    local left, top, rowHeight, column = 10, height - 10, 0, 0
    for _, bag in ipairs(bags) do
        if column == columns then
            left, top, rowHeight, column = 10, top - rowHeight - gap, 0, 0
        end
        if left + bag.w > width or top - bag.h < 0 then return nil end
        result[bag.key] = {x = left + bag.w, y = top}
        left = left + bag.w + gap
        rowHeight = math.max(rowHeight, bag.h)
        column = column + 1
    end
    return result
end

function ForeverBagMoverLayout.Snap(bag, others, width, height, gap)
    local xs = {{value = bag.w, guide = 0}, {value = width, guide = width}}
    local ys = {{value = bag.h, guide = 0}, {value = height, guide = height}}
    for _, other in ipairs(others) do
        if other.key ~= bag.key then
            for _, target in ipairs({
                {other.x, other.x}, {other.x - other.w + bag.w, other.x - other.w},
                {other.x + gap + bag.w, other.x}, {other.x - other.w - gap, other.x - other.w},
            }) do table.insert(xs, {value = target[1], guide = target[2]}) end
            for _, target in ipairs({
                {other.y, other.y}, {other.y - other.h + bag.h, other.y - other.h},
                {other.y + gap + bag.h, other.y}, {other.y - other.h - gap, other.y - other.h},
            }) do table.insert(ys, {value = target[1], guide = target[2]}) end
        end
    end
    local function Nearest(value, targets, minimum, maximum)
        local distance, snapped, guide = 11, value, nil
        for _, target in ipairs(targets) do
            local delta = math.abs(value - target.value)
            if delta < distance and target.value >= minimum and target.value <= maximum then
                distance, snapped, guide = delta, target.value, target.guide
            end
        end
        return math.max(minimum, math.min(maximum, snapped)), guide
    end
    local x, gx = Nearest(bag.x, xs, bag.w, width)
    local y, gy = Nearest(bag.y, ys, bag.h, height)
    return x, y, gx, gy
end

-- Glue: a bag touching the combined bag keeps its offset from the nearest
-- combined-bag edges, so it follows that bag through moves, resizes, and
-- reloads. Bags are {x = right, y = top, w, h} in UIParent coordinates.
local function Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- True when the rectangles share an edge (gap up to `tolerance`) or overlap;
-- corner-only contact does not count.
function ForeverBagMoverLayout.Touching(a, b, tolerance)
    local gapX = math.max(a.x - a.w - b.x, b.x - b.w - a.x)
    local gapY = math.max(a.y - a.h - b.y, b.y - b.h - a.y)
    return gapX <= tolerance and gapY <= tolerance and (gapX < 0 or gapY < 0)
end

function ForeverBagMoverLayout.ValidGlue(glue)
    return type(glue) == "table" and (glue.h == "left" or glue.h == "right")
        and (glue.v == "top" or glue.v == "bottom") and Finite(glue.dx) and Finite(glue.dy)
end

local function Reference(glue, anchor)
    return glue.h == "left" and anchor.x - anchor.w or anchor.x,
        glue.v == "bottom" and anchor.y - anchor.h or anchor.y
end

function ForeverBagMoverLayout.Glue(bag, anchor, tolerance)
    if not ForeverBagMoverLayout.Touching(bag, anchor, tolerance) then return nil end
    local left, anchorLeft = bag.x - bag.w, anchor.x - anchor.w
    local bottom, anchorBottom = bag.y - bag.h, anchor.y - anchor.h
    local h, v
    if bag.x <= anchorLeft + tolerance then h = "left"
    elseif left >= anchor.x - tolerance then h = "right"
    else h = math.abs(left - anchorLeft) < math.abs(bag.x - anchor.x) and "left" or "right" end
    if bag.y <= anchorBottom + tolerance then v = "bottom"
    elseif bottom >= anchor.y - tolerance then v = "top"
    else v = math.abs(bottom - anchorBottom) < math.abs(bag.y - anchor.y) and "bottom" or "top" end
    local glue = {h = h, v = v}
    local refX, refY = Reference(glue, anchor)
    glue.dx, glue.dy = bag.x - refX, bag.y - refY
    return glue
end

function ForeverBagMoverLayout.GluedPosition(glue, anchor)
    local refX, refY = Reference(glue, anchor)
    return refX + glue.dx, refY + glue.dy
end

-- Minimap launcher: angles are degrees counterclockwise from east, in [0, 360).
ForeverBagMoverLayout.DefaultMinimapAngle = 225

function ForeverBagMoverLayout.MinimapAngle(dx, dy)
    if dx == 0 and dy == 0 then return ForeverBagMoverLayout.DefaultMinimapAngle end
    return math.deg(math.atan2(dy, dx)) % 360
end

function ForeverBagMoverLayout.ValidMinimapAngle(angle)
    if type(angle) ~= "number" or angle ~= angle or angle < 0 or angle >= 360 then
        return ForeverBagMoverLayout.DefaultMinimapAngle
    end
    return angle
end

function ForeverBagMoverLayout.MinimapOffset(angle, radius)
    local radians = math.rad(angle)
    return math.cos(radians) * radius, math.sin(radians) * radius
end
