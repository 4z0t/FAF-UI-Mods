ReUI.Require
{
    'ReUI.Core >= 1.1.0',
    "ReUI.UI.Views.Grid >= 1.0.0"
}

function Main(isReplay)
    local Prefs = import('/lua/user/prefs.lua')


    ---@class ExtensionInfo
    ---@field name string
    ---@field description string
    ---@field class ASelectionHandler
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
                WARN("Unsupported type of ReUI.ActionsPanel extension of mod " .. modFolder)
                continue
            end

            for _, className in classes do
                local files = DiskFindFiles("/mods/" .. modFolder .. "/"--[[@as FileName]] , className .. '.lua')
                if table.empty(files) then
                    WARN(("Couldn't find class '%s' in folder '%s'"):format(className, modFolder))
                    continue
                end
                for _, file in files do
                    local ok, module = pcall(import, file)
                    if not ok then
                        WARN(module)
                        continue
                    end
                    local class = module[className]
                    LOG("ReUI.ActionsPanel: added " .. modFolder .. " : " .. className)
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

    LoadExtensions()


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
        ActionsGrid = ActionsGrid
    }
end
