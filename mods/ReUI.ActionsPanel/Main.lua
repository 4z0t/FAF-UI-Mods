ReUI.Require
{
    'ReUI.Core >= 1.1.0',
    "ReUI.UI.Views.Grid >= 1.0.0",
    "ReUI.Options >= 1.0.0",
}

function Main(isReplay)
    local Prefs = import('/lua/user/prefs.lua')

    ---@class ExtensionInfo
    ---@field name string
    ---@field description string
    ---@field class ASelectionHandler
    ---@field enabled boolean

    local extensions = {}
    ---@param name string
    ---@param handlerClass ASelectionHandler
    local function AddExtension(name, handlerClass)
        name = name .. ":" .. handlerClass.Name
        extensions[name] = {
            name = name,
            description = handlerClass.Description or "NO DESCRIPTION",
            class = handlerClass,
            enabled = handlerClass.Enabled,
        }
        LOG("ReUI.ActionsPanel: added extension '" .. name .. "'")
    end

    local function SetLayout()
        local panel = ReUI.UI.Global["ActionsGrid"]
        if IsDestroyed(panel) then return end

        local LayoutFor = ReUI.UI.FloorLayoutFor
        local constructionPanelControls = import("/lua/ui/game/construction.lua").controls

        LayoutFor(constructionPanelControls.constructionGroup)
            :AnchorToLeft(panel, 25)
    end

    ReUI.Core.Hook("/lua/ui/game/layouts/orders_left.lua", "SetLayout", function(field, module)
        return function()
            field()
            SetLayout()
        end
    end)
    ReUI.Core.Hook("/lua/ui/game/layouts/orders_mini.lua", "SetLayout", function(field, module)
        return function()
            field()
            SetLayout()
        end
    end)
    ReUI.Core.Hook("/lua/ui/game/layouts/orders_right.lua", "SetLayout", function(field, module)
        return function()
            field()
            SetLayout()
        end
    end)

    ReUI.Core.OnPostCreateUI(function(isReplay)
        local activeExtensions = Prefs.GetFromCurrentProfile("ReUIActionsPanel_extensions") or {}

        for name, info in extensions do
            if activeExtensions[name] == nil then
                activeExtensions[name] = info.enabled
            end
            info.enabled = activeExtensions[name]
        end

        Prefs.SetToCurrentProfile("ReUIActionsPanel_extensions", activeExtensions)

        local IsDestroyed = IsDestroyed

        local LayoutFor = ReUI.UI.FloorLayoutFor
        local ActionsGrid = ReUI.ActionsPanel.ActionsGrid

        local parent = import("/lua/ui/game/construction.lua").controlClusterGroup

        local options = ReUI.Options.Mods["ReUI.ActionsPanel"]

        ---@type ActionsGrid
        local panel = ActionsGrid(parent)
        panel:LoadExtensions(extensions)
        panel.ColumnWidth       = options.itemSize:Raw()
        panel.RowHeight         = options.itemSize:Raw()
        panel.Rows              = options.rows:Raw()
        panel.Columns           = options.columns:Raw()
        panel.VerticalSpacing   = options.space:Raw()
        panel.HorizontalSpacing = options.space:Raw()

        LayoutFor(panel)
            :AtRightBottomIn(GetFrame(0)--[[@as Frame]] , 14, 14)
            :Hide()

        local function OnSelectionChanged(info)
            if IsDestroyed(panel) then
                return
            end

            panel:OnSelectionChanged(info.newSelection)
        end

        import("/lua/ui/game/gamemain.lua").ObserveSelection:AddObserver(OnSelectionChanged)


        ReUI.UI.Global["ActionsGrid"] = panel
    end)

    local ActionsGrid = import("Modules/ActionsGrid.lua").ActionsGrid

    return {
        ActionsGrid = ActionsGrid,
        AddExtension = AddExtension,
    }
end
