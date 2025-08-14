local Options = ReUI.Options.Builder
local Opt = ReUI.Options.Opt

ReUI.Options.Mods["ReUI.ActionsPanel"] = {
    rows = Opt(2),
    columns = Opt(8),
    itemSize = Opt(48),
    space = Opt(2),
}

function Main()
    local options = ReUI.Options.Mods["ReUI.ActionsPanel"]
    Options.AddOptions("ReUI.ActionsPanel", "ReUI.ActionsPanel", {
        Options.Slider("Rows", 1, 10, 1, options.rows, 4),
        Options.Slider("Columns", 1, 10, 1, options.columns, 4),
        Options.Slider("Size", 10, 64, 1, options.itemSize, 4),
        Options.Slider("Space", 0, 10, 1, options.space, 4),
    })

    Options.AddOptions("ReUI.ActionsPanel_Ext", "ReUI.ActionsPanel Extensions", function(parent)
        local panel = ReUI.UI.Global["ActionsGrid"]

        if IsDestroyed(panel) then return end

        local Prefs = import('/lua/user/prefs.lua')
        local Selector = import("Modules/Selector.lua").Selector

        local extensions = panel.Extensions

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
    end)
end
