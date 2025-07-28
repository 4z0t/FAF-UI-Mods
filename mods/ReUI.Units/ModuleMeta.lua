---@meta

---@class ReUI.Units : ReUI.Module
ReUI.Units = {}

---Performs callback with no effect on selection
---@param callback fun(currentSelection:UserUnit[]?)
function ReUI.Units.HiddenSelect(callback)
end

---Applies function to selected units one by one selecting them
---@param fn fun(unit:UserUnit)
function ReUI.Units.ApplyToSelectedUnits(fn)
end

---@return table<string, UserUnit>
function ReUI.Units.Get()
end
