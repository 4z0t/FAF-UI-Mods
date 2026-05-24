local Group = ReUI.UI.Controls.Group
local Events = ReUI.Core.Events

---@class ReUI.Options.OptionControl : ReUI.UI.Controls.Group
---@field _option ReUI.Options.ReactiveOption
OptionControl = ReUI.Core.Class(Group)
{
    ---@param self ReUI.Options.OptionControl
    ---@param parent Control
    ---@param option ReUI.Options.ReactiveOption
    __init = function(self, parent, option)
        Group.__init(self, parent)

        self._option = option
        self._option.OnChanged:Add(Events.Bind(self, self.ValueChanged))
    end,

    ---@param self ReUI.Options.OptionControl
    ---@param option ReUI.Options.ReactiveOption
    ---@param value any
    ValueChanged = function(self, option, value)
    end,

    ---@param self ReUI.Options.OptionControl
    Destroy = function(self)
        self._option.OnChanged:Remove(Events.Bind(self, self.ValueChanged))
        self._option = nil
        Group.Destroy(self)
    end
}
