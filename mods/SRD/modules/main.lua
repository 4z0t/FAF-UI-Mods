local Decal = import("/lua/user/userdecal.lua").UserDecal

local textures = {"nondirect.dds", "nondirectBold.dds", "smd.dds", "smdBold.dds", "tmd.dds", "tmdBold.dds", "air.dds",
                  "airBold.dds", "direct.dds", "directBold.dds"}
local texturePath = "/mods/SRD/textures/"
local range = 10

local function PreloadDecals()
    for i, texture in textures do
        local decal = Decal()
        decal:SetTexture(texturePath .. texture)
        decal:SetScale({math.floor(2.03 * (range)), 0, math.floor(2.03 * (range))})
        local pos = Vector(0,0,0)
        decal:SetPosition(pos)
    end
end

function init(isReplay)
    PreloadDecals()
end
