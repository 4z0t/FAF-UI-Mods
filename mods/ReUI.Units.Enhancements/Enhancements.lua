ReUI.Require
{
    "ReUI.Core >= 1.2.0",
    "ReUI.Units >= 1.0.0",
    "ReUI.LINQ >= 1.3.0",
}


function Main(isReplay)
    local TableInsert = table.insert
    local TableEmpty = table.empty
    local TableGetN = table.getn

    local Enumerate = ReUI.LINQ.Enumerate
    local IPairsEnumerator = ReUI.LINQ.IPairsEnumerator

    local ContainsPrerequisite = IPairsEnumerator
        :Select "ID"
        :Contains()

    local Reverse = IPairsEnumerator:Reverse():ToArray()

    local EnhanceCommon = import("/lua/enhancementcommon.lua")
    local EnhancementQueueFile = import("/lua/ui/notify/enhancementqueue.lua")


    ---@param unit UserUnit
    local function HasOrderedUpgrades(unit)
        if not unit:IsIdle() then
            local cmdqueue = unit:GetCommandQueue()
            local enhancementQueue = EnhancementQueueFile.getEnhancementQueue()[unit:GetEntityId()]
            if cmdqueue and cmdqueue[1] and cmdqueue[1].type == 'Script'
                and enhancementQueue[1]
                and not string.find(enhancementQueue[1].ID, "Remove", 1, true) then
                return true
            end
        end
        return false
    end

    local processed = ReUI.Core.Weak.Key {}
    ---@param bp UnitBlueprint
    ---@return table<Enhancement, UnitBlueprintEnhancement>?
    local function GetBluePrintEnhancements(bp)
        if not bp.Enhancements then
            return
        end

        if processed[bp.BlueprintId] then
            return bp.Enhancements
        end
        processed[bp.BlueprintId] = true

        ---@param name string
        ---@param tbl UnitBlueprintEnhancement
        for name, tbl in bp.Enhancements do
            if name ~= "Slots" then
                tbl.ID = name
                tbl.UnitID = bp.BlueprintId
            end
        end

        return bp.Enhancements
    end

    ---@alias Upgrade string

    ---@param unit UserUnit
    ---@return Upgrade[]
    local function GetAllInstalledEnhancements(unit)

        local id = unit:GetEntityId()

        local bpEnhancements = GetBluePrintEnhancements(unit:GetBlueprint()) or {}
        local existingEnhancements = EnhanceCommon.GetEnhancements(id) or {}

        local enhancements = {}

        ---@param enh string
        for _, enh in existingEnhancements do
            local prerequisite = enh
            repeat
                TableInsert(enhancements, prerequisite)
                prerequisite = bpEnhancements[prerequisite].Prerequisite
            until not prerequisite
        end

        return enhancements
    end

    ---@param bp UnitBlueprint
    ---@param enhancement Upgrade
    ---@param possiblePrerequisite Upgrade
    ---@return boolean
    local function IsPrerequisite(bp, enhancement, possiblePrerequisite)
        local bpEnhancements = GetBluePrintEnhancements(bp)
        if not bpEnhancements then
            return false
        end

        local prerequisite = enhancement
        repeat
            if possiblePrerequisite == prerequisite then
                return true
            end
            prerequisite = bpEnhancements[prerequisite].Prerequisite
        until not prerequisite
        return false
    end

    ---@param unit UserUnit
    ---@param upgrade Upgrade
    ---@return boolean
    local function IsInstalled(unit, upgrade)

        local bp = unit:GetBlueprint()
        local bpEnhancements = GetBluePrintEnhancements(bp)
        if not bpEnhancements then
            return false
        end

        local existingEnhancements = EnhanceCommon.GetEnhancements(unit:GetEntityId())
        if not existingEnhancements then
            return false
        end

        local slot = bpEnhancements[upgrade].Slot
        local installedEnh = existingEnhancements[slot]

        if not installedEnh then
            return false
        end

        return IsPrerequisite(bp, installedEnh, upgrade)
    end

    ---@param unit UserUnit
    ---@param enhancement Upgrade
    ---@return boolean
    local function IsQueued(unit, enhancement)
        local id = unit:GetEntityId()
        local orderedEnhancements = EnhancementQueueFile.getEnhancementQueue()[id]
        return orderedEnhancements and ContainsPrerequisite(orderedEnhancements, enhancement)
    end

    ---@param unit UserUnit
    ---@param prerequisite Upgrade
    local function HasPrerequisite(unit, prerequisite)
        return IsInstalled(unit, prerequisite) or IsQueued(unit, prerequisite)
    end

    ---@param unit UserUnit
    ---@param enhancement Upgrade
    ---@return string|false
    local function IsOccupiedSlotFor(unit, enhancement)
        local bp = unit:GetBlueprint()
        local bpEnhancements = GetBluePrintEnhancements(bp)
        if not bpEnhancements then return false end

        if not bpEnhancements[enhancement] then
            return false
        end

        local id = unit:GetEntityId()
        local existingEnhancements = EnhanceCommon.GetEnhancements(id)
        if TableEmpty(existingEnhancements) then
            return false
        end
        ---@cast existingEnhancements -nil


        local slot = bpEnhancements[enhancement].Slot
        local installedEnh = existingEnhancements[slot]
        if not installedEnh then
            return false
        end

        if IsInstalled(unit, enhancement) or IsPrerequisite(bp, enhancement, installedEnh) then
            return false
        end

        return bpEnhancements[installedEnh].Name --[[@as string]]
    end

    ---@param unit UserUnit
    ---@param enhancement Upgrade
    ---@param noClear? boolean
    local function OrderUnitEnhancement(unit, enhancement, noClear)

        local bpEnhancements = GetBluePrintEnhancements(unit:GetBlueprint())
        if not bpEnhancements then return end

        if not bpEnhancements[enhancement] then return end

        if IsInstalled(unit, enhancement) then return end

        local id = unit:GetEntityId()

        local orders = {}
        TableInsert(orders, enhancement)

        local prerequisite = bpEnhancements[enhancement].Prerequisite
        while prerequisite do
            if HasPrerequisite(unit, prerequisite) then
                break
            end
            TableInsert(orders, prerequisite)
            prerequisite = bpEnhancements[prerequisite].Prerequisite
        end

        local existingEnhancements = EnhanceCommon.GetEnhancements(id)
        if not TableEmpty(existingEnhancements) then
            ---@cast existingEnhancements -nil

            local slot = bpEnhancements[enhancement].Slot
            local installedEnh = existingEnhancements[slot]
            if installedEnh and not IsPrerequisite(unit:GetBlueprint(), enhancement, installedEnh) then
                TableInsert(orders, installedEnh .. "Remove")
            end
        end

        local cleanOrder = not HasOrderedUpgrades(unit) and not noClear

        if cleanOrder then
            EnhancementQueueFile.getEnhancementQueue()[id] = nil
        end

        for i = TableGetN(orders), 1, -1 do
            local order = orders[i]
            IssueCommand("UNITCOMMAND_Script",
                {
                    TaskName = 'EnhanceTask',
                    Enhancement = order
                },
                cleanOrder)
            cleanOrder = false
        end
    end

    ---@param enhancement string
    ---@param noClearOrders? boolean
    local function OrderEnhancement(enhancement, noClearOrders)
        ReUI.Units.ApplyToSelectedUnits(function(unit)
            OrderUnitEnhancement(unit, enhancement, noClearOrders)
        end)
    end

    ---@alias UpgradeChain Upgrade[]


    ---@type table<string, UpgradeChain[]>
    local resolved = {}


    ---@param bp UnitBlueprint
    ---@return UpgradeChain[]?
    local function ResolveUpgradeChains(bp)
        local enhancements = bp.Enhancements
        if not enhancements then
            return
        end
        local id = bp.BlueprintId
        local resolvedChains = resolved[id]

        if resolvedChains then
            return resolvedChains
        end

        local chains = {}
        local visited = {}

        local function DFS(currentUpgrade, currentChain)
            table.insert(currentChain, currentUpgrade)

            local prereq = enhancements[currentUpgrade].Prerequisite
            if not prereq then
                local chainCopy = Reverse(currentChain)
                local l2 = TableGetN(chainCopy)

                local foundEqual = false

                for j, chain in chains do
                    foundEqual = true
                    local l1 = TableGetN(chain)
                    for i = 1, math.min(l1, l2) do
                        if chain[i] ~= chainCopy[i] then
                            foundEqual = false
                            break
                        end
                    end
                    if foundEqual then
                        if l2 > l1 then
                            chains[j] = chainCopy
                        end
                        break
                    end
                end
                if not foundEqual then
                    table.insert(chains, chainCopy)
                end
            elseif not visited[prereq] then
                visited[prereq] = true
                DFS(prereq, currentChain)
                visited[prereq] = nil
            end

            table.remove(currentChain)
        end

        for upgrade in enhancements do
            if not StringEnds(upgrade, "Remove") and upgrade ~= "Slots" then
                visited = {}
                DFS(upgrade, {})
            end
        end

        resolved[id] = chains

        table.sort(chains, function(a, b)
            local enh1, enh2 = enhancements[ a[1] ], enhancements[ b[1] ]

            return (enh1.BuildCostMass or 0) < (enh2.BuildCostMass or 0)
        end)

        return chains
    end

    return {
        GetAllInstalledEnhancements = GetAllInstalledEnhancements,
        IsInstalled = IsInstalled,
        IsOccupiedSlotFor = IsOccupiedSlotFor,
        IsQueued = IsQueued,
        OrderUnitEnhancement = OrderUnitEnhancement,
        HasPrerequisite = HasPrerequisite,
        OrderEnhancement = OrderEnhancement,
        ResolveUpgradeChains = ResolveUpgradeChains,
    }
end
