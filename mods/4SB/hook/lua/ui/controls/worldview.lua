local oldWorldView = WorldView
WorldView = Class(oldWorldView) {
    HandleEvent = function(self, event)
        if event.Modifiers.Shift then
            -- 
        end
        return oldWorldView.HandleEvent(self, event)
    end
}
