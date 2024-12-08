do
    local TableInsert = table.insert
    local TableGetn = table.getn
    local TableEmpty = table.empty
    local unpack = unpack
    local UI_DrawCircle = UI_DrawCircle

    local LuaQ = UMT.LuaQ

    local options = UMT.Options.Mods["RFA"]
    local GetCommandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode
    local overlayParams = import("/lua/ui/game/rangeoverlayparams.lua").RangeOverlayParams

    ---@class RingData
    ---@field [1] string # type
    ---@field [2] number # range

    local showDirectFire = false
    local showIndirectFire = false
    local showAntiAir = false
    local showAntiNavy = false
    local showCountermeasure = false
    local showOmni = false
    local showRadar = false

    options.showDirectFire:Bind(function(opt)
        showDirectFire = opt()
    end)
    options.showIndirectFire:Bind(function(opt)
        showIndirectFire = opt()
    end)
    options.showAntiAir:Bind(function(opt)
        showAntiAir = opt()
    end)
    options.showAntiNavy:Bind(function(opt)
        showAntiNavy = opt()
    end)
    options.showCountermeasure:Bind(function(opt)
        showCountermeasure = opt()
    end)
    options.showOmni:Bind(function(opt)
        showOmni = opt()
    end)
    options.showRadar:Bind(function(opt)
        showRadar = opt()
    end)

    ---@param bp UnitBlueprint
    ---@return RingData[]?
    local function GetBPInfo(bp)
        if bp.Weapon ~= nil and not TableEmpty(bp.Weapon) then
            local weapons = {}
            for _wIndex, w in bp.Weapon do
                local radius = w.MaxRadius
                if showDirectFire and w.RangeCategory == "UWRC_DirectFire" then
                    TableInsert(weapons, { "AllMilitary", radius })
                elseif showIndirectFire and w.RangeCategory == "UWRC_IndirectFire" then
                    TableInsert(weapons, { "IndirectFire", radius })
                elseif showAntiAir and w.RangeCategory == "UWRC_AntiAir" then
                    TableInsert(weapons, { "AntiAir", radius })
                elseif showCountermeasure and w.RangeCategory == "UWRC_Countermeasure" then
                    TableInsert(weapons, { "Defense", radius })
                elseif showAntiNavy and w.RangeCategory == "UWRC_AntiNavy" then
                    TableInsert(weapons, { "AntiNavy", radius })
                end
            end
            return weapons
        elseif bp.Intel ~= nil then
            local weapons = {}
            if showOmni and bp.Intel.OmniRadius then
                TableInsert(weapons, { "Omni", bp.Intel.OmniRadius })
            end
            if showRadar and bp.Intel.RadarRadius then
                TableInsert(weapons, { "Radar", bp.Intel.RadarRadius })
            end
            return weapons
        end
    end

    local function GetColorAndThickness(type)
        return ("ff%s"):format((overlayParams[type].NormalColor):sub(3)),
            overlayParams[type].Outer[1] / overlayParams[type].Type
    end

    local function TableClear(t)
        for k in t do
            t[k] = nil
        end
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
    ---@class WorldView : WorldView
    ---@field _hoverRings Ring[]
    ---@field _selectionRings Ring[]
    ---@field _buildRing Ring
    ---@field _showRings boolean
    WorldView = Class(oldWorldView) {

        ---@param self WorldView
        ---@param spec any
        __post_init = function(self, spec)
            oldWorldView.__post_init(self, spec)
            self._showRings = false
            local render = self.SetCustomRender and self:GetName() ~= "MiniMap"
            if render then
                self._hoverRings = {}
                self._selectionRings = {}
                self._buildRing = nil
                self:SetCustomRender(true)
                self._showRings = true
            end
        end,

        ---@param self WorldView
        ---@param rings Ring[]
        RenderRings = function(self, rings)
            for _, ring in rings do
                ring:Render()
            end
        end,

        ---@param self WorldView
        ---@param delta number
        OnRenderWorld = function(self, delta)
            self:RenderRings(self._hoverRings)
            self:RenderRings(self._selectionRings)
            if self._buildRing then
                self._buildRing:Render()
            end
        end,

        HoverPreviewKey = options.hoverPreviewKey(),
        SelectedPreviewKey = options.selectedPreviewKey(),
        BuildPreviewKey = options.buildPreviewKey(),

        ---@param self WorldView
        OnUpdateCursor = function(self)
            if self._showRings then
                local commandMode = GetCommandMode()
                local givingMoveOrder = commandMode[1] == "order" and commandMode[2].name == "RULEUCC_Move"
                local notIssuingOrder = not commandMode[2]

                if IsKeyDown(self.HoverPreviewKey) and notIssuingOrder then
                    self:UpdateHoverRings()
                else
                    self:ClearHoverRings()
                end

                if notIssuingOrder or givingMoveOrder then
                    if IsKeyDown(self.SelectedPreviewKey) then
                        self:UpdateSelectionRings()
                    else
                        self:ClearSelectionRings()
                    end

                    if IsKeyDown(self.BuildPreviewKey) then
                        self:UpdateBuildRings()
                    elseif IsKeyDown(18) then --alt
                        self:UpdateReclaimRings()
                    else
                        self:ClearBuildRings()
                    end
                end
            end
            return oldWorldView.OnUpdateCursor(self)
        end,

        ---@param self WorldView
        UpdateHoverRings = function(self)
            local info = GetRolloverInfo()
            if not (info and info.blueprintId ~= "unknown") then
                self:ClearHoverRings()
                return
            end

            local weapons = GetBPInfo(__blueprints[info.blueprintId])
            if TableEmpty(weapons) then
                self:ClearHoverRings()
                return
            end

            self:UpdateRings(self._hoverRings, weapons)
        end,

        ---@param self WorldView
        ClearHoverRings = function(self)
            TableClear(self._hoverRings)
        end,

        ---@param self WorldView
        UpdateSelectionRings = function(self)
            local selection = GetSelectedUnits()
            if not selection then
                self:ClearSelectionRings()
                return
            end

            local data = selection
                | LuaQ.select(function(u) return u:GetBlueprint() end)
                | LuaQ.distinct
                | LuaQ.select(GetBPInfo)
                | LuaQ.concat
            self:UpdateRings(self._selectionRings, data)
        end,

        ---@param self WorldView
        ClearSelectionRings = function(self)
            TableClear(self._selectionRings)
        end,

        UpdateBuildRings = function(self)
            local selection = GetSelectedUnits()
            if not selection then
                self:ClearBuildRings()
                return
            end
            local engineers = EntityCategoryFilterDown(categories.ENGINEER, selection)
            if TableEmpty(engineers) then
                self:ClearBuildRings()
                return
            end

            local radius = selection
                | LuaQ.select(function(u) return u:GetBlueprint().Economy.MaxBuildDistance end)
                | LuaQ.max.value

            ---@type Ring
            local ring = Ring()
            ring.pos = GetMouseWorldPos()
            ring.radius = (radius or 0) + 2
            local color, thick = GetColorAndThickness "Miscellaneous"
            ring.thickness = thick
            ring:SetColor(color)
            self._buildRing = ring
        end,

        UpdateReclaimRings = function(self)
            local selection = GetSelectedUnits()
            if not selection then
                self:ClearBuildRings()
                return
            end

            local engineers = EntityCategoryFilterDown(categories.ENGINEER + categories.FACTORY, selection)
            if TableEmpty(engineers) then
                self:ClearBuildRings()
                return
            end

            ---@type Ring
            local ring = Ring()
            ring.pos = GetMouseWorldPos()
            ring.radius = 28
            local color, thick = GetColorAndThickness "AllMilitary"
            ring.thickness = thick
            ring:SetColor(color)
            self._buildRing = ring
        end,

        ClearBuildRings = function(self)
            self._buildRing = nil
        end,

        ---@param self WorldView
        ---@param rings Ring[]
        ---@param ringsData RingData[]
        UpdateRings = function(self, rings, ringsData)
            if TableGetn(ringsData) > TableGetn(rings) then
                for i, d in ringsData do
                    local ring = rings[i]
                    if ring then
                        self.UpdateRing(ring, unpack(d))
                    else
                        rings[i] = self.CreateRing(unpack(d))
                    end
                end
            else

                for i, ring in rings do
                    local d = ringsData[i]
                    if d then
                        self.UpdateRing(ring, unpack(d))
                    else
                        rings[i] = nil
                    end
                end
            end
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

        ---@param ring Ring
        ---@param type string
        ---@param range number
        UpdateRing = function(ring, type, range)
            if ring.type ~= type then
                local color, thick = GetColorAndThickness(type)
                ring:SetColor(color)
                ring.type = type
                ring.thickness = thick
            end
            if ring.range ~= range then
                ring:SetRadius(range)
                ring.range = range
            end
            ring:SetPosition(GetMouseWorldPos())
        end,

        ---@param self WorldView
        OnDestroy = function(self)
            self:ClearHoverRings()
            self._hoverRings = nil
            self:ClearSelectionRings()
            self._selectionRings = nil
            self._buildRing = nil
            self._showRings = false

            oldWorldView.OnDestroy(self)
        end,

        ---@param self WorldView
        ---@param renderable Renderable
        ---@param id string
        RegisterRenderable = function(self, renderable, id)
            self.Trash:Add(renderable)
            self.Renderables[id] = renderable
        end,

        ---@param self WorldView
        ---@param id string
        UnregisterRenderable = function(self, id)
            self.Renderables[id] = nil
        end,
    }

end
