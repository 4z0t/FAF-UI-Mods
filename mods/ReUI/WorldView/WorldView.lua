ReUI.Require
{
    "ReUI.Core >= 1.2.0",
    "ReUI.ECS >= 1.0.0",
}

function Main(isReplay)

    ---@param WorldView WorldView
    ReUI.Core.Hook("/lua/ui/controls/worldview.lua", "WorldView", function(WorldView, module)
        local WorldView__post_init = WorldView.__post_init
        local WorldViewHandleEvent = WorldView.HandleEvent
        local WorldViewOnFrame = WorldView.OnFrame
        local WorldViewOnUpdateCursor = WorldView.OnUpdateCursor
        local WorldViewOnDestroy = WorldView.OnDestroy

        ---@class ReUI.WorldView.WorldView : WorldView, ComponentContainer
        ---@field _camera Camera
        local ReUIWorldView = Class(WorldView, ReUI.ECS.ComponentContainer)
        {
            ---@param self ReUI.WorldView.WorldView
            ---@param parentControl Control
            ---@param cameraName string
            ---@param depth number
            ---@param isMiniMap boolean
            ---@param trackCamera boolean
            __post_init = function(self, parentControl, cameraName, depth, isMiniMap, trackCamera)
                WorldView__post_init(self, parentControl, cameraName, depth, isMiniMap, trackCamera)

                local componentClasses = isMiniMap
                    and ReUI.WorldView.MinimapComponents
                    or ReUI.WorldView.PrimaryComponents

                ---@param name string
                ---@param componentClass fun(worldView: WorldView, name: string): ReUI.WorldView.Component
                for name, componentClass in componentClasses do
                    self:AddComponent(name, componentClass(self, name))
                end

                ---@param component ReUI.WorldView.Component
                for _, component in self:IterateComponents() do
                    component:Init()
                end

                if not isMiniMap then
                    self:SetNeedsFrameUpdate(true)
                end
            end,

            ---@param self ReUI.WorldView.WorldView
            ---@param event KeyEvent
            ---@return boolean
            HandleEvent = function(self, event)
                local result = false
                ---@param component ReUI.WorldView.Component
                for _, component in self:IterateEnabledComponents() do
                    result = component:OnHandleEvent(event) or result
                end
                return WorldViewHandleEvent(self, event) or result
            end,

            ---@param self ReUI.WorldView.WorldView
            ---@param delta number
            OnFrame = function(self, delta)
                ---@param component ReUI.WorldView.Component
                for _, component in self:IterateEnabledComponents() do
                    component:OnFrame(delta)
                end
                return WorldViewOnFrame(self, delta)
            end,

            ---@param self ReUI.WorldView.WorldView
            OnUpdateCursor = function(self)
                ---@param component ReUI.WorldView.Component
                for _, component in self:IterateEnabledComponents() do
                    component:OnUpdateCursor()
                end
                return WorldViewOnUpdateCursor(self)
            end,

            ---@param self ReUI.WorldView.WorldView
            OnDestroy = function(self)
                self:DestroyComponents()
                return WorldViewOnDestroy(self)
            end,

            ---@param self ReUI.WorldView.WorldView
            ---@return Camera
            GetCamera = function(self)
                local camera = self._camera
                if not camera then
                    camera = GetCamera(self._cameraName)
                    self._camera = camera
                end
                return camera
            end,
        }
        return ReUIWorldView
    end)


    local Component = import("Modules/WorldViewComponent.lua").Component

    return {
        Component = Component,
        PrimaryComponents = {},
        MinimapComponents = {},
    }
end
