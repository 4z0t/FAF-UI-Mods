ReUI.Require
{
}

---@class IAction
---@field Process fun(self:IAction, selection:UserUnit[]?)

function Main()
    ---@diagnostic disable-next-line:deprecated
    local TableGetN = table.getn
    local ipairs = ipairs
    local type = type
    local iscallable = iscallable
    local EntityCategoryFilterDown = EntityCategoryFilterDown
    local GetSelectedUnits = GetSelectedUnits
    local ConExecute = ConExecute

    ---@type table<string, IAction>
    local categoryActions = {}
    local function ProcessAction(name)
        local action = categoryActions[name]
        if not action then
            WARN("Attempt to use action '" .. name .. "' which wasn't registered")
            return
        end
        action:Process(GetSelectedUnits())
    end

    ---@param name string
    ---@return string
    local function GetFormattedName(name)
        return (name:gsub("[^A-Za-z0-9]+", "_"))
    end

    ---@param name string
    ---@return string
    local function CheckFormattedName(name)
        if name == GetFormattedName(name) then
            return name
        end
        error("name must be made of only letters A-Z, a-z, 0-9 and _")
    end

    ---@class ActionModifiers
    ---@field shift boolean?
    ---@field ctrl boolean?
    ---@field alt boolean?

    ---@class SimpleActionParams
    ---@field category string
    ---@field action string
    ---@field description string
    ---@field formattedName string
    ---@field modifiers ActionModifiers?

    ---@param action SimpleActionParams
    local function AddSimpleAction(action)
        LOG("ReUI.Actions: adding '" .. action.description .. "'")
        local formattedName = CheckFormattedName(action.formattedName or GetFormattedName(action.description))

        local actionTable = {
            action = action.action,
            category = action.category,
            ReUI = true,
            shift = action.modifiers.shift,
            ctrl = action.modifiers.ctrl,
            alt = action.modifiers.alt
        }

        import("/lua/keymap/keymapper.lua").SetUserKeyAction(formattedName, actionTable)

        local keyDescriptions = import("/lua/keymap/keydescriptions.lua").keyDescriptions
        if keyDescriptions[formattedName] then
            WARN(("Overwriting key action description of '%s'"):format(formattedName))
        end
        keyDescriptions[formattedName] = action.description
    end

    ---@param name string
    ---@param matcher IAction
    ---@param category? string
    ---@param formattedName? string
    ---@param modifiers? ActionModifiers
    local function AddAction(name, matcher, category, formattedName, modifiers)
        category      = category or "ReUI.Actions"
        formattedName = formattedName or GetFormattedName(name)

        categoryActions[formattedName] = matcher

        AddSimpleAction
        {
            description = name,
            action = "UI_Lua ReUI.Actions.ProcessAction('" .. formattedName .. "')",
            category = category,
            formattedName = formattedName,
            modifiers = modifiers
        }
    end

    ---@class SelectionAction : IAction
    ---@field func fun(selection:UserUnit[]?)
    local SelectionAction = Class()
    {
        __init = function(self, description, func, category, name, modifiers)
            self.func = func
            AddAction(description, self, category, name, modifiers)
        end,

        Process = function(self, selection)
            self.func(selection)
        end
    }

    ---@class CategoryMatcher : IAction
    ---@field description string
    ---@field modifiers ActionModifiers
    ---@field _actions CategoryAction[]
    ---@operator call(Action[]):CategoryMatcher
    local CategoryMatcher = Class()
    {
        __init = function(self, description)
            self.description = description
        end,

        __call = function(self, actions)
            self._actions = actions
            self:Register()
            return self
        end,

        ---@param self CategoryMatcher
        ---@param modifiers ActionModifiers
        ---@return CategoryMatcher
        Modifiers = function(self, modifiers)
            self.modifiers = modifiers
            return self
        end,

        ---@param self CategoryMatcher
        Register = function(self)
            AddAction(self.description, self, nil, nil, self.modifiers)
        end,

        ---@param self CategoryMatcher
        ---@param selection UserUnit[]?
        Process = function(self, selection)
            for _, action in ipairs(self._actions) do
                if action:Process(selection) then
                    break
                end
            end
        end,

        ---@param self CategoryMatcher
        ---@param other CategoryMatcher
        Copy = function(self, other)
            self._actions = table.copy(other._actions)
            self:Register()
            return self
        end,
    }

    ---@alias Action string | fun(selection:UserUnit[]?)

    ---@class CategoryAction
    ---@field _actions Action[]
    ---@field _category? EntityCategory
    ---@field _matcher false|fun(selection:UserUnit[]?, category:EntityCategory?):boolean
    local CategoryAction = Class()
    {
        ---@param self CategoryAction
        ---@param category? EntityCategory
        __init = function(self, category)
            self._actions = {}
            self._category = category
            self._matcher = false
        end,

        ---Add action into list
        ---@param self CategoryAction
        ---@param action Action
        Action = function(self, action)
            table.insert(self._actions, action)
            return self
        end,

        ---Match category and selected units
        ---@param self CategoryAction
        ---@param selection UserUnit[]?
        Matches = function(self, selection)
            local category = self._category
            local matcher = self._matcher
            if matcher then
                return matcher(selection, category)
            end
            return (not category and not selection)
                or
                (category and selection and
                    TableGetN(EntityCategoryFilterDown(category, selection)) == TableGetN(selection))
        end,

        ---Set custom category matcher
        ---@param self CategoryAction
        ---@param matcher fun(selection:UserUnit[]?, category:EntityCategory?):boolean
        Match = function(self, matcher)
            self._matcher = matcher
            return self
        end,

        ---Process the action
        ---@param self CategoryAction
        ---@param selection UserUnit[]?
        ---@return boolean
        Process = function(self, selection)
            if self:Matches(selection) then
                self:Execute(selection)
                return true
            end
            return false
        end,

        ---@param self CategoryAction
        ---@param selection UserUnit[]?
        Execute = function(self, selection)
            for _, action in ipairs(self._actions) do
                if type(action) == "string" then
                    ConExecute(action)
                elseif iscallable(action) then
                    action(selection)
                else
                    error("unknown type of action")
                end
            end
        end
    }

    local Prefs = import('/lua/user/prefs.lua')
    local actions = Prefs.GetFromCurrentProfile("UserKeyActions") or {}
    for name, action in actions do
        if action.category == 'ReUI.Actions' or action.ReUI then
            actions[name] = nil
        end
    end
    Prefs.SetToCurrentProfile("UserKeyActions", actions)


    ReUI.Core.Hook("/lua/keymap/keymapper.lua", "GenerateHotbuildModifiers", function(field, module)
        return function()
            local modifiers = field()
            local keyDetails = module.GetKeyMappingDetails()
            for key, info in keyDetails do
                if info.action.shift then
                    local modKey = "Shift-" .. key
                    local bind = keyDetails[modKey]
                    if bind then
                        WARN('Hotbuild key ' ..
                            modKey ..
                            ' is already bound to action "' .. bind.name .. '" under "' .. bind.category .. '" category')
                    else
                        modifiers[modKey] = info.action
                    end
                end
                if info.action.alt then
                    local modKey = "Alt-" .. key
                    local bind = keyDetails[modKey]
                    if bind then
                        WARN('Hotbuild key ' ..
                            modKey ..
                            ' is already bound to action "' .. bind.name .. '" under "' .. bind.category .. '" category')
                    else
                        modifiers[modKey] = info.action
                    end
                end
                if info.action.ctrl then
                    local modKey = "Ctrl-" .. key
                    local bind = keyDetails[modKey]
                    if bind then
                        WARN('Hotbuild key ' ..
                            modKey ..
                            ' is already bound to action "' .. bind.name .. '" under "' .. bind.category .. '" category')
                    else
                        modifiers[modKey] = info.action
                    end
                end
            end
            return modifiers
        end
    end)

    ReUI.Core.OnPostCreateUI(function(isReplay)
        ForkThread(function()
            WaitFrames(1)
            local KeyMapper = import("/lua/keymap/keymapper.lua")
            IN_ClearKeyMap()
            IN_AddKeyMapTable(KeyMapper.GetKeyMappings())
            if SessionIsActive() then
                import("/lua/keymap/hotbuild.lua").addModifiers()
                import("/lua/keymap/hotkeylabels.lua").init()
            end
        end)
    end)

    return {
        CategoryMatcher  = CategoryMatcher,
        CategoryAction   = CategoryAction,
        SelectionAction  = SelectionAction,
        ProcessAction    = ProcessAction,
        AddSimpleAction  = AddSimpleAction,
        FormatActionName = GetFormattedName,
    }
end
