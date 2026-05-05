ReUI.Require
{
    "ReUI.Core >= 1.6.0",
    "ReUI.Options >= 1.0.0",
}

function Main(isReplay)
    local SelectUnits = SelectUnits
    local IsKeyDown = IsKeyDown
    local TableEmpty = table.empty
    local ForkThread = ForkThread


    local options = ReUI.Options.Mods["ReUI.Selection"]

    local enabled = false
    options.enabled:Bind(function(var)
        enabled = var()
    end)


    local ignored = false
    local function SelectIgnored(units)
        ignored = true
        SelectUnits(nil)
        SelectUnits(units)
        ignored = false
    end

    ---Base class for selection handlers
    ---@class ReUI.Selection.Handler
    local Handler = ReUI.Core.Class()
    {
        ---Name of the handler. Must be unique
        Name = "Default",

        ---Priority of the handler - higher the value, first it goes
        Priority = 0,

        --- Returns the new selection and whether the selection has changed
        ---@param self ReUI.Selection.Handler
        ---@param selection UserUnit[]
        ---@return UserUnit[], boolean
        Handle = function(self, selection)
            return selection, false
        end,
    }

    ---Base class for unit selector
    ---@class ReUI.Selection.Selector
    ---@field _handlers ReUI.Selection.Handler[]
    local Selector = ReUI.Core.Class()
    {
        ---@param self ReUI.Selection.Selector
        __init = function(self)
            self._handlers = {}
        end,

        ---@param self ReUI.Selection.Selector
        ---@param oldSelection UserUnit[]
        ---@param newSelection UserUnit[]
        ---@param added UserUnit[]
        ---@param removed UserUnit[]
        ---@return UserUnit[]
        ---@return boolean
        Process = function(self, oldSelection, newSelection, added, removed)
            local changed, changedSel = false, false
            local selection = newSelection

            ---@param handler ReUI.Selection.Handler
            for _, handler in self:GetHandlers() do
                selection, changedSel = handler:Handle(selection)
                changed = changed or changedSel
            end

            return selection, changed
        end,

        ---@param self ReUI.Selection.Selector
        ---@param name string
        ---@return ReUI.Selection.Handler?
        Get = function(self, name)
            ---@param handler ReUI.Selection.Handler
            for i, handler in self._handlers do
                if handler.Name == name then
                    return handler
                end
            end

            return nil
        end,


        ---@param self ReUI.Selection.Selector
        ---@param handler ReUI.Selection.Handler
        Add = function(self, handler)
            if self:Get(handler.Name) then
                WARN("ReUI.Selection: Handler with name " + tostring(handler.Name) + " already exists in selector")
                return
            end
            table.insert(self._handlers, handler)
            table.sort(self._handlers, function(a, b) return a.Priority > b.Priority end)
        end,


        ---@param self ReUI.Selection.Selector
        ---@param name string
        Remove = function(self, name)
            for i, handler in self._handlers do
                if handler.Name == name then
                    table.remove(self._handlers, i)
                    return
                end
            end
        end,

        ---@param self ReUI.Selection.Selector
        ---@return ReUI.Selection.Handler[]
        GetHandlers = function(self)
            return self._handlers
        end
    }

    ---@type ReUI.Selection.Selector
    local selector

    ---Returns unit selector for `OnSelectionChanged` callback. Creates one if doesn't present
    ---@return ReUI.Selection.Selector
    local function GetSelector()
        if selector == nil then
            selector = ReUI.Selection.Selector()
        end
        return selector
    end

    ---@param oldSelection UserUnit[]
    ---@param newSelection UserUnit[]
    ---@param added UserUnit[]
    ---@param removed UserUnit[]
    local function HandleSelectionChanged(oldSelection, newSelection, added, removed)
        if not enabled or ignored or IsKeyDown("Shift") or TableEmpty(added) then
            return false
        end

        local selection, changed = nil, false
        if selector then
            selection, changed = selector:Process(oldSelection, newSelection, added, removed)
        end

        if changed then
            ForkThread(SelectIgnored, selection)
            return true
        end

        return false
    end

    ---@param OnSelectionChanged fun(oldSelection: UserUnit[], newSelection: UserUnit[], added: UserUnit[], removed: UserUnit[])
    ---@param module table
    ReUI.Core.Hook("/lua/ui/game/gamemain.lua", "OnSelectionChanged", function(OnSelectionChanged, module)
        ---@param oldSelection UserUnit[]
        ---@param newSelection UserUnit[]
        ---@param added UserUnit[]
        ---@param removed UserUnit[]
        return function(oldSelection, newSelection, added, removed)
            if module.IsIgnoredSelection() then
                return
            end

            if HandleSelectionChanged(oldSelection, newSelection, added, removed) then
                return
            end

            OnSelectionChanged(oldSelection, newSelection, added, removed)
        end
    end)

    ReUI.Core.OnPostCreateUI(function()
        if selector == nil then
            return
        end

        LOG "ReUI.Selection: Handlers:"
        ---@param handler ReUI.Selection.Handler
        for _, handler in selector:GetHandlers() do
            LOG("\t", handler.Name)
        end
    end)

    ---@class ReUI.Selection : ReUI.Module
    return {
        Selector = Selector,
        Get = GetSelector,
        Handler = Handler,
    }
end
