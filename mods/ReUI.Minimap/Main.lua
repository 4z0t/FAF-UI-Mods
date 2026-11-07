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
    local controls
    local autoHideActive = false
    local restoreVisible = false
    local mapZoomScale = 1

    local options = ReUI.Options.Mods["ReUI.Minimap"]

    local function ShouldHideMinimap()
        if options.hideOnSplitScreen:Get() and GetCamera("WorldCamera2") then
            return true
        end

        if options.hideAtCameraDistance:Get() then
            local camera = GetCamera("WorldCamera")
            local threshold = options.cameraDistanceThreshold:Get() * mapZoomScale
            if camera and camera:GetZoom() >= threshold then
                return true
            end
        end

        return false
    end

    local function UpdateMinimapVisibility()
        if not controls or not controls.displayGroup then
            return
        end

        if ShouldHideMinimap() then
            if not autoHideActive then
                restoreVisible = not controls.displayGroup:IsHidden()
                autoHideActive = true
            end
            controls.displayGroup:Hide()
        elseif autoHideActive then
            autoHideActive = false
            controls.displayGroup:SetHidden(not restoreVisible)
        end
    end

    ReUI.Core.Hook("/lua/ui/game/minimap.lua", "CreateMinimap", function(field, module)
        return function(parent)
            field(parent)
            controls = module.controls

            local oldHandleEvent = controls.miniMap.HandleEvent

            controls.miniMap.HandleEvent = function(self, event)
                if (not self.isZoom) and (event.Type == 'WheelRotation') then
                    return true
                end
                return oldHandleEvent(self, event)
            end

            controls.miniMap.isZoom = options.allowZoom:Get()
            options.allowZoom.OnChanged:Add(function(_, value)
                controls.miniMap.isZoom = value
            end)

            local mapWidth = SessionGetScenarioInfo().size[1]
            local mapHeight = SessionGetScenarioInfo().size[2]
            local areaData = Sync.NewPlayableArea
            if areaData then
                mapWidth = areaData[3] - areaData[1]
                mapHeight = areaData[4] - areaData[2]
            end
            mapZoomScale = math.max(mapWidth, mapHeight) / 512
            if mapWidth and mapHeight then
                local displayGroup = controls.displayGroup
                local left = displayGroup.Left()
                local top = displayGroup.Top()
                local right = displayGroup.Right()
                local width = right - left
                displayGroup.Bottom:Set(mapHeight * width / mapWidth + top + 35)
            end

            import("/lua/ui/game/gamemain.lua").AddBeatFunction(UpdateMinimapVisibility, true)
        end
    end)

    ReUI.Core.Hook("/lua/ui/game/minimap.lua", "ToggleMinimap", function(field)
        return function()
            field()

            if controls and controls.displayGroup and autoHideActive then
                restoreVisible = not controls.displayGroup:IsHidden()
                controls.displayGroup:Hide()
            end
        end
    end)
end
