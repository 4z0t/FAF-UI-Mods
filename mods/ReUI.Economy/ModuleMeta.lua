---@meta


---@class ReUI.Economy : ReUI.Module
ReUI.Economy = {}

---@type table<string, (fun(control: ReUI.UI.Layoutable, layouter:ReUI.UI.Layouter) : fun(control: ReUI.UI.Layoutable)?)>
ReUI.Economy.Layouts = {}

ReUI.Economy.Layouts["default"] = ...

---@class EconomyPanel
ReUI.Economy.EconomyPanel = ...
