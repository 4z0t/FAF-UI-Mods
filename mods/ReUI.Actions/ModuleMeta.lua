---@meta

---@class ReUI.Actions : ReUI.Module
ReUI.Actions = {}

---@type CategoryMatcher | fun(name:string):CategoryMatcher
ReUI.Actions.CategoryMatcher = ...

---@type CategoryAction | fun(category?:EntityCategory):CategoryAction
ReUI.Actions.CategoryAction = ...

---@param name string
function ReUI.Actions.ProcessAction(name)
end

---Adds action that can be executed by a simple string
---@param action SimpleActionParams
function ReUI.Actions.AddSimpleAction(action)
end

---@param description string
---@param func fun(selection:UserUnit[]?)
---@param category? string
---@param name? string @optional formatted name
function ReUI.Actions.SelectionAction(description, func, category, name)
end

---Returns formatted name for the action
---@param name string
---@return string
function ReUI.Actions.FormatActionName(name)
end
