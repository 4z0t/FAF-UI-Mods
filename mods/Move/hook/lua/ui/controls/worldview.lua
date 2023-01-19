do
    local oldWorldView = WorldView
    local MoveOnly = import "/mods/Move/modules/Main.lua"
    WorldView = Class(oldWorldView) {

        ---comment
        ---@param self WorldView
        ---@param event KeyEvent
        HandleEvent = function(self, event)
            if event.Modifiers.Right and MoveOnly.IsLocked() then
                MoveOnly.Toggle(true)
            end
            oldWorldView.HandleEvent(self, event)
        end

    }
end
