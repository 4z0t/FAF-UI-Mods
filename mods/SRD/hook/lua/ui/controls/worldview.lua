do
    local TableInsert = table.insert
    local TableGetn = table.getn
    local GetCommandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode
    local unpack = unpack

    local overlayParams = import("/lua/ui/game/rangeoverlayparams.lua").RangeOverlayParams

    local function GetBPInfo(bp)
        if bp.Weapon ~= nil and not table.empty(bp.Weapon) then
            local weapons = {}
            for _wIndex, w in bp.Weapon do
                local radius = w.MaxRadius
                if w.RangeCategory == "UWRC_DirectFire" then
                    TableInsert(weapons, { "AllMilitary", radius })
                elseif w.RangeCategory == "UWRC_IndirectFire" then
                    TableInsert(weapons, { "IndirectFire", radius })
                elseif w.RangeCategory == "UWRC_AntiAir" then
                    TableInsert(weapons, { "AntiAir", radius })
                elseif w.RangeCategory == "UWRC_Countermeasure" then
                    TableInsert(weapons, { "Defense", radius })
                end
            end
            return weapons
        elseif bp.Intel ~= nil then
            local weapons = {}
            if bp.Intel.OmniRadius then
                TableInsert(weapons, { "Omni", bp.Intel.OmniRadius })
            end
            if bp.Intel.RadarRadius then
                TableInsert(weapons, { "Radar", bp.Intel.RadarRadius })
            end
            return weapons
        end
    end

    local function GetColorAndThickness(type)
        return ("ff%s"):format((overlayParams[type].NormalColor):sub(3)),
            overlayParams[type].Outer[1] / overlayParams[type].Type
    end

    ---@class Ring
    ---@field pos Vector
    ---@field color string
    ---@field radius number
    ---@field thickness number
    Ring = ClassSimple
    {
        __init = function(self, color, radius)
            self.pos = Vector(0, 0, 0)
            self.color = color or "ffffffff"
            self.radius = radius or 0
            self.thickness = 0.15
        end,

        ---@param self Ring
        Render = function(self)
            UI_DrawCircle(self.pos, self.radius, self.color, self.thickness)
        end,

        SetPosition = function(self, pos)
            self.pos = pos
        end,

        SetRadius = function(self, radius)
            self.radius = radius
        end,

        SetColor = function(self, color)
            self.color = color
        end

    }

    local oldWorldView = WorldView
    WorldView = Class(oldWorldView) {

        ---@param self WorldView
        ---@param spec any
        __post_init = function(self, spec)
            oldWorldView.__post_init(self, spec)
            self:SetCustomRender(self:GetName() ~= "MiniMap")
        end,
        OnRenderWorld = function(self, delta)
            for _, ring in self.ActiveRings do
                ring:Render()
            end
        end,

        PreviewKey = "SHIFT",
        IsClear = false,
        ActiveRings = {},

        OnUpdateCursor = function(self)
            if IsKeyDown(self.PreviewKey) and not GetCommandMode()[2] then
                self:Update()
            else
                self:Clear()
            end
            return oldWorldView.OnUpdateCursor(self)
        end,

        CreateRing = function(type, range)
            local ring = Ring()
            local color, thick = GetColorAndThickness(type)
            ring:SetColor(color)
            ring:SetRadius(range)
            ring:SetPosition(GetMouseWorldPos())
            ring.thickness = thick
            ring.type = type
            ring.range = range
            return ring
        end,

        UpdateDecal = function(decal, type, range)
            if decal.type ~= type then
                local color, thick = GetColorAndThickness(type)
                decal:SetColor(color)
                decal.type = type
                decal.thickness = thick
            end
            if decal.range ~= range then
                decal:SetRadius(range)
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
                    local ActiveRings = self.ActiveRings

                    self.IsClear = false

                    if TableGetn(weapons) > TableGetn(ActiveRings) then
                        local decal
                        for i, weapon in weapons do
                            decal = ActiveRings[i]
                            if decal then
                                self.UpdateDecal(decal, unpack(weapon))
                            else
                                ActiveRings[i] = self.CreateRing(unpack(weapon))
                            end
                        end
                    else
                        local weapon
                        for i, decal in ActiveRings do
                            weapon = weapons[i]
                            if weapon then
                                self.UpdateDecal(decal, unpack(weapon))
                            else
                                ActiveRings[i] = nil
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
                for i, decal in self.ActiveRings do
                    self.ActiveRings[i] = nil
                end
                self.IsClear = true
            end
        end,

        OnDestroy = function(self)
            self:Clear()
            self.ActiveRings = nil
            oldWorldView.OnDestroy(self)
        end

    }

end
