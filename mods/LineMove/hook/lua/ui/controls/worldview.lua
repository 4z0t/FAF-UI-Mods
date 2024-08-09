do
    local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
    local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor
    local Dragger = import("/lua/maui/dragger.lua").Dragger
    local LineMoveModule = import("/mods/LineMove/modules/Main.lua")

    local oldWorldView = WorldView
    ---@class WorldView : WorldView
    ---@field _mouseMonitor MouseMonitor
    WorldView = Class(oldWorldView) {

        __init = function(self, ...)
            oldWorldView.__init(self, unpack(arg))
            self._mouseMonitor = LineMoveModule.MouseMonitor(self)
            LayoutFor(self._mouseMonitor)
                :Fill(self)
                :DisableHitTest()
        end,

        ---@param self WorldView
        ---@param event KeyEvent
        HandleEvent = function(self, event)
            if self._mouseMonitor:IsStartEvent(event) then
                self._mouseMonitor:StartLineMove()
            end
            return oldWorldView.HandleEvent(self, event)
        end

        -- ---@param self WorldView
        -- ---@param event KeyEvent
        -- HandleEvent = function(self, event)
        --     import("/mods/LineMove/modules/Main.lua").HandleEvent(self, event)
        --     return oldWorldView.HandleEvent(self, event)
        -- end

    }
end
