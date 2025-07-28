---@meta


---@class ReUI.Units.Enhancements : ReUI.Module
ReUI.Units.Enhancements = {}

---Returns all installed enhancements of given unit
---@param unit UserUnit
---@return Upgrade[]
function ReUI.Units.Enhancements.GetAllInstalledEnhancements(unit)
end

---Returns whether upgrade is installed on given unit
---@param unit UserUnit
---@param upgrade Upgrade
---@return boolean
function ReUI.Units.Enhancements.IsInstalled(unit, upgrade)
end

---Returns whether slot is occupied for given upgrade, if it is then returns the one occupied
---@param unit UserUnit
---@param upgrade Upgrade
---@return string|false
function ReUI.Units.Enhancements.IsOccupiedSlotFor(unit, upgrade)
end

---Orders to given unit to upgrade. if `noClear` is false, then cancels current order
---@param unit UserUnit
---@param enhancement Upgrade
---@param noClear? boolean
function ReUI.Units.Enhancements.OrderUnitEnhancement(unit, enhancement, noClear)
end

---Returns whether unit has prerequisite installed or has queued it.
---@param unit UserUnit
---@param prerequisite Upgrade
function ReUI.Units.Enhancements.HasPrerequisite(unit, prerequisite)
end

---@param unit UserUnit
---@param enhancement Upgrade
---@return boolean
function ReUI.Units.Enhancements.IsQueued(unit, enhancement)
end

---Orders selected units to upgrade
---@param enhancement string
---@param noClearOrders? boolean
function ReUI.Units.Enhancements.OrderEnhancement(enhancement, noClearOrders)
end

---@param bp UnitBlueprint
---@return UpgradeChain[]?
function ReUI.Units.Enhancements.ResolveUpgradeChains(bp)
end
