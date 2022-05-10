
local CM = import("/lua/ui/game/commandmode.lua")
local Decal = import("/lua/user/userdecal.lua").UserDecal
local texturePath = "/mods/SRD/textures/"
local textureTypes = {
    ["direct"] = texturePath .. "direct.dds",
    ["nondirect"] = texturePath .. "nondirect.dds",
    ["antiair"] = texturePath .. "air.dds",
    ["smd"] = texturePath .. "smd.dds",
    ["tmd"] = texturePath .. "tmd.dds"
}

local function getBPInfo(bp)
    if bp.Weapon ~= nil then
        for _wIndex, w in bp.Weapon do
            local radius = w.MaxRadius;
            if w.RangeCategory == "UWRC_DirectFire" then
                return "direct", radius
            elseif w.RangeCategory == "UWRC_IndirectFire" then
                return "nondirect", radius
            elseif w.RangeCategory == "UWRC_AntiAir" then
                return "antiair", radius
            elseif w.RangeCategory == "UWRC_Countermeasure" then
                return "smd", radius
            end
        end
    end
    return nil, nil
end

local oldWorldView = WorldView
WorldView = Class(oldWorldView) {

    previewKey = "SHIFT",
    IsClear = false,
    ActiveDecal = false,

    OnUpdateCursor = function(self)

        if not CM.GetCommandMode()[2] and IsKeyDown(self.previewKey) then
            self:Update()
        else
            self:Clear()
        end

        return oldWorldView.OnUpdateCursor(self)
    end,

    CreateRingDecal = function(self, info)
        
        local type, range = getBPInfo(__blueprints[info.blueprintId])
        if type then
            local ring = Decal(self)
            ring:SetTexture(textureTypes[type])
            ring:SetScale({math.floor(2.05 * (range)), 0, math.floor(2.05 * (range))})
            ring:SetPosition(GetMouseWorldPos())
            ring.type = type
            ring.range = range
            self.ActiveDecal = ring
            self.IsClear = false
        end
    end,

    Update = function(self)
        local info = GetRolloverInfo()
        if info and info.blueprintId ~= "unknown" then
            local type, range = getBPInfo(__blueprints[info.blueprintId])
            if not type then
                self:Clear()
                return
            end
            if self.ActiveDecal then
                if self.ActiveDecal.type ~= type then
                    self.ActiveDecal:SetTexture(textureTypes[type])
                end
                if self.ActiveDecal.range ~= range then
                    self.ActiveDecal:SetScale({math.floor(2.05 * (range)), 0, math.floor(2.05 * (range))})
                end
                self.ActiveDecal:SetPosition(GetMouseWorldPos())
            else
                self:CreateRingDecal(info)
            end
        else
            self:Clear()
        end
    end,

    Clear = function(self)
        if not self.IsClear then
            if self.ActiveDecal then
                self.ActiveDecal:Destroy()
                self.ActiveDecal = false
            end
            self.IsClear = true
        end
    end,

    OnDestroy = function(self)
        if self.ActiveDecal then
            self.ActiveDecal:Destroy()
        end
        oldWorldView.OnDestroy(self)
    end

}
