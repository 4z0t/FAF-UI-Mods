ReUI.Require
{
    "ReUI.Core >= 1.3.0",
    "ReUI.LINQ >= 1.4.0",
    "ReUI.Options >= 1.0.0",
    "ReUI.WorldView >= 1.0.0",
}

function Main(isReplay)

    --#region Upvalues
    local GetSelectedUnits = GetSelectedUnits
    local GetMouseWorldPos = GetMouseWorldPos
    local GetRolloverInfo = GetRolloverInfo
    local GetFocusArmy = GetFocusArmy
    local IsKeyDown = IsKeyDown
    local MathMax = math.max
    local MathFloor = math.floor
    local MathSqrt = math.sqrt
    local TableInsert = table.insert
    local TableGetn = table.getn
    local TableEmpty = table.empty
    local TableSort = table.sort
    local unpack = unpack
    local UI_DrawCircle = UI_DrawCircle
    local EmptyTable = EmptyTable
    --#endregion

    local options = ReUI.Options.Mods["RFA"]

    local Enumerate = ReUI.LINQ.Enumerate
    local IPairsEnumerator = ReUI.LINQ.IPairsEnumerator
    local PairsEnumerator = ReUI.LINQ.PairsEnumerator

    local Contains = PairsEnumerator:Contains()

    local GetCommandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode
    local overlayParams = import("/lua/ui/game/rangeoverlayparams.lua").RangeOverlayParams
    local GetWorldViews = import("/lua/ui/game/worldview.lua").GetWorldViews
    local GetEnhancements = import("/lua/enhancementcommon.lua").GetEnhancements
    local XZDistanceTwoVectorsSquared = import("/lua/utilities.lua").XZDistanceTwoVectorsSquared

    ---@class RingData
    ---@field [1] string # type
    ---@field [2] number # range

    --#region Options
    local showDirectFire = false
    local showIndirectFire = false
    local showAntiAir = false
    local showAntiNavy = false
    local showCountermeasure = false
    local showOmni = false
    local showRadar = false
    local showSonar = false
    local showCounterIntel = false
    local showShield = false
    local displayBuildRingAtMouseHeight = false

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
    options.showSonar:Bind(function(opt)
        showSonar = opt()
    end)
    options.showCounterIntel:Bind(function(opt)
        showCounterIntel = opt()
    end)
    options.showShield:Bind(function(opt)
        showShield = opt()
    end)
    options.displayBuildRingAtMouseHeight:Bind(function (opt)
        displayBuildRingAtMouseHeight = opt()
    end)
    options.showInMinimap.OnChange = function(opt)
        -- local minimap = GetWorldViews()["MiniMap"]
        -- if not minimap then
        --     return
        -- end

        -- local isON = opt()
        -- if isON then
        --     if minimap._showRings then
        --         return
        --     end
        --     local render = minimap.SetCustomRender
        --     if render then
        --         minimap._hoverRings = {}
        --         minimap._selectionRings = {}
        --         minimap._buildRing = nil
        --         minimap:SetCustomRender(true)
        --         minimap._showRings = true
        --     end
        -- else
        --     local render = minimap.SetCustomRender
        --     if render then
        --         minimap._hoverRings = nil
        --         minimap._selectionRings = nil
        --         minimap._buildRing = nil
        --         minimap:SetCustomRender(false)
        --         minimap._showRings = false
        --     end
        -- end
    end
    options.hoverPreviewKey.OnChange = function(opt)
        ---@param view ReUI.WorldView.WorldView
        for _, view in GetWorldViews() do
            local rfa = view:GetComponent("RFA") --[[@as RFAWorldViewComponent]]
            if rfa then
                rfa.HoverPreviewKey = opt()
            end
        end
    end
    options.selectedPreviewKey.OnChange = function(opt)
        ---@param view ReUI.WorldView.WorldView
        for _, view in GetWorldViews() do
            local rfa = view:GetComponent("RFA") --[[@as RFAWorldViewComponent]]
            if rfa then
                rfa.SelectedPreviewKey = opt()
            end
        end
    end
    options.buildPreviewKey.OnChange = function(opt)
        ---@param view ReUI.WorldView.WorldView
        for _, view in GetWorldViews() do
            local rfa = view:GetComponent("RFA") --[[@as RFAWorldViewComponent]]
            if rfa then
                rfa.BuildPreviewKey = opt()
            end
        end
    end
    --#endregion

    local buildersCategory = categories.REPAIR + categories.RECLAIM + categories.xrl0403

    local overlaySortOrder = {
        ["AllMilitary"] = 1,
        ["IndirectFire"] = 2,
        ["AntiAir"] = 3,
        ["Defense"] = 4,
        ["AntiNavy"] = 5,
        ["Omni"] = 6,
        ["CounterIntel"] = 7,
        ["Radar"] = 8,
        ["Sonar"] = 9,
    }
    ---@type table<UnitId, table<string, true>>
    local unitsWithWeaponRangeEnh = {
        ual0001 = { OverCharge = true, AutoOverCharge = true, RightDisruptor = true, ChronoDampener = true },
        uel0001 = { OverCharge = true, AutoOverCharge = true, RightZephyr = true },
        url0001 = { OverCharge = true, AutoOverCharge = true, RightRipper = true, MLG = true },
        xsl0001 = { OverCharge = true, AutoOverCharge = true, ChronotronCannon = true },

        ual0301 = { RightReactonCannon = true },
        uel0301 = { RightHeavyPlasmaCannon = true },
        url0301 = { RightDisintegrator = true },
        xsl0301 = { LightChronatronCannon = true, OverCharge = true, AutoOverCharge = true },
    }

    local unitsWithIntelEnh = {
        url0001 = true,

        ual0001 = true,
        uel0301 = true,
        xsl0301 = true,
    }

    local intelToEnhancement = {
        OmniRadius = "NewOmniRadius",
        RadarRadius = "NewRadarRadius",
    }

    local intelWithRangeRing = {
        "OmniRadius",
        "RadarRadius",
        "SonarRadius",
        "CloakFieldRadius",
        "SonarStealthFieldRadius",
        "RadarStealthFieldRadius",
    }

    local isWaterSurfaceMotionType = {
        RULEUMT_Water = true,
        RULEUMT_Hover = true,
        RULEUMT_AmphibiousFloating = true,
    }

    ---@type table<UnitId, IUnitBlueprint>
    local IBPByBpIdCache = ReUI.Core.Weak.Value {}
    ---@type table<UserUnit, IUnitBlueprint>
    local IBPByUnitCache = ReUI.Core.Weak.Key {}
    local EntityIdToUnitCache = ReUI.Core.Weak.Value {}

    local lastEnhSyncTable = {}
    AddOnSyncHashedCallback(
    ---@param enhSyncTable EnhancementSyncTable
        function(enhSyncTable)
            -- sim re-evaluates all enhancements for all units every time an enhancement is built/removed...
            -- Check for changes to prevent trashing our IBPs

            for entityId, enhSync in enhSyncTable do
                local lastEnhSync = lastEnhSyncTable[entityId]
                local unit = EntityIdToUnitCache[entityId]
                if not unit then continue end

                -- unit got first enhancement and was added to table
                if not lastEnhSync then
                    IBPByUnitCache[unit] = nil
                else -- unit's enhancements may have changed
                    local changed = false
                    for slot, enh in enhSync do
                        if lastEnhSync[slot] ~= enh then
                            IBPByUnitCache[unit] = nil
                            changed = true
                            break
                        end
                    end

                    -- set nil so we don't check it again later on
                    lastEnhSyncTable[entityId] = nil

                    if changed then continue end
                end
            end

            -- unit lost all enh and was removed from table
            for entityId, enhSync in lastEnhSyncTable do
                local unit = EntityIdToUnitCache[entityId]
                if unit then
                    IBPByUnitCache[unit] = nil
                end
            end

            lastEnhSyncTable = enhSyncTable
        end,
        "UserUnitEnhancements",
        'RFA_DirtyIBPByUnitCache'
    )

    ---@class IWeaponBlueprint
    ---@field MaxRadius number
    ---@field RangeCategory WeaponRangeCategory

    ---@class IUnitBlueprint
    ---@field Weapon? IWeaponBlueprint[]
    ---@field Intel UnitBlueprintIntel

    ---@param obp UnitBlueprint
    ---@param activeEnhs? EnhancementSyncData | Enhancement[]
    ---@return IUnitBlueprint
    local function GenerateIBP(obp, activeEnhs)
        if not activeEnhs then activeEnhs = EmptyTable end

        ---@type IUnitBlueprint
        local ibp = {
            Weapon = {},
            Intel = {},
        }

        local id = obp.EnhancementPresetAssigned.BaseBlueprintId or obp.BlueprintId
        local obpEnh = obp.Enhancements --[[@as table<Enhancement, UnitBlueprintEnhancement>]]
        -- function only gets called after we checked for enhancements

        local weaponsAffectedByRangeEnh = unitsWithWeaponRangeEnh[id]
        local newMaxRadius = Enumerate(obpEnh, next)
            :Where(function(value, key)
                return Contains(activeEnhs, key)
            end)
            :Select(function(value, key)
                return value.NewMaxRadius
            end)
            :Max()

        ---@param w WeaponBlueprint
        for i, w in obp.Weapon do
            -- Skip adding disabled weapons to IBp
            local enh = w.EnabledByEnhancement
            if enh and not Contains(activeEnhs, enh) then
                continue
            end

            TableInsert(ibp.Weapon, {
                RangeCategory = w.RangeCategory,
                MaxRadius = weaponsAffectedByRangeEnh[w.Label] and newMaxRadius or w.MaxRadius,
                MinRadius = w.MinRadius,
            })
        end

        if unitsWithIntelEnh[id] then
            local ibpIntel = ibp.Intel
            local obpIntel = obp.Intel
            for _, intelType in intelWithRangeRing do
                local enhIntel = intelToEnhancement[intelType]
                ibpIntel[intelType] = Enumerate(activeEnhs, next)
                    :Select(function(value, key) return obpEnh[value][enhIntel] end)
                    :Max()
                    or obpIntel[intelType]
            end
        else
            ibp.Intel = obp.Intel
        end

        return ibp
    end

    ---@param unit UserUnit
    ---@return IUnitBlueprint | UnitBlueprint
    local function GetEnhancedBlueprintFromUnit(unit)
        local bp = unit:GetBlueprint()

        if bp.Enhancements then
            local cachedBP = IBPByUnitCache[unit]
            if not cachedBP then
                local id = unit:GetEntityId()
                cachedBP = GenerateIBP(bp, GetEnhancements(id))
                IBPByUnitCache[unit] = cachedBP
                EntityIdToUnitCache[id] = unit
            end
            return cachedBP
        end

        return bp
    end

    ---@param bpId UnitId
    ---@return IUnitBlueprint | UnitBlueprint
    local function GetEnhancedBlueprintFromId(bpId)
        local bp = __blueprints[bpId] --[[@as UnitBlueprint]]

        -- Check for `bp.EnhancementPresets` instead of `bp.Enhancements` so that ACUs always show all weapons, since they're likely upgraded while SACU are not
        -- `bp.EnhancementPresets == nil` for units with presets
        if bp.EnhancementPresets or bp.EnhancementPresetAssigned then
            local cachedBP = IBPByBpIdCache[bpId]
            if not cachedBP then
                cachedBP = GenerateIBP(bp, bp.EnhancementPresetAssigned.Enhancements)
                IBPByBpIdCache[bpId] = cachedBP
            end
            return cachedBP
        end

        return bp
    end

    ---@param bp IUnitBlueprint | UnitBlueprint
    ---@return RingData[]
    local function GetBPInfo(bp)
        local weapons = {}
        if bp.Weapon ~= nil and not TableEmpty(bp.Weapon) then
            for _wIndex, w in bp.Weapon do
                local radius = w.MaxRadius
                local minRadius = w.MinRadius
                local function AddRadii(type)
                    TableInsert(weapons, { type, radius })
                    if minRadius > 0 then TableInsert(weapons, { type, minRadius }) end
                end
                if showDirectFire and w.RangeCategory == "UWRC_DirectFire" then
                    AddRadii("AllMilitary")
                elseif showIndirectFire and w.RangeCategory == "UWRC_IndirectFire" then
                    AddRadii("IndirectFire")
                elseif showAntiAir and w.RangeCategory == "UWRC_AntiAir" then
                    AddRadii("AntiAir")
                elseif showCountermeasure and w.RangeCategory == "UWRC_Countermeasure" then
                    AddRadii("Defense")
                elseif showAntiNavy and w.RangeCategory == "UWRC_AntiNavy" then
                    AddRadii("AntiNavy")
                end
            end
        end
        local intel = bp.Intel
        if intel ~= nil then
            if showOmni and intel.OmniRadius > 0 then
                TableInsert(weapons, { "Omni", intel.OmniRadius })
            end
            if showRadar and intel.RadarRadius > 0 then
                TableInsert(weapons, { "Radar", intel.RadarRadius })
            end
            if showSonar and intel.SonarRadius > 0 then
                TableInsert(weapons, { "Sonar", intel.SonarRadius })
            end
            if showCounterIntel and
                (
                intel.CloakFieldRadius > 0
                    or intel.SonarStealthFieldRadius > 0
                    or intel.RadarStealthFieldRadius > 0
                )
            then
                TableInsert(weapons,
                    { "CounterIntel",
                        MathMax(intel.CloakFieldRadius, intel.SonarStealthFieldRadius, intel.RadarStealthFieldRadius) })
            end
        end

        if showShield then
            local shield = bp.Defense.Shield
            if shield and not shield.PersonalShield and not shield.PersonalBubble and not shield.TransportShield then
                local radius = (shield.ShieldSize or 10) / 2
                local height = (shield.ShieldVerticalOffset or -1) + bp.SizeY / 2
                local range = MathSqrt(radius * radius - height * height)
                TableInsert(weapons, { "Defense", range })
            end
        end

        return weapons
    end

    ---@param unit UserUnit
    ---@return number
    local function GetActualBuildRange(unit)
        local commandMode = GetCommandMode()
        local buildPreviewSkirtSize = 1
        if commandMode[1] == 'build' then
            local bpPhysics = __blueprints[commandMode[2].name].Physics
            if bpPhysics then
                buildPreviewSkirtSize = MathMax(bpPhysics.SkirtSizeX, bpPhysics.SkirtSizeZ)
            end
        elseif commandMode[1] == 'order' then
            local orderName = commandMode[2].name
            if orderName == "RULEUCC_Repair" then
                local info = GetRolloverInfo()
                ---@diagnostic disable-next-line: param-type-mismatch
                if info and IsAlly(info.armyIndex + 1, GetFocusArmy()) then
                    local bpPhysics = __blueprints[info.blueprintId].Physics
                    if bpPhysics then
                        buildPreviewSkirtSize = MathMax(bpPhysics.SkirtSizeX, bpPhysics.SkirtSizeZ)
                    end
                end
            elseif orderName == "RULEUCC_Reclaim" then
                local info = GetRolloverInfo()
                if info then
                    local bpFoot = __blueprints[info.blueprintId].Footprint
                    if bpFoot then
                        ---@diagnostic disable-next-line: cast-local-type
                        buildPreviewSkirtSize = MathMax(bpFoot.SizeX, bpFoot.SizeZ)
                    end
                end
            elseif orderName == "RULEUCC_Capture" then
                local info = GetRolloverInfo()
                if info then
                    local bpFoot = __blueprints[info.blueprintId].Footprint
                    if bpFoot then
                        ---@diagnostic disable-next-line: cast-local-type
                        buildPreviewSkirtSize = MathMax(bpFoot.SizeX, bpFoot.SizeZ)
                    end
                end
                local bp = unit:GetBlueprint()
                local bpFoot = bp.Footprint
                local captureDistance
                if bp.Physics.MotionType == "RULEUMT_None" then
                    captureDistance = 10
                else
                    captureDistance = 5
                end
                ---@diagnostic disable-next-line: need-check-nil
                return captureDistance + MathMax(bpFoot.SizeX, bpFoot.SizeZ) + buildPreviewSkirtSize
            end
        end

        local bp = unit:GetBlueprint()
        local bpFoot = bp.Footprint
        ---@diagnostic disable-next-line: need-check-nil
        return (bp.Economy.MaxBuildDistance or 5) + MathMax(bpFoot.SizeX, bpFoot.SizeZ) + buildPreviewSkirtSize
    end

    ---@param unit UserUnit
    ---@return number
    local function GetSimpleBuildRange(unit)
        local bp = unit:GetBlueprint()
        return (bp.Economy.MaxBuildDistance or 5) + 2
    end

    ---@type fun(unit:UserUnit):number
    local buildRangeFunc

    options.displayActualBuildRange:Bind(function(opt)
        if opt() then
            buildRangeFunc = GetActualBuildRange
        else
            buildRangeFunc = GetSimpleBuildRange
        end
    end)

    ---@param a RingData
    ---@param b RingData
    local function OverlaySortFunction(a, b)
        return overlaySortOrder[ a[1] ] > overlaySortOrder[ b[1] ]
    end

    local GetSelectionRingData = IPairsEnumerator
        :Select(GetEnhancedBlueprintFromUnit)
        :Distinct()
        :Select(GetBPInfo)
        :SelectMany()
        :OrderByDescending(function(value)
            return overlaySortOrder[ value[1] ]
        end)
        :ToArray()

    local GetMaxBuildRange = IPairsEnumerator
        :Select(function(unit) return buildRangeFunc(unit) end)
        :Max()

    ---@param type string
    ---@param colorType "NormalColor" | "SelectColor" | "RolloverColor" | nil
    ---@return string
    ---@return number
    local function GetColorAndThickness(type, colorType)
        local params = overlayParams[type]
        if not colorType then colorType = "NormalColor" end
        return ("ff%s"):format((params[colorType]):sub(3)), params.Outer[1] / params.Type
    end

    local function TableClear(t)
        for k in t do
            t[k] = nil
        end
    end

    --- Retrieves cursor information from the engine statistics
    ---@return { Position: string, Elevation: number, OCell: string, LODMetric: number }
    local function GetCursorInformation()
        local cursor = { }
        if __EngineStats and __EngineStats.Children then
            for _, a in __EngineStats.Children do
                if a.Name == 'Camera' then
                    for _, b in a.Children do
                        if b.Name == 'Cursor' then
                            for _, c in b.Children do
                                cursor[c.Name] = c.Value
                            end
                            break
                        end
                    end
                end
            end
        end

        return cursor
    end

    ---@class Ring
    ---@field pos Vector
    ---@field color string
    ---@field radius number
    ---@field thickness number
    local Ring = ClassSimple
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

    local function CreateRing(type, range)
        local ring = Ring()
        local color, thick = GetColorAndThickness(type)
        ring:SetColor(color)
        ring:SetRadius(range)
        ring:SetPosition(GetMouseWorldPos())
        ring.thickness = thick
        ring.type = type
        ring.range = range
        return ring
    end

    ---@class RFAWorldViewComponent : ReUI.WorldView.Component, UIShape
    ---@field _hoverRings Ring[]
    ---@field _selectionRings Ring[]
    ---@field _buildRing Ring
    ---@field _showRings boolean
    ---@field _cachedSelection UserUnit[]?
    ---@field _isCachedSelection boolean
    local RFAWorldViewComponent = ReUI.Core.Class(ReUI.WorldView.Component)
    {
        HoverPreviewKey = options.hoverPreviewKey(),
        SelectedPreviewKey = options.selectedPreviewKey(),
        BuildPreviewKey = options.buildPreviewKey(),

        ---Called when component is initialized
        ---@param self RFAWorldViewComponent
        OnInit = function(self)
            self._isCachedSelection = false
            self._hoverRings = {}
            self._selectionRings = {}
            self._buildRing = nil
            self._showRings = true
        end,

        ---@param self RFAWorldViewComponent
        OnEnabled = function(self)
            self.worldView:AddShape(self, self.name)
        end,

        ---@param self RFAWorldViewComponent
        OnDisabled = function(self)
            self.worldView:RemoveShape(self.name)
        end,

        ---@param self RFAWorldViewComponent
        ---@param rings Ring[]
        RenderRings = function(self, rings)
            for _, ring in rings do
                ring:Render()
            end
        end,

        OnRender = true,

        ---@param self RFAWorldViewComponent
        ---@param delta number
        Render = function(self, delta)
            if not self._showRings then
                return
            end

            self:RenderRings(self._hoverRings)
            self:RenderRings(self._selectionRings)
            if self._buildRing then
                self._buildRing:Render()
            end
        end,

        ---@param self RFAWorldViewComponent
        ClearBuildRings = function(self)
            self._buildRing = nil
        end,

        ---@param self RFAWorldViewComponent
        ClearSelectionRings = function(self)
            local rings = self._selectionRings
            if not rings then return end

            TableClear(rings)
        end,

        ---@param self RFAWorldViewComponent
        ClearHoverRings = function(self)
            local rings = self._hoverRings
            if not rings then return end

            TableClear(rings)
        end,

        ---@param self RFAWorldViewComponent
        ---@return UserUnit[]?
        GetSelectedUnits = function(self)
            if self._isCachedSelection then
                return self._cachedSelection
            end
            self._cachedSelection = GetSelectedUnits()
            self._isCachedSelection = true
            return self._cachedSelection
        end,

        ---Called when grid worldview receives an event
        ---@param self RFAWorldViewComponent
        ---@param event KeyEvent
        ---@return boolean
        OnHandleEvent = function(self, event)
            if event.Type == "MouseExit" then
                self:ClearBuildRings()
                self:ClearHoverRings()
                self:ClearSelectionRings()
            end
            return false
        end,

        ---@param self RFAWorldViewComponent
        ---@param rings Ring[]
        ---@param ringsData RingData[]
        UpdateRings = function(self, rings, ringsData)
            if TableGetn(ringsData) > TableGetn(rings) then
                for i, d in ringsData do
                    local ring = rings[i]
                    if ring then
                        self.UpdateRing(ring, unpack(d))
                    else
                        rings[i] = CreateRing(unpack(d))
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

        ---@param self RFAWorldViewComponent
        UpdateReclaimRings = function(self)
            local selection = self:GetSelectedUnits()
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

        ---@param self RFAWorldViewComponent
        UpdateHoverRings = function(self)
            local info = GetRolloverInfo()
            local bpId = info.blueprintId
            if not (info and bpId ~= "unknown") then
                self:ClearHoverRings()
                return
            end

            local weapons
            local unit = info.userUnit
            if unit then
                weapons = GetBPInfo(GetEnhancedBlueprintFromUnit(unit))
            else
                weapons = GetBPInfo(GetEnhancedBlueprintFromId(bpId))
            end

            if TableEmpty(weapons) then
                self:ClearHoverRings()
                return
            end
            TableSort(weapons, OverlaySortFunction)
            self:UpdateRings(self._hoverRings, weapons)
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

        ---@param self RFAWorldViewComponent
        UpdateSelectionRings = function(self)
            local selection = self:GetSelectedUnits()
            if not selection then
                self:ClearSelectionRings()
                return
            end

            self:UpdateRings(self._selectionRings, GetSelectionRingData(selection))
        end,

        ---@param self RFAWorldViewComponent
        ---@param useMousePos boolean
        UpdateBuildRings = function(self, useMousePos)
            local selection = self:GetSelectedUnits()
            if not selection then
                self:ClearBuildRings()
                return
            end
            ---@type UserUnit[]
            local builders = EntityCategoryFilterDown(buildersCategory, selection)
            if TableEmpty(builders) then
                self:ClearBuildRings()
                return
            end

            local radius = GetMaxBuildRange(builders)

            local orderType
            local colorType

            ---@type Ring
            local ring = Ring()
            if useMousePos then
                ring.pos = GetMouseWorldPos()
            else
                orderType = GetCommandMode()[1]

                local unit = builders[1]
                local pos = unit:GetInterpolatedPosition()
                if IsKeyDown("Shift") then
                    local queue = unit:GetCommandQueue()
                    for i = TableGetn(queue), 1, -1 do
                        local commandType = queue[i].type
                        if commandType == "Move"
                            or commandType == "Teleport"
                            or commandType == "AggressiveMove"
                            or commandType == "Patrol" then
                            pos = queue[i].position
                            pos[1] = MathFloor(pos[1]) + 0.5
                            pos[3] = MathFloor(pos[3]) + 0.5
                            break
                        end
                    end
                end


                local info = GetRolloverInfo()
                local rolloverUnit = info.userUnit
                if displayBuildRingAtMouseHeight then
                    local newY

                    if orderType == "build" then
                        newY = GetMouseWorldPos()[2]
                    else
                        if info then
                            if rolloverUnit then
                                newY = rolloverUnit:GetPosition()[2]
                            else
                                local rolloverBp = __blueprints[info.blueprintId]
                                local bpPhysics = rolloverBp.Physics
                                local motionType = bpPhysics.MotionType

                                if isWaterSurfaceMotionType[motionType]
                                    or motionType == "RULEUMT_None" and not bpPhysics.BuildOnLayerCaps["LAYER_Seabed"]
                                then
                                    newY = GetMouseWorldPos()[2]
                                elseif motionType == "RULEUMT_SurfacingSub" then
                                    newY = GetMouseWorldPos()[2] + bpPhysics.Elevation
                                else
                                    newY = GetCursorInformation().Elevation
                                end
                            end
                        else
                            newY = GetCursorInformation().Elevation
                        end
                    end

                    pos[2] = newY
                end
                ring.pos = pos

                local targetPos
                if orderType == "build" then
                    targetPos = GetMouseWorldPos()
                    targetPos[1] = MathFloor(targetPos[1]) + 0.5
                    targetPos[3] = MathFloor(targetPos[3]) + 0.5
                elseif rolloverUnit then
                    targetPos = rolloverUnit:GetPosition()
                else
                    targetPos = GetMouseWorldPos()
                end
                if XZDistanceTwoVectorsSquared(targetPos, pos) <= radius * radius then
                    colorType = "RolloverColor"
                end
            end
            ring.radius = radius
            local color, thick = GetColorAndThickness("Miscellaneous", colorType)
            ring.thickness = thick
            ring:SetColor(color)
            self._buildRing = ring
        end,


        ---@param self RFAWorldViewComponent
        OnUpdateCursor = function(self)
            if not self._showRings then return end

            local commandMode = GetCommandMode()
            local orderType = commandMode[1]
            local orderName = commandMode[2].name
            local givingMoveOrder = orderType == "order" and orderName == "RULEUCC_Move"
            local notIssuingOrder = not commandMode[2]
            self._isCachedSelection = false

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

                if IsKeyDown(18) then --alt
                    self:UpdateReclaimRings()
                elseif IsKeyDown(self.BuildPreviewKey) then
                    self:UpdateBuildRings(true)
                else
                    self:ClearBuildRings()
                end
            elseif self._buildRing
                or orderType == "build"
                or orderType == "order"
                and (orderName == "RULEUCC_Repair"
                    or orderName == "RULEUCC_Reclaim"
                    or orderName == "RULEUCC_Guard"
                    or orderName == "RULEUCC_Capture")
            then
                self:UpdateBuildRings(false)
            end
        end,

        ---Called when component is destroyed
        ---@param self RFAWorldViewComponent
        OnDestroy = function(self)
            self:ClearHoverRings()
            self._hoverRings = nil
            self:ClearSelectionRings()
            self._selectionRings = nil
            self._buildRing = nil
            self._showRings = false
            self._isCachedSelection = false
            self._cachedSelection = nil
        end,
    }

    ReUI.WorldView.PrimaryComponents.RFA = RFAWorldViewComponent
end
