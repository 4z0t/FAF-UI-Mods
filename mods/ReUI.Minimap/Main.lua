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
        end
    end)
end
