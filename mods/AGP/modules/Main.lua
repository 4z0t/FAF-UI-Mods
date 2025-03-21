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
    local l = {}
    for _, modInfo in __active_mods do
        if not (modInfo.AGP and modInfo.ui_only) then
            continue
        end

        local modFolder = string.sub(modInfo.location, 7)

        local classes = modInfo.AGP
        if type(classes) == "table" then
        elseif type(classes) == "string" then
            classes = { classes }
        else
            WARN("Unsupported type of AGP extension of mod " .. modFolder)
            return
        end

        for _, className in classes do
            local files = DiskFindFiles("/mods/" .. modFolder .. "/", className .. '.lua')
            if table.empty(files) then
                WARN(("Couldn't find class '%s' in folder '%s'"):format(className, modFolder))
                continue
            end
            for _, file in files do
                local class = import(file)[className]
                LOG("AGP: added " .. modFolder .. " : " .. className)
                table.insert(l, { ("%s.%s"):format(modFolder, className), class })
            end
        end
    end


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
---@field _border GlowBorder
---@field _selectionHandlers table<string, ISelectionHandler>
---@field _order table<string, number>
---@field _componentClasses table<string, fun(item:Item):IItemComponent>
Panel = UMT.Class(ActionsGridPanel)
{

    ---@param self Panel
    __init = function(self, parent)
        ActionsGridPanel.__init(self, parent)
        self._border = UMT.Views.WindowFrame(self)
    end,

    ---@param self Panel
    ---@param layouter UMT.Layouter
    InitLayout = function(self, layouter)
        ActionsGridPanel.InitLayout(self, layouter)
        layouter(self._border)
            :FillFixedBorder(self, -5)
            :Under(self)
            :DisableHitTest(true)
    end,

    ---@param self Panel
    LoadExtensions = function(self)
        self._selectionHandlers = {}
        self._order = {}
        self._componentClasses = {}

        local i = 0
        for name, info in pairs(extensions) do
            if info.enabled then
                local handler                 = info.class(self)
                self._selectionHandlers[name] = handler
                self._order[name]             = i
                self._componentClasses[name]  = handler.ComponentClass
            end
            i = i + 1
        end
    end,

    ---@param self Panel
    OnResized = function(self)
        self:LoadExtensions()
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

    ---@generic T
    ---@param self Panel
    ---@return table<string,T>
    GetExtensionComponentClasses = function(self)
        return self._componentClasses
    end,

    ItemClass = import("Item.lua").Item
}

---@type Panel
local panel = nil

function OnSelectionChanged(info)
    if IsDestroyed(panel) then return end

    panel:OnSelectionChanged(info.newSelection)
end

function CreatePanel()
    local LayoutFor = UMT.Layouter.ReusedLayoutFor
    local parent = import("/lua/ui/game/construction.lua").controlClusterGroup
    panel = Panel(parent)
    LayoutFor(panel)
        :AtRightBottomIn(GetFrame(0), 10, 10)
        :Hide()
end

function SetLayout()
    ForkThread(function()
        WaitSeconds(0.5)
        if IsDestroyed(panel) then return end

        local LayoutFor = UMT.Layouter.ReusedLayoutFor
        local constructionPanelControls = import("/lua/ui/game/construction.lua").controls

        LayoutFor(constructionPanelControls.constructionGroup)
            :AnchorToLeft(panel, 20)
    end)
end

function Main(isReplay)
    local GM = import("/lua/ui/game/gamemain.lua")
    GM.ObserveSelection:AddObserver(OnSelectionChanged)
    LoadExtensions()
    CreatePanel()
end

function CreateSelector(parent)
    local Selector = import("Selector.lua").Selector
    ---@type Selector
    local selector = Selector(parent)
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
    return selector
end
