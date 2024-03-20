do
    local CommandMode = import('/lua/ui/game/commandmode.lua')
    local prefixes = {
        ["AEON"] = { "uab", "xab", "dab", "zab" },
        ["UEF"] = { "ueb", "xeb", "deb", "zeb" },
        ["CYBRAN"] = { "urb", "xrb", "drb", "zrb" },
        ["SERAPHIM"] = { "xsb", "usb", "dsb", "zsb" }
    }

    local function CopyBuilding()
        local info = GetRolloverInfo()
        if info and info.blueprintId ~= 'unknown' then
            local selection = GetSelectedUnits()
            if not selection then
                return false
            end
            local bp = info.blueprintId
            local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(selection)

            local buildable = EntityCategoryGetUnitList(buildableCategories)

            if table.empty(buildable) then
                return false
            end

            local currentFaction = string.upper(selection[1]:GetBlueprint().General.FactionName)
            for i, prefix in prefixes[currentFaction] do
                local nbp = string.gsub(bp, "(%a+)(%d+)", prefix .. "%2")
                if table.find(buildable, nbp) then
                    ClearBuildTemplates()
                    CommandMode.StartCommandMode("build", {
                        name = nbp
                    })
                    return true
                end
            end
        end
        return false
    end

    local _WorldViewHandleEvent = WorldView.HandleEvent
    WorldView = Class(WorldView) {
        ReturnHitTest = false,
        ---@param self WorldView
        ---@param event KeyEvent
        HandleEvent = function(self, event)
            if self.ReturnHitTest then
                self:EnableHitTest()
            end
            if event.Type == "ButtonPress" and event.Modifiers.Ctrl and event.Modifiers.Right then
                if CopyBuilding() then
                    self.ReturnHitTest = true
                    self:DisableHitTest()
                end
            end
            return _WorldViewHandleEvent(self, event)
        end
    }
end
