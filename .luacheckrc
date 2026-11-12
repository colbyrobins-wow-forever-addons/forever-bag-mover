-- Lint addon code; tests intentionally stub the client API.
std = "lua51"
max_line_length = false
ignore = { "212/self", "431" }
globals = {
    "ForeverBagMoverDB", "ForeverBagMoverSharedDB",
    "ForeverBagMoverLayout", "ForeverBagMoverPresets", "ForeverBagMoverFilters",
    "SLASH_FOREVERBAGMOVER1", "SlashCmdList",
}
read_globals = {
    "BagItemAutoSortButton", "BagItemSearchBox", "C_Container", "C_Item",
    "ContainerFrameCombinedBags", "CreateFrame", "DEFAULT_CHAT_FRAME",
    "GameTooltip", "GetCursorPosition", "GetItemInfoInstant", "GetRealmName",
    "hooksecurefunc", "InCombatLockdown", "IsAltKeyDown", "Minimap",
    "NUM_CONTAINER_FRAMES", "NUM_TOTAL_BAG_FRAMES", "OpenAllBags",
    "OpenBackpack", "UIParent", "UnitName", "UpdateContainerFrameAnchors",
}
