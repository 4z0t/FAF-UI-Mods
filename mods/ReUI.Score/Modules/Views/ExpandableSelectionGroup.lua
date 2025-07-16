local ExpandableGroup = import("ExpandableGroup.lua").ExpandableGroup

ExpandableSelectionGroup = ReUI.Core.Class(ExpandableGroup)
{
    AddControls = function(self, controls)
        ExpandableGroup.AddControls(self, controls)

        local function ControlEvent(control, event)
            if event.Type == 'ButtonPress' then
                if self._isExpanded then
                    self:SetActiveControl(control._id)
                    self:Contract()
                else
                    self:Expand()
                end
            end
        end

        self._active._id = 0
        self._active.HandleEvent = ControlEvent
        for i, control in self._controls do
            control._id = i
            control.HandleEvent = ControlEvent
        end
    end,

    Expand = function(self)
        table.sort(self._controls, function(a, b)
            return a._id < b._id
        end)
        ExpandableGroup.Expand(self)
    end,

    SetActiveControl = function(self, index)

        if index == self._active._id then
            return
        end

        local newActive
        for i, control in self._controls do
            if control._id == index then
                newActive = control
                index = i
                break
            end
        end

        local oldActive = self._active
        self._controls[index] = oldActive
        self._active = newActive
        local indexOffset = (index + 0.5)

        if self._isExpanded then
            self.Layouter(newActive)
                :AtCenterIn(self)

            self.Layouter(oldActive)
                :AtHorizontalCenterIn(self)
                :Top(function() return self.Top() + indexOffset * self.Height() - 0.5 * oldActive.Height() end)
        else
            newActive:Enable()
            newActive:Show()
            oldActive:Disable()
            oldActive:Hide()
        end

        return newActive, oldActive
    end

}
