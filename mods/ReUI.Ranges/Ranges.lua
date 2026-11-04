Version = "1.0.0"

ReUI.Require
{
    "ReUI.Core >= 1.5.0",
    "ReUI.LINQ >= 1.4.0",
    "ReUI.Options >= 2.0.0",
    "ReUI.WorldView >= 1.0.0",
    enabled = true,
}

function Main(isReplay)

    --#region Upvalues
    local GetSelectedUnits = GetSelectedUnits
    local GetMouseWorldPos = GetMouseWorldPos
    local GetRolloverInfo = GetRolloverInfo
    local GetFocusArmy = GetFocusArmy
    local IsKeyDown = IsKeyDown
    local MathMax = math.max
    local MathMin = math.min
    local MathFloor = math.floor
    local TableInsert = table.insert
    local TableRemove = table.remove
    local TableGetn = table.getn
    local TableEmpty = table.empty
    local UI_DrawCircle = UI_DrawCircle
    local EmptyTable = EmptyTable
    local EntityCategoryFilterDown = EntityCategoryFilterDown
    --#endregion

    local options = ReUI.Options.Mods["ReUI.Ranges"]

    local Enumerate = ReUI.LINQ.Enumerate
    local PairsEnumerator = ReUI.LINQ.PairsEnumerator
    local Contains = PairsEnumerator:Contains()

    local GetCommandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode
    local overlayParams = import("/lua/ui/game/rangeoverlayparams.lua").RangeOverlayParams
    local GetWorldViews = import("/lua/ui/game/worldview.lua").GetWorldViews
    local GetEnhancements = import("/lua/enhancementcommon.lua").GetEnhancements

    --#region Options & Bindings
    local hoverPreviewKey = "SHIFT"
    local selectedPreviewKey = "SHIFT"
    local buildPreviewKey = "SHIFT"
    local selectionRangeMode = "all"
    local ringOpacity = 100
    local currentAlphaHex = "ff"

    local showDirectFire = true
    local showIndirectFire = true
    local showAntiAir = true
    local showAntiNavy = true
    local showCountermeasure = true
    local showOmni = true
    local showRadar = true
    local showSonar = true
    local showCounterIntel = true
    local showShield = true
    local showInMinimap = false

    options.hoverPreviewKey:Bind(function(opt, val)
        hoverPreviewKey = val
    end)
    options.selectedPreviewKey:Bind(function(opt, val)
        selectedPreviewKey = val
    end)
    options.buildPreviewKey:Bind(function(opt, val)
        buildPreviewKey = val
    end)
    options.selectionRangeMode:Bind(function(opt, val)
        selectionRangeMode = val
    end)
    options.ringOpacity:Bind(function(opt, val)
        ringOpacity = val or 100
        local alpha = MathFloor(MathMax(0, MathMin(255, ringOpacity * 2.55)))
        currentAlphaHex = string.format("%02x", alpha)
    end)

    options.ringOpacity.OnChanged:Add(function(var, val)
        for _, view in GetWorldViews() do
            local comp = view:GetComponent("Ranges")
            if comp then
                comp:ResetRings()
            end
        end
    end)

    options.showDirectFire:Bind(function(opt, val)
        showDirectFire = val
    end)
    options.showIndirectFire:Bind(function(opt, val)
        showIndirectFire = val
    end)
    options.showAntiAir:Bind(function(opt, val)
        showAntiAir = val
    end)
    options.showAntiNavy:Bind(function(opt, val)
        showAntiNavy = val
    end)
    options.showShield:Bind(function(opt, val)
        showShield = val
    end)
    options.showCountermeasure:Bind(function(opt, val)
        showCountermeasure = val
    end)
    options.showOmni:Bind(function(opt, val)
        showOmni = val
    end)
    options.showRadar:Bind(function(opt, val)
        showRadar = val
    end)
    options.showSonar:Bind(function(opt, val)
        showSonar = val
    end)
    options.showCounterIntel:Bind(function(opt, val)
        showCounterIntel = val
    end)
    options.showInMinimap:Bind(function(opt, val)
        showInMinimap = val
    end)
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

    ---@type table<UnitId, IUnitBlueprint>
    local IBPByBpIdCache = ReUI.Core.Weak.Value {}
    ---@type table<UserUnit, IUnitBlueprint>
    local IBPByUnitCache = ReUI.Core.Weak.Key {}
    local EntityIdToUnitCache = ReUI.Core.Weak.Value {}

    local lastEnhSyncTable = {}
    AddOnSyncHashedCallback(
    ---@param enhSyncTable EnhancementSyncTable
        function(enhSyncTable)
            for entityId, enhSync in enhSyncTable do
                local lastEnhSync = lastEnhSyncTable[entityId]
                local unit = EntityIdToUnitCache[entityId]
                if unit then
                    if not lastEnhSync then
                        IBPByUnitCache[unit] = nil
                    else
                        local changed = false
                        for slot, enh in enhSync do
                            if lastEnhSync[slot] ~= enh then
                                IBPByUnitCache[unit] = nil
                                changed = true
                                break
                            end
                        end
                        lastEnhSyncTable[entityId] = nil
                    end
                end
            end

            for entityId, _ in lastEnhSyncTable do
                local unit = EntityIdToUnitCache[entityId]
                if unit then
                    IBPByUnitCache[unit] = nil
                end
            end

            lastEnhSyncTable = enhSyncTable
        end,
        "UserUnitEnhancements",
        'ReUI_Ranges_DirtyIBPByUnitCache'
    )

    ---@class IWeaponBlueprint
    ---@field MaxRadius number
    ---@field RangeCategory WeaponRangeCategory
    ---@field Label string
    ---@field EnabledByEnhancement? string

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

        local id = (obp.EnhancementPresetAssigned and obp.EnhancementPresetAssigned.BaseBlueprintId) or obp.BlueprintId
        local obpEnh = obp.Enhancements --[[@as table<Enhancement, UnitBlueprintEnhancement>]]

        local weaponsAffectedByRangeEnh = unitsWithWeaponRangeEnh[id]
        local newMaxRadius = nil
        if obpEnh then
            newMaxRadius = Enumerate(obpEnh, next)
                :Where(function(value, key)
                    return Contains(activeEnhs, key)
                end)
                :Select(function(value, key)
                    return value.NewMaxRadius
                end)
                :Max()
        end

        if obp.Weapon then
            ---@param w WeaponBlueprint
            for _, w in obp.Weapon do
                local enh = w.EnabledByEnhancement
                if not (enh and not Contains(activeEnhs, enh)) then
                    local isAffected = weaponsAffectedByRangeEnh and weaponsAffectedByRangeEnh[w.Label]
                    TableInsert(ibp.Weapon, {
                        RangeCategory = w.RangeCategory,
                        Label = w.Label,
                        MaxRadius = (isAffected and newMaxRadius) or w.MaxRadius
                    })
                end
            end
        end

        if unitsWithIntelEnh[id] and obpEnh then
            local ibpIntel = ibp.Intel
            local obpIntel = obp.Intel
            for _, intelType in intelWithRangeRing do
                local enhIntel = intelToEnhancement[intelType]
                if enhIntel then
                    ibpIntel[intelType] = Enumerate(activeEnhs, next)
                        :Select(function(value, key)
                            local e = obpEnh[value]
                            return e and e[enhIntel]
                        end)
                        :Max()
                        or obpIntel[intelType]
                else
                    ibpIntel[intelType] = obpIntel[intelType]
                end
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
        if not bp then return bp end

        if bp.EnhancementPresets or bp.EnhancementPresetAssigned then
            local cachedBP = IBPByBpIdCache[bpId]
            if not cachedBP then
                local assignedEnhs = bp.EnhancementPresetAssigned and bp.EnhancementPresetAssigned.Enhancements
                cachedBP = GenerateIBP(bp, assignedEnhs)
                IBPByBpIdCache[bpId] = cachedBP
            end
            return cachedBP
        end

        return bp
    end

    ---@param type string
    ---@return string
    ---@return number
    local function GetColorAndThickness(type)
        local params = overlayParams[type]
        if not params then
            return currentAlphaHex .. "ffffff", 0.15
        end
        return (currentAlphaHex .. (params.NormalColor):sub(3)), params.Outer[1] / params.Type
    end

    ---Helper to set or update a range entry in a key-based container.
    ---If a range already exists, keep the overlay type with higher priority (lower overlaySortOrder value).
    ---@param container table<number, string>
    ---@param range number
    ---@param overlayType string
    local function SetRingDataKeyed(container, range, overlayType)
        local existingType = container[range]
        if not existingType then
            container[range] = overlayType
        else
            local existingOrder = overlaySortOrder[existingType] or 99
            local newOrder = overlaySortOrder[overlayType] or 99
            if newOrder < existingOrder then
                container[range] = overlayType
            end
        end
    end

    ---Helper to add a range to a type's range set
    ---@param rangesByType table<string, table<number, true>>
    ---@param overlayType string
    ---@param radius number
    local function AddRangeForType(rangesByType, overlayType, radius)
        local typeRanges = rangesByType[overlayType]
        if not typeRanges then
            typeRanges = {}
            rangesByType[overlayType] = typeRanges
        end
        typeRanges[radius] = true
    end

    ---Returns key-based ring data for a single unit blueprint (used for rollover/hover preview).
    ---Duplicate weapons with the same range are automatically merged by range key.
    ---@param bp IUnitBlueprint | UnitBlueprint
    ---@return table<number, string> # key is range, value is overlayType
    local function GetHoverRingsData(bp)
        local rings = {}
        if not bp then return rings end

        if bp.Weapon and not TableEmpty(bp.Weapon) then
            for _, w in bp.Weapon do
                local radius = w.MaxRadius
                if radius and radius > 0 then
                    local cat = w.RangeCategory
                    if showDirectFire and cat == "UWRC_DirectFire" then
                        SetRingDataKeyed(rings, radius, "AllMilitary")
                    elseif showIndirectFire and cat == "UWRC_IndirectFire" then
                        SetRingDataKeyed(rings, radius, "IndirectFire")
                    elseif showAntiAir and cat == "UWRC_AntiAir" then
                        SetRingDataKeyed(rings, radius, "AntiAir")
                    elseif showCountermeasure and cat == "UWRC_Countermeasure" then
                        SetRingDataKeyed(rings, radius, "Defense")
                    elseif showAntiNavy and cat == "UWRC_AntiNavy" then
                        SetRingDataKeyed(rings, radius, "AntiNavy")
                    end
                end
            end
        end

        local intel = bp.Intel
        if intel then
            if showOmni and intel.OmniRadius and intel.OmniRadius > 0 then
                SetRingDataKeyed(rings, intel.OmniRadius, "Omni")
            end
            if showRadar and intel.RadarRadius and intel.RadarRadius > 0 then
                SetRingDataKeyed(rings, intel.RadarRadius, "Radar")
            end
            if showSonar and intel.SonarRadius and intel.SonarRadius > 0 then
                SetRingDataKeyed(rings, intel.SonarRadius, "Sonar")
            end
            if showCounterIntel then
                local cloak = intel.CloakFieldRadius or 0
                local sonarStealth = intel.SonarStealthFieldRadius or 0
                local radarStealth = intel.RadarStealthFieldRadius or 0
                local maxCounter = MathMax(cloak, sonarStealth, radarStealth)
                if maxCounter > 0 then
                    SetRingDataKeyed(rings, maxCounter, "CounterIntel")
                end
            end
        end

        if showShield then
            local shield = bp.Defense.Shield
            if shield and not shield.PersonalShield and not shield.PersonalBubble and not shield.TransportShield then
                local radius = (shield.ShieldSize or 10) / 2
                local height = (shield.ShieldVerticalOffset or -1) + bp.SizeY / 2
                local range = math.sqrt(radius * radius - height * height)
                SetRingDataKeyed(rings, range, "Defense")
            end
        end

        return rings
    end

    ---Collects all ring data for current selection, using key-based deduplication
    ---and applying the selectionRangeMode option ("all", "min_max", or "max") PER TYPE.
    ---@param selection UserUnit[]
    ---@return table<number, string> # key is range, value is overlayType
    local function GetSelectionRingsData(selection)
        local rangesByType = {}
        local visitedBPs = {}

        for _, unit in selection do
            local bp = GetEnhancedBlueprintFromUnit(unit)
            if bp and not visitedBPs[bp] then
                visitedBPs[bp] = true

                -- Collect weapon ranges grouped by overlay type
                if bp.Weapon and not TableEmpty(bp.Weapon) then
                    for _, w in bp.Weapon do
                        local radius = w.MaxRadius
                        if radius and radius > 0 then
                            local cat = w.RangeCategory
                            if showDirectFire and cat == "UWRC_DirectFire" then
                                AddRangeForType(rangesByType, "AllMilitary", radius)
                            elseif showIndirectFire and cat == "UWRC_IndirectFire" then
                                AddRangeForType(rangesByType, "IndirectFire", radius)
                            elseif showAntiAir and cat == "UWRC_AntiAir" then
                                AddRangeForType(rangesByType, "AntiAir", radius)
                            elseif showCountermeasure and cat == "UWRC_Countermeasure" then
                                AddRangeForType(rangesByType, "Defense", radius)
                            elseif showAntiNavy and cat == "UWRC_AntiNavy" then
                                AddRangeForType(rangesByType, "AntiNavy", radius)
                            end
                        end
                    end
                end

                -- Collect intel ranges grouped by overlay type
                local intel = bp.Intel
                if intel then
                    if showOmni and intel.OmniRadius and intel.OmniRadius > 0 then
                        AddRangeForType(rangesByType, "Omni", intel.OmniRadius)
                    end
                    if showRadar and intel.RadarRadius and intel.RadarRadius > 0 then
                        AddRangeForType(rangesByType, "Radar", intel.RadarRadius)
                    end
                    if showSonar and intel.SonarRadius and intel.SonarRadius > 0 then
                        AddRangeForType(rangesByType, "Sonar", intel.SonarRadius)
                    end
                    if showCounterIntel then
                        local cloak = intel.CloakFieldRadius or 0
                        local sonarStealth = intel.SonarStealthFieldRadius or 0
                        local radarStealth = intel.RadarStealthFieldRadius or 0
                        local maxCounter = MathMax(cloak, sonarStealth, radarStealth)
                        if maxCounter > 0 then
                            AddRangeForType(rangesByType, "CounterIntel", maxCounter)
                        end
                    end
                end

                if showShield then
                    local shield = bp.Defense.Shield
                    if shield and not shield.PersonalShield and not shield.PersonalBubble and not shield.TransportShield then
                        local radius = (shield.ShieldSize or 10) / 2
                        local height = (shield.ShieldVerticalOffset or -1) + bp.SizeY / 2
                        local range = math.sqrt(radius * radius - height * height)
                        AddRangeForType(rangesByType, "Defense", range)
                    end
                end
            end
        end

        local finalRings = {}

        -- Filter ranges per type according to selectionRangeMode
        for overlayType, ranges in rangesByType do
            if selectionRangeMode == "min_max" then
                local minRange = nil
                local maxRange = nil
                for r in ranges do
                    if not minRange or r < minRange then
                        minRange = r
                    end
                    if not maxRange or r > maxRange then
                        maxRange = r
                    end
                end

                if minRange then
                    SetRingDataKeyed(finalRings, minRange, overlayType)
                end
                if maxRange and maxRange ~= minRange then
                    SetRingDataKeyed(finalRings, maxRange, overlayType)
                end
            elseif selectionRangeMode == "max" then
                local maxRange = nil
                for r in ranges do
                    if not maxRange or r > maxRange then
                        maxRange = r
                    end
                end

                if maxRange then
                    SetRingDataKeyed(finalRings, maxRange, overlayType)
                end
            else -- "all"
                for r in ranges do
                    SetRingDataKeyed(finalRings, r, overlayType)
                end
            end
        end

        return finalRings
    end

    ---@param unit UserUnit
    ---@return number
    local function GetActualBuildRange(unit)
        local commandMode = GetCommandMode()
        local buildPreviewSkirtSize = 1
        if commandMode[1] == 'build' and commandMode[2] and commandMode[2].name then
            local bp = __blueprints[commandMode[2].name]
            local bpPhysics = bp and bp.Physics
            if bpPhysics then
                buildPreviewSkirtSize = MathMax(bpPhysics.SkirtSizeX or 1, bpPhysics.SkirtSizeZ or 1)
            end
        elseif commandMode[1] == 'order' and commandMode[2] and commandMode[2].name then
            local orderName = commandMode[2].name
            if orderName == "RULEUCC_Repair" then
                local info = GetRolloverInfo()
                if info and info.blueprintId and info.armyIndex and IsAlly(info.armyIndex + 1, GetFocusArmy()) then
                    local bp = __blueprints[info.blueprintId]
                    local bpPhysics = bp and bp.Physics
                    if bpPhysics then
                        buildPreviewSkirtSize = MathMax(bpPhysics.SkirtSizeX or 1, bpPhysics.SkirtSizeZ or 1)
                    end
                end
            elseif orderName == "RULEUCC_Reclaim" then
                local info = GetRolloverInfo()
                if info and info.blueprintId then
                    local bp = __blueprints[info.blueprintId]
                    local bpFoot = bp and bp.Footprint
                    if bpFoot then
                        buildPreviewSkirtSize = MathMax(bpFoot.SizeX or 1, bpFoot.SizeZ or 1)
                    end
                end
            end
        end

        local bp = unit:GetBlueprint()
        local bpFoot = bp.Footprint
        local footSize = bpFoot and MathMax(bpFoot.SizeX or 1, bpFoot.SizeZ or 1) or 1
        local maxBuildDist = (bp.Economy and bp.Economy.MaxBuildDistance) or 5
        return maxBuildDist + footSize + buildPreviewSkirtSize
    end

    ---@param unit UserUnit
    ---@return number
    local function GetSimpleBuildRange(unit)
        local bp = unit:GetBlueprint()
        return ((bp.Economy and bp.Economy.MaxBuildDistance) or 5) + 2
    end

    ---@type fun(unit:UserUnit):number
    local buildRangeFunc = GetSimpleBuildRange

    options.displayActualBuildRange:Bind(function(opt, val)
        if val then
            buildRangeFunc = GetActualBuildRange
        else
            buildRangeFunc = GetSimpleBuildRange
        end
    end)

    ---@param builders UserUnit[]
    ---@return number
    local function GetMaxBuildRange(builders)
        local maxRange = 0
        for _, unit in builders do
            local r = buildRangeFunc(unit)
            if r > maxRange then
                maxRange = r
            end
        end
        return maxRange
    end

    ---@param previewKey "NONE"|"SHIFT"|"CONTROL"|"EITHER"
    ---@return boolean
    local function IsPreviewKeyDown(previewKey)
        if previewKey == "NONE" then
            return false
        end
        if previewKey == "EITHER" then
            return IsKeyDown("SHIFT") or IsKeyDown("CONTROL")
        end
        return IsKeyDown(previewKey)
    end

    ---@class Ring
    ---@field pos Vector
    ---@field color string
    ---@field radius number
    ---@field thickness number
    ---@field type string?
    local Ring = ClassSimple
    {
        __init = function(self, color, radius)
            self.pos = Vector(0, 0, 0)
            self.color = color or "ffffffff"
            self.radius = radius or 0
            self.thickness = 0.15
            self.type = nil
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
        end,
    }

    ---@class RingPool
    ---@field ringCount number # total number of rings created by the pool
    ---@field freeCount number # number of currently available free rings
    ---@field freeRings Ring[] # pool of idle/recycled Ring objects
    local RingPool = ClassSimple
    {
        ---@param self RingPool
        __init = function(self)
            self.ringCount = 0
            self.freeCount = 0
            self.freeRings = {}
        end,

        ---Allocates a ring from the pool or creates a new one if none available
        ---@param self RingPool
        ---@return Ring
        Alloc = function(self)
            if self.freeCount > 0 then
                self.freeCount = self.freeCount - 1
                return TableRemove(self.freeRings)
            end
            self.ringCount = self.ringCount + 1
            local ring = Ring()
            return ring
        end,

        ---Recycles a ring back into the pool
        ---@param self RingPool
        ---@param ring Ring
        Free = function(self, ring)
            TableInsert(self.freeRings, ring)
            self.freeCount = self.freeCount + 1
        end,

        ---Clears the pool
        ---@param self RingPool
        Clear = function(self)
            self.freeRings = {}
            self.freeCount = 0
            self.ringCount = 0
        end,
    }

    ---@param ring Ring
    ---@param overlayType string
    ---@param range number
    ---@param mousePos Vector
    local function UpdateRing(ring, overlayType, range, mousePos)
        if ring.type ~= overlayType then
            local color, thick = GetColorAndThickness(overlayType)
            ring:SetColor(color)
            ring.type = overlayType
            ring.thickness = thick
        end
        ring.radius = range
        ring:SetPosition(mousePos)
    end

    ---@class RangesWorldViewComponent : ReUI.WorldView.Component, UIShape
    ---@field _ringPool RingPool
    ---@field _hoverRings table<number, Ring>
    ---@field _selectionRings table<number, Ring>
    ---@field _buildRing Ring?
    ---@field _showRings boolean
    ---@field _cachedSelection UserUnit[]?
    ---@field _isCachedSelection boolean
    local RangesWorldViewComponent = ReUI.Core.Class(ReUI.WorldView.Component)
    {
        ---Called when component is initialized
        ---@param self RangesWorldViewComponent
        OnInit = function(self)
            self._isCachedSelection = false
            self._ringPool = RingPool()
            self._hoverRings = {}
            self._selectionRings = {}
            self._buildRing = nil
            self._showRings = true
        end,

        ---@param self RangesWorldViewComponent
        OnEnabled = function(self)
            self.worldView:AddShape(self, self.name)
        end,

        ---@param self RangesWorldViewComponent
        OnDisabled = function(self)
            self.worldView:RemoveShape(self.name)
        end,

        ---@param self RangesWorldViewComponent
        ---@param rings table<number, Ring>
        RenderRings = function(self, rings)
            if not rings then return end
            for _, ring in rings do
                ring:Render()
            end
        end,

        OnRender = true,

        ---@param self RangesWorldViewComponent
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

        ---Updates a key-based container of Ring objects to match target ring data.
        ---@param self RangesWorldViewComponent
        ---@param rings table<number, Ring> # key is range, value is Ring object
        ---@param targetData table<number, string> # key is range, value is overlayType
        ---@param mousePos Vector
        UpdateRings = function(self, rings, targetData, mousePos)
            local pool = self._ringPool

            -- 1. Update existing rings and add new rings
            for range, overlayType in targetData do
                local ring = rings[range]
                if ring then
                    UpdateRing(ring, overlayType, range, mousePos)
                else
                    ring = pool:Alloc()
                    UpdateRing(ring, overlayType, range, mousePos)
                    rings[range] = ring
                end
            end

            -- 2. Remove rings whose ranges are no longer present
            local deadRanges = nil
            for range, ring in rings do
                if not targetData[range] then
                    if not deadRanges then
                        deadRanges = {}
                    end
                    TableInsert(deadRanges, range)
                end
            end

            if deadRanges then
                for _, range in deadRanges do
                    local ring = rings[range]
                    if ring then
                        pool:Free(ring)
                        rings[range] = nil
                    end
                end
            end
        end,

        ---@param self RangesWorldViewComponent
        ClearBuildRings = function(self)
            if self._buildRing then
                if self._ringPool then
                    self._ringPool:Free(self._buildRing)
                end
                self._buildRing = nil
            end
        end,

        ---@param self RangesWorldViewComponent
        ClearSelectionRings = function(self)
            local rings = self._selectionRings
            if not rings or TableEmpty(rings) then return end

            local pool = self._ringPool
            if pool then
                for _, ring in rings do
                    pool:Free(ring)
                end
            end
            self._selectionRings = {}
        end,

        ---@param self RangesWorldViewComponent
        ClearHoverRings = function(self)
            local rings = self._hoverRings
            if not rings or TableEmpty(rings) then return end

            local pool = self._ringPool
            if pool then
                for _, ring in rings do
                    pool:Free(ring)
                end
            end
            self._hoverRings = {}
        end,

        ---@param self RangesWorldViewComponent
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
        ---@param self RangesWorldViewComponent
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

        ---@param self RangesWorldViewComponent
        UpdateReclaimRings = function(self)
            local selection = self:GetSelectedUnits()
            if not selection or TableEmpty(selection) then
                self:ClearBuildRings()
                return
            end

            local engineers = EntityCategoryFilterDown(categories.ENGINEER + categories.FACTORY, selection)
            if TableEmpty(engineers) then
                self:ClearBuildRings()
                return
            end

            local ring = self._buildRing
            if not ring then
                ring = self._ringPool:Alloc()
                self._buildRing = ring
            end

            UpdateRing(ring, "AllMilitary", 28, GetMouseWorldPos())
        end,

        ---@param self RangesWorldViewComponent
        UpdateHoverRings = function(self)
            local info = GetRolloverInfo()
            local bpId = info and info.blueprintId
            if not (info and bpId and bpId ~= "unknown") then
                self:ClearHoverRings()
                return
            end

            local ringsData
            local unit = info.userUnit
            if unit then
                ringsData = GetHoverRingsData(GetEnhancedBlueprintFromUnit(unit))
            else
                ringsData = GetHoverRingsData(GetEnhancedBlueprintFromId(bpId))
            end

            if TableEmpty(ringsData) then
                self:ClearHoverRings()
                return
            end

            self:UpdateRings(self._hoverRings, ringsData, GetMouseWorldPos())
        end,

        ---@param self RangesWorldViewComponent
        UpdateSelectionRings = function(self)
            local selection = self:GetSelectedUnits()
            if not selection or TableEmpty(selection) then
                self:ClearSelectionRings()
                return
            end

            local ringsData = GetSelectionRingsData(selection)
            if TableEmpty(ringsData) then
                self:ClearSelectionRings()
                return
            end

            self:UpdateRings(self._selectionRings, ringsData, GetMouseWorldPos())
        end,

        ---@param self RangesWorldViewComponent
        ---@param useMousePos boolean
        UpdateBuildRings = function(self, useMousePos)
            local selection = self:GetSelectedUnits()
            if not selection or TableEmpty(selection) then
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
            local ring = self._buildRing
            if not ring then
                ring = self._ringPool:Alloc()
                self._buildRing = ring
            end

            local ringPos
            if useMousePos then
                ringPos = GetMouseWorldPos()
            else
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
                ringPos = pos
            end

            UpdateRing(ring, "Miscellaneous", radius, ringPos)
        end,

        ---@param self RangesWorldViewComponent
        OnUpdateCursor = function(self)
            if not self._showRings then return end

            local commandMode = GetCommandMode()
            local orderType = commandMode[1]
            local orderName = commandMode[2] and commandMode[2].name
            local givingMoveOrder = orderType == "order" and orderName == "RULEUCC_Move"
            local notIssuingOrder = not commandMode[2]
            self._isCachedSelection = false

            if IsPreviewKeyDown(hoverPreviewKey) and notIssuingOrder then
                self:UpdateHoverRings()
            else
                self:ClearHoverRings()
            end

            if notIssuingOrder or givingMoveOrder then
                if IsPreviewKeyDown(selectedPreviewKey) then
                    self:UpdateSelectionRings()
                else
                    self:ClearSelectionRings()
                end

                if IsKeyDown(18) then -- alt
                    self:UpdateReclaimRings()
                elseif IsPreviewKeyDown(buildPreviewKey) then
                    self:UpdateBuildRings(true)
                else
                    self:ClearBuildRings()
                end
            elseif self._buildRing
                or orderType == "build"
                or (orderType == 'order'
                    and (orderName == "RULEUCC_Repair"
                        or orderName == "RULEUCC_Reclaim"
                        or orderName == "RULEUCC_Guard"))
            then
                self:ClearSelectionRings()
                self:UpdateBuildRings(false)
            else
                self:ClearSelectionRings()
            end
        end,

        ---@param self RangesWorldViewComponent
        ResetRings = function(self)
            self:ClearHoverRings()
            self:ClearSelectionRings()
            self:ClearBuildRings()
            if self._ringPool then
                self._ringPool:Clear()
            end
        end,

        ---Called when component is destroyed
        ---@param self RangesWorldViewComponent
        OnDestroy = function(self)
            self:ClearHoverRings()
            self._hoverRings = nil
            self:ClearSelectionRings()
            self._selectionRings = nil
            self:ClearBuildRings()
            self._buildRing = nil
            if self._ringPool then
                self._ringPool:Clear()
                self._ringPool = nil
            end
            self._showRings = false
            self._isCachedSelection = false
            self._cachedSelection = nil
        end,
    }

    ReUI.WorldView.PrimaryComponents.Ranges = RangesWorldViewComponent

    ---@class ReUI.Ranges
    return {
        RangesWorldViewComponent = RangesWorldViewComponent,
    }
end
