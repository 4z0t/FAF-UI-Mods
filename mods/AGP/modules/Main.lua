local next = next
local table = table
local IsDestroyed = IsDestroyed

local ActionsGridPanel = import("ActionsGridPanel.lua").ActionsGridPanel
local Prefs = import('/lua/user/prefs.lua')

local LuaQ = UMT.LuaQ

---@class ExtensionInfo
---@field name string
---@field description string
---@field class ISelectionHandler
---@field enabled boolean

---@type table<string, ExtensionInfo>
local extensions = {}
local function LoadExtensions()
    local activeExtensions = Prefs.GetFromCurrentProfile("AGP_extensions") or {}
    local l = __active_mods
        | LuaQ.where(function(v) return v.AGP and v.ui_only end)
        | LuaQ.select(function(modInfo)
            local modFolder = string.sub(modInfo.location, 7)
            local className = modInfo.AGP

            local files = DiskFindFiles("/mods/" .. modFolder .. "/", className .. '.lua')
            for _, file in files do
                local class = import(file)[className]
                LOG("AGP: added " .. modFolder .. " : " .. className)
                return { ("%s.%s"):format(modFolder, className), class }
            end
            error(("Couldn't find class '%s' in folder '%s'"):format(className, modFolder))
        end)

    for i, info in l do
        local name         = info[1]
        local handlerClass = info[2]
        local enabled      = activeExtensions[name]

        if enabled == nil then
            enabled = handlerClass.Enabled
        end
        activeExtensions[name] = enabled
        extensions[name] = {
            name = handlerClass.Name or name,
            description = handlerClass.Description or "NO DESCRIPTION",
            class = handlerClass,
            enabled = enabled,
        }
    end
    Prefs.SetToCurrentProfile("AGP_extensions", activeExtensions)
end

---@class Panel : ActionsGridPanel
---@field _selectionHandlers table<string, ISelectionHandler>
---@field _order table<string, number>
Panel = UMT.Class(ActionsGridPanel)
{
    ---@param self Panel
    LoadExtensions = function(self)
        self._selectionHandlers = {}
        self._order = {}

        local i = 0
        for name, info in pairs(extensions) do
            if info.enabled then
                self._selectionHandlers[name] = info.class(self)
                self._order[name]             = i
            end
            i = i + 1
        end
    end,

    ---@param self Panel
    OnResized = function(self)
        self:LoadExtensions()

        for name, handler in self._selectionHandlers do
            self:AddItemComponent(name, handler.ComponentClass)
        end
        self:Update()
    end,

    ---@param self Panel
    ---@param selection UserUnit[]
    GetActions = function(self, selection)
        local order = self._order
        local actions = {}

        for name, handler in pairs(self._selectionHandlers) do
            local _actions = handler:OnSelectionChanged(selection)
            if not _actions then continue end

            for i, action in _actions do
                table.insert(actions, {
                    handler = name,
                    action = action,
                    id = i,
                })
            end
        end

        table.sort(actions, function(a, b)
            local oa = order[a.handler]
            local ob = order[b.handler]
            if oa == ob then
                return a.id < b.id
            end
            return oa < ob
        end)

        return actions
    end,

    ---@param self Panel
    ---@param selection UserUnit[]
    OnSelectionChanged = function(self, selection)
        local actions = self:GetActions(selection)

        if table.empty(actions) then
            self:Hide()
            return
        end
        self:Show()

        local index, actionInfo = next(actions, nil)

        self:IterateItems(function(grid, item, row, column)
            if index == nil then item:Disable() return end
            item:EnableComponent(actionInfo.handler, actionInfo.action)

            index, actionInfo = next(actions, index)
        end)
    end,

    ---@param self Panel
    Update = function(self)
        self:OnSelectionChanged(GetSelectedUnits() or {})
    end,

    ---@param self Panel
    OnDestroy = function(self)
        ActionsGridPanel.OnDestroy(self)
        self._selectionHandlers = nil
        self._order = nil
    end,
}

---@type Panel
local panel = nil

function OnSelectionChanged(info)
    if IsDestroyed(panel) then return end

    if table.empty(info.added) and table.empty(info.removed) then return end

    panel:OnSelectionChanged(info.newSelection)
end

function Main(isReplay)

    local LayoutFor = UMT.Layouter.ReusedLayoutFor

    local GM = import("/lua/ui/game/gamemain.lua")
    GM.ObserveSelection:AddObserver(OnSelectionChanged)
    LoadExtensions()

    ForkThread(function()
        WaitSeconds(1)
        local constructionPanelControls = import("/lua/ui/game/construction.lua").controls
        local parent = import("/lua/ui/game/construction.lua").controlClusterGroup

        panel = Panel(parent)

        LayoutFor(panel)
            :AtRightBottomIn(GetFrame(0), 10, 10)
            :Hide()

        LayoutFor(constructionPanelControls.constructionGroup)
            :AnchorToLeft(panel, 20)
    end)
end

---@type Selector
local selector
local Selector = import("Selector.lua").Selector
function CreateSelector()
    if IsDestroyed(selector) then
        selector = Selector(GetFrame(0))
        ---@param self Selector
        ---@param id string
        ---@param enabled boolean
        selector.OnSelect = function(self, id, enabled)
            local activeExtensions = Prefs.GetFromCurrentProfile("AGP_extensions") or {}
            extensions[id].enabled = enabled
            activeExtensions[id] = enabled
            Prefs.SetToCurrentProfile("AGP_extensions", activeExtensions)
        end
        selector.OnClose = function(self)
            if IsDestroyed(panel) then return end
            panel:Resize()
        end
        selector:SetData(extensions)
        selector:CalcVisible()
    end
end
