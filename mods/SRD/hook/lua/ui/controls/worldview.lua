do
    local TableInsert = table.insert

    local GetCommandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode
    local Decal = import("/lua/user/userdecal.lua").UserDecal

    local texturePath = "/mods/SRD/textures/"
    local textureTypes = {
        ["direct"] = texturePath .. "direct.dds",
        ["nondirect"] = texturePath .. "nondirect.dds",
        ["antiair"] = texturePath .. "air.dds",
        ["smd"] = texturePath .. "smd.dds",
        ["tmd"] = texturePath .. "tmd.dds"
    }

    local function GetBPInfo(bp)
        if bp.Weapon ~= nil then
            local weapons = {}
            for _wIndex, w in bp.Weapon do
                local radius = w.MaxRadius;
                if w.RangeCategory == "UWRC_DirectFire" then
                    TableInsert(weapons, { "direct", radius })
                elseif w.RangeCategory == "UWRC_IndirectFire" then
                    TableInsert(weapons, { "nondirect", radius })
                elseif w.RangeCategory == "UWRC_AntiAir" then
                    TableInsert(weapons, { "antiair", radius })
                elseif w.RangeCategory == "UWRC_Countermeasure" then
                    TableInsert(weapons, { "smd", radius })
                end
            end
            return weapons
        end
    end

    local oldWorldView = WorldView
    WorldView = Class(oldWorldView) {

        PreviewKey = "SHIFT",
        IsClear = false,
        ActiveDecals = {},

        OnUpdateCursor = function(self)
            if IsKeyDown(self.PreviewKey) and not GetCommandMode()[2] then
                self:Update()
            else
                self:Clear()
            end
            return oldWorldView.OnUpdateCursor(self)
        end,

        CreateRingDecal = function(type, range)
            local ring = Decal()
            ring:SetTexture(textureTypes[type])
            ring:SetScale({ math.floor(2.03 * (range)), 0, math.floor(2.03 * (range)) })
            ring:SetPosition(GetMouseWorldPos())
            ring.type = type
            ring.range = range
            return ring
        end,

        UpdateDecal = function(decal, type, range)
            if decal.type ~= type then
                decal:SetTexture(textureTypes[type])
                decal.type = type
            end
            if decal.range ~= range then
                decal:SetScale({ math.floor(2.05 * (range)), 0, math.floor(2.05 * (range)) })
                decal.range = range
            end
            decal:SetPosition(GetMouseWorldPos())
        end,

        Update = function(self)
            local info = GetRolloverInfo()
            if info and info.blueprintId ~= "unknown" then
                local weapons = GetBPInfo(__blueprints[info.blueprintId])
                if table.empty(weapons) then
                    self:Clear()
                else
                    local ActiveDecals = self.ActiveDecals

                    self.IsClear = false

                    if table.getn(weapons) > table.getn(ActiveDecals) then
                        local decal
                        for i, weapon in weapons do
                            decal = ActiveDecals[i]
                            if decal then
                                self.UpdateDecal(decal, unpack(weapon))
                            else
                                ActiveDecals[i] = self.CreateRingDecal(unpack(weapon))
                            end
                        end
                    else
                        local weapon
                        for i, decal in ActiveDecals do
                            weapon = weapons[i]
                            if weapon then
                                self.UpdateDecal(decal, unpack(weapon))
                            else
                                decal:Destroy()
                                ActiveDecals[i] = nil
                            end
                        end
                    end
                end
            else
                self:Clear()
            end
        end,

        Clear = function(self)
            if not self.IsClear then
                for i, decal in self.ActiveDecals do
                    decal:Destroy()
                    self.ActiveDecals[i] = nil
                end
                self.IsClear = true
            end
        end,

        OnDestroy = function(self)
            self:Clear()
            self.ActiveDecals = nil
            oldWorldView.OnDestroy(self)
        end

    }

end
