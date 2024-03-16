local TableGetN = table.getn
local iscallable = iscallable
local EntityCategoryFilterDown = EntityCategoryFilterDown


---@type table<string, CategoryMatcher>
local categotyActions = {}
function ProcessAction(name)
    if not categotyActions[name] then
        WARN("Attempt to use action " .. name .. " which wasn't registered")
        return
    end
    categotyActions[name]:Process(GetSelectedUnits())
end

---@class CategoryMatcher
---@field description string
---@field _actions CategoryAction[]
CategoryMatcher = Class()
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
    Register = function(self)
        local name = self.description:gsub("[^A-Za-z0-9]+", "_")
        categotyActions[name] = self
        import("/lua/keymap/keymapper.lua").SetUserKeyAction(name,
            {
                action = "UI_Lua import('/mods/AKA/Main.lua').ProcessAction('" .. name .. "')",
                category = "AKA"
            })
        if import("/lua/keymap/keydescriptions.lua").keyDescriptions[name] then
            WARN(("Overwriting key action description of '%s'"):format(name))
        end
        import("/lua/keymap/keydescriptions.lua").keyDescriptions[name] = self.description
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
}

---@alias Action string | fun(selection:UserUnit[])

---@class CategoryAction
---@field _actions Action[]
---@field _category? EntityCategory
---@field _matcher false|fun(selection:UserUnit[]?, category:EntityCategory?):boolean
---@operator call(EntityCategory?): CategoryAction
CategoryAction = Class()
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
        if self._matcher then
            return self._matcher(selection, category)
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
        for _, action in self._actions do
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

local LuaQ = UMT.LuaQ

CategoryMatcher("Fancy Description")
{
    CategoryAction(), -- do nothing if no selection
    CategoryAction(categories.TRANSPORTATION)
        :Action "StartCommandMode order RULEUCC_Transport",
    CategoryAction(categories.COMMAND + categories.SUBCOMMANDER)
        :Action(import('/lua/ui/game/orders.lua').EnterOverchargeMode),
    CategoryAction()
        :Match(function(selection)
            return selection
                | LuaQ.all(function(_, unit)
                    return unit:IsInCategory 'FACTORY'
                        or unit:IsInCategory 'EXTERNALFACTORY'
                end)
        end)
        :Action(function(selection)
            local isRepeatBuild = selection
                | LuaQ.all(function(_, unit) return unit:IsRepeatQueue() end)
                and 'false'
                or 'true'
            for _, unit in selection do
                unit:ProcessInfo('SetRepeatQueue', isRepeatBuild)
                if EntityCategoryContains(categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT, unit) then
                    unit:GetCreator():ProcessInfo('SetRepeatQueue', isRepeatBuild)
                end
            end
        end)
}



function Main()
    local CM = import("/lua/ui/game/commandmode.lua")

    local attackMoveModeData = {
        name = "RULEUCC_Script",
        AbilityName = 'AttackMove',
        TaskName = 'AttackMove',
        Cursor = 'ATTACK_MOVE',
    }

    CategoryMatcher "Launch missle / attack-reclaim / attack order"
    {
        CategoryAction(categories.SILO * categories.STRUCTURE * categories.TECH3)
            :Action 'StartCommandMode order RULEUCC_Nuke',
        CategoryAction(categories.SILO * categories.STRUCTURE * categories.TECH2)
            :Action 'StartCommandMode order RULEUCC_Tactical',
        CategoryAction(categories.ENGINEER * (categories.TECH1 + categories.TECH2 + categories.TECH3)
            + categories.FACTORY * categories.STRUCTURE - categories.SUBCOMMANDER)
            :Action(function(selection)
                CM.StartCommandMode("order", attackMoveModeData)
            end),
        CategoryAction()
            :Match(function(selection, category)
                return true
            end)
            :Action 'StartCommandMode order RULEUCC_Attack',
    }
end
