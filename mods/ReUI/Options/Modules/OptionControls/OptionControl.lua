local Group = ReUI.UI.Controls.Group

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
        self._option.OnChanged:Add { self, self.ValueChanged }
    end,

    Option = ReUI.Core.Property
    {
        ---@param self ReUI.Options.OptionControl
        get = function(self)
            return self._option
        end,
    } --[[@as ReUI.Options.ReactiveOption]] ,

    ---@param self ReUI.Options.OptionControl
    ---@param option ReUI.Options.ReactiveOption
    ---@param value any
    ValueChanged = function(self, option, value)
    end,

    ---@param self ReUI.Options.OptionControl
    Destroy = function(self)
        self._option.OnChanged:Remove { self, self.ValueChanged }
        self._option = nil
        Group.Destroy(self)
    end
}
