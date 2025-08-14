ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    -- "ReUI.UI >= 1.4.0",
    -- "ReUI.UI.Animation >= 1.0.0",
    -- "ReUI.UI.Controls >= 1.0.0",
    -- "ReUI.UI.Views >= 1.2.0",
    "ReUI.Options >= 1.0.0"
}

function Main(isReplay)
    ReUI.Core.Hook("/lua/ui/game/minimap.lua", "CreateMinimap", function(field, module)
        return function(parent)
            field(parent)
            local controls = module.controls

            local oldHandleEvent = controls.miniMap.HandleEvent

            controls.miniMap.HandleEvent = function(self, event)
                if (not self.isZoom) and (event.Type == 'WheelRotation') then
                    return true
                end
                return oldHandleEvent(self, event)
            end

            local options = ReUI.Options.Mods["ReUI.Minimap"]
            options.allowZoom:Bind(function(opt)
                controls.miniMap.isZoom = opt()
            end)

            local mapWidth = SessionGetScenarioInfo().size[1]
            local mapHeight = SessionGetScenarioInfo().size[2]
            local areaData = Sync.NewPlayableArea
            if areaData then
                mapWidth = areaData[3] - areaData[1]
                mapHeight = areaData[4] - areaData[2]
            end
            if mapWidth and mapHeight then
                local displayGroup = controls.displayGroup
                local left = displayGroup.Left()
                local top = displayGroup.Top()
                local right = displayGroup.Right()
                local width = right - left
                displayGroup.Bottom:Set(mapHeight * width / mapWidth + top + 35)
            end
        end
    end)
end
