local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

if ExistGlobal "UMT" and UMT.Version >= 10 then

    local function ResetCapping()
        structure = nil
        pStructure1 = nil
        pStructure2 = nil
    end

    local function OrderCapping(target, layer, id)
        SimCallback(
            { Func = 'CapStructure',
                Args = {
                    target = target,
                    layer = layer,
                    id = id
                }
            },
            true)
    end

    local capMexes = false
    local buildFabs = false
    local capRadars = false
    local capT2Arty = false
    local capPDs = false
    local capAirFac = false
    local capT3Arty = false
    local capFabs = false
    local function InitCappingOptions()

        local Options = UMT.Options
        local OptionVar = UMT.OptionVar.Create

        local modName = "CSB"
        local function CSBOptionVar(name, value)
            return OptionVar(modName, name, value)
        end

        local _options = {
            capMexes = CSBOptionVar("capMexes", false),
            buildFabs = CSBOptionVar("buildFabs", false),
            capRadars = CSBOptionVar("capRadars", false),
            capT2Arty = CSBOptionVar("capT2Arty", false),
            capPDs = CSBOptionVar("capPDs", false),
            capAirFac = CSBOptionVar("capAirFac", false),
            capT3Arty = CSBOptionVar("capT3Arty", false),
            capFabs = CSBOptionVar("capFabs", false),
        }
        _options.capMexes.OnChange = function(var) capMexes = var() end
        _options.buildFabs.OnChange = function(var) buildFabs = var() end
        _options.capRadars.OnChange = function(var) capRadars = var() end
        _options.capT2Arty.OnChange = function(var) capT2Arty = var() end
        _options.capPDs.OnChange = function(var) capPDs = var() end
        _options.capAirFac.OnChange = function(var) capAirFac = var() end
        _options.capT3Arty.OnChange = function(var) capT3Arty = var() end
        _options.capFabs.OnChange = function(var) capFabs = var() end
        capMexes = _options.capMexes()
        buildFabs = _options.buildFabs()
        capRadars = _options.capRadars()
        capT2Arty = _options.capT2Arty()
        capPDs = _options.capPDs()
        capAirFac = _options.capAirFac()
        capT3Arty = _options.capT3Arty()
        capFabs = _options.capFabs()

        Options.AddOptions(modName, "Cap Structures Better",
            {
                Options.Filter("Cap mexes with mass storages", _options.capMexes),
                Options.Filter("Build fabs around capped mexes", _options.buildFabs),
                Options.Filter("Cap radars", _options.capRadars),
                Options.Filter("Cap t2 arty", _options.capT2Arty),
                Options.Filter("Cap t1 pd", _options.capPDs),
                Options.Filter("Cap t3 air factory", _options.capAirFac),
                Options.Filter("Cap t3 arty", _options.capT3Arty),
                Options.Filter("Cap fabs with mass storages", _options.capFabs),
            })
    end

    InitCappingOptions()

    function CapStructure(command)
        -- check if we have engineers
        local units = EntityCategoryFilterDown(categories.ENGINEER, command.Units)
        if not units[1] then return end

        -- check if we have a building that we target
        local structure = GetUnitById(command.Target.EntityId)
        if not structure or IsDestroyed(structure) then return end

        -- various conditions written out for maintainability
        local isShiftDown = IsKeyDown('Shift')

        local isDoubleTapped = structure ~= nil and (pStructure1 == structure)
        local isTripleTapped = structure ~= nil and (pStructure1 == structure) and (pStructure2 == structure)

        local isUpgrading = structure:GetFocus() ~= nil

        local isTech1 = structure:IsInCategory('TECH1')
        local isTech2 = structure:IsInCategory('TECH2')
        local isTech3 = structure:IsInCategory('TECH3')
        local isTech4 = structure:IsInCategory('EXPERIMENTAL')

        -- only run logic for structures
        if structure:IsInCategory('STRUCTURE') then

            -- try and create storages and / or fabricators around it
            if structure:IsInCategory('MASSEXTRACTION') then

                -- check what type of buildings we'd like to make
                local _buildFabs =
                buildFabs and
                    (
                    (isTech2 and isUpgrading and isTripleTapped and isShiftDown) or
                        (isTech3 and isDoubleTapped and isShiftDown))

                local buildStorages =
                (
                    (isTech1 and isUpgrading and isDoubleTapped and isShiftDown)
                        or (isTech2 and isUpgrading and isDoubleTapped and isShiftDown)
                        or (isTech2 and not isUpgrading)
                        or isTech3
                    ) and not _buildFabs and capMexes

                if buildStorages then

                    -- prevent consecutive calls
                    local gametime = GetGameTimeSeconds()
                    if structure.RingStoragesStamp then
                        if structure.RingStoragesStamp + 0.75 > gametime then
                            return
                        end
                    end

                    structure.RingStoragesStamp = gametime

                    OrderCapping(command.Target.EntityId, 1, "b1106")

                    -- only clear state if we can't make fabricators
                    if (isTech1 and isUpgrading) or (isTech2 and not isUpgrading) then
                        ResetCapping()
                    end
                end

                if _buildFabs then

                    -- prevent consecutive calls
                    local gametime = GetGameTimeSeconds()
                    if structure.RingFabsStamp then
                        if structure.RingFabsStamp + 0.75 > gametime then
                            return
                        end
                    end

                    structure.RingFabsStamp = gametime
                    OrderCapping(command.Target.EntityId, 2, "b1104")

                    ResetCapping()
                end
            else

                -- prevent consecutive calls
                local gametime = GetGameTimeSeconds()
                if structure.RingStamp then
                    if structure.RingStamp + 0.75 > gametime then
                        return
                    end
                end

                structure.RingStamp = gametime

                -- if we have a t3 fabricator, create storages around it
                if structure:IsInCategory('MASSFABRICATION') and isTech3 and capFabs then
                    OrderCapping(command.Target.EntityId, 1, "b1106")

                    ResetCapping()

                    -- if we have a t2 artillery, create t1 pgens around it
                elseif structure:IsInCategory('ARTILLERY') and isTech2 and capT2Arty then
                    OrderCapping(command.Target.EntityId, 1, "b1101")

                    ResetCapping()

                    -- if we have a T3 artillery, create T3 pgens around it
                elseif structure:IsInCategory('ARTILLERY') and (isTech3 or isTech4) and capT3Arty then
                    OrderCapping(command.Target.EntityId, 1, "b1301")

                    ResetCapping()

                    -- if we have a T3 Air Factory, create T3 pgens around it
                elseif structure:IsInCategory('AIR') and structure:IsInCategory('FACTORY') and isTech3 and capAirFac then
                    OrderCapping(command.Target.EntityId, 1, "b1301")

                    ResetCapping()

                    -- if we have a radar, create t1 pgens around it
                elseif (structure:IsInCategory('RADAR')
                    and (
                    (isTech1 and isUpgrading and isDoubleTapped and isShiftDown)
                        or (isTech2 and isUpgrading and isDoubleTapped and isShiftDown)
                        or (isTech2 and not isUpgrading)
                    )
                    or structure:IsInCategory('OMNI')) and capRadars
                then
                    OrderCapping(command.Target.EntityId, 1, "b1101")

                    ResetCapping()

                elseif structure:IsInCategory('DIRECTFIRE') and isTech1 and capPDs then
                    OrderCapping(command.Target.EntityId, 1, "b5101")

                    ResetCapping()
                end
            end
        end

        -- keep track of previous structure to identify a 2nd / 3rd click
        pStructure2 = pStructure1
        pStructure1 = structure

        -- prevent building up state when upgrading but shift isn't pressed
        if isUpgrading and not isShiftDown then
            ResetCapping()
        end
    end
end
