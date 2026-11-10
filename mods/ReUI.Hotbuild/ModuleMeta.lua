---@meta


---@class ReUI.Hotbuild : ReUI.Module
ReUI.Hotbuild = {}

---Returns true if the hotbuild was processed
---@param name string
---@return boolean
function ReUI.Hotbuild.ProcessHotbuild(name)
end

---@return CycleMap
function ReUI.Hotbuild.GetCycleMap()
end

---@param name string
---@param data string[]|table[]
function ReUI.Hotbuild.AddHotbuild(name, data)
end

---Opens the Hotbuild configuration window
---@param parent? Control
---@return Quick.Window
function ReUI.Hotbuild.OpenWindow(parent)
end
