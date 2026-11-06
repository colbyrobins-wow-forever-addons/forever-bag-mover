ForeverBagMoverFilters = {}
local filters = ForeverBagMoverFilters
filters.options = {
    {label = "All items", query = ""},
    {label = "Food", query = "food"},
    {label = "Drinks", query = "drink"},
    {label = "Potions", query = "potion"},
    {label = "Quest items", category = "quest", query = ""},
    {label = "Reagents", category = "reagents", query = ""},
    {label = "Equipment", category = "equipment", query = ""},
    {label = "Junk", category = "junk", query = ""},
}
filters.selected = 1
local hookedButtons = setmetatable({}, {__mode = "k"})
local updating = false

function filters.Matches(category, info, classID, equipLoc, quest)
    if not category then return true end
    if not info or not info.itemID then return false end
    if category == "junk" then return info.quality == 0 end
    if category == "quest" then
        return classID == 12 or (quest and (quest.isQuestItem or quest.questID ~= nil)) or false
    end
    if category == "reagents" then return classID == 5 or classID == 7 end
    if category == "equipment" then
        return equipLoc ~= nil and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP"
    end
    return false
end

local function ApplyButton(button, bagID)
    if not button.SetMatchesSearch or not C_Container then return end
    local bag = button.GetBagID and button:GetBagID() or bagID
    if type(bag) ~= "number" or bag < 0 or bag > (NUM_TOTAL_BAG_FRAMES or 5) then return end
    local slot = button:GetID()
    local info = C_Container.GetContainerItemInfo(bag, slot)
    local category = filters.options[filters.selected].category
    local classID, equipLoc
    if info and info.itemID and category then
        local getInfo = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
        if getInfo then
            local _, _, _, location, _, itemClass = getInfo(info.itemID)
            equipLoc, classID = location, itemClass
        end
    end
    local quest = category == "quest" and C_Container.GetContainerItemQuestInfo
        and C_Container.GetContainerItemQuestInfo(bag, slot)
    updating = true
    button:SetMatchesSearch(not (info and info.isFiltered)
        and filters.Matches(category, info, classID, equipLoc, quest))
    updating = false
    if not hookedButtons[button] then
        hookedButtons[button] = true
        hooksecurefunc(button, "SetMatchesSearch", function()
            if not updating and filters.options[filters.selected].category then
                ApplyButton(button, bag)
            end
        end)
    end
end

function filters.Apply(frame, bagID)
    if not frame:IsShown() then return end
    if frame.EnumerateValidItems then
        for _, button in frame:EnumerateValidItems() do ApplyButton(button, bagID) end
    elseif frame.Items then
        for _, button in ipairs(frame.Items) do ApplyButton(button, bagID) end
    end
end
