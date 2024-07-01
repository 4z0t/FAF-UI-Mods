do
    local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
    local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor
    local Dragger = import("/lua/maui/dragger.lua").Dragger
    local LineMoveModule = import("/mods/LineMove/modules/Main.lua")

    local oldWorldView = WorldView
    WorldView = Class(oldWorldView) {

        __init = function(self, ...)
            oldWorldView.__init(self, unpack(arg))
            self._mouseMonitor = LineMoveModule.MouseMonitor(self)
            LayoutFor(self._mouseMonitor)
                :Fill(self)
        end,

        -- ---@param self WorldView
        -- ---@param event KeyEvent
        -- HandleEvent = function(self, event)
        --     import("/mods/LineMove/modules/Main.lua").HandleEvent(self, event)
        --     return oldWorldView.HandleEvent(self, event)
        -- end

    }
end
