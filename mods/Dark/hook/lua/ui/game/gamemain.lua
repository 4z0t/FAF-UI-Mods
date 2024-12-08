local skins = import("/lua/skins/skins.lua").skins
skins["dark-cybran"] = {
    default = "cybran",
    texturesPath = "/mods/Dark/textures/dark-cybran",
    fontColor = "FFff0000", --#FFe24f2d
    tooltipBorderColor = "FF000000", --#FFb62929
    tooltipTitleColor = "FF000000", --#FF621917
}

-- skins["sky-cybran"] = {
--     default = "aeon",
--     texturesPath = "/mods/Dark/textures/sky-cybran",
--     fontColor = "FFff0000", --#FFe24f2d
--     tooltipBorderColor = "FF000000", --#FFb62929
--     tooltipTitleColor = "FF000000", --#FF621917
-- }

-- Flatten skins for performance. Note that this doesn't avoid the need to scan texture paths.
for k, v in skins do
    local default = skins[v.default]
    while default do
        -- Copy the entire default chain into the toplevel skin.
        table.assimilate(v, default)

        default = skins[default.default]
    end
end
