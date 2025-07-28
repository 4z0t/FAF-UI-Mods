do
    local GetCommandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode
    local ShowReclaim = import("/lua/ui/game/Reclaim.lua").ShowReclaim
    local oldWorldView = WorldView
    WorldView = Class(oldWorldView) {

        EnabledWithReclaimMode = false,

        OnUpdateCursor = function(self)
            local order = GetCommandMode()[2] and GetCommandMode()[2].name
            if order == "RULEUCC_Reclaim" then
                if not self.ReclaimThread then
                    ShowReclaim(true)
                else
                    self.ShowingReclaim = true
                end
                self.EnabledWithReclaimMode = true
            elseif order ~= "RULEUCC_Move" and self.EnabledWithReclaimMode then
                if not self.ReclaimThread then
                    ShowReclaim(false)
                else
                    self.ShowingReclaim = false
                end
                self.EnabledWithReclaimMode = false
            end
            return oldWorldView.OnUpdateCursor(self)
        end
    }
end
