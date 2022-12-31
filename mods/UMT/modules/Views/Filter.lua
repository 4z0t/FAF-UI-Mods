local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutFor = UMT.Layouter.ReusedLayoutFor

---@class Filter : Group
Filter = Class(Group)
{
    ---comment
    ---@param self Filter
    ---@param parent Control
    ---@param optionVar OptionVar
    ---@param name string
    __init = function(self, parent, optionVar, name)
        Group.__init(self, parent)
        self._option = optionVar
        self._check = UIUtil.CreateCheckbox(self, "/dialogs/check-box_btn/", name, true)

        self._check.OnCheck = function(control, checked)
            optionVar:Set(checked)
        end
        self._check:SetCheck(self._option(), true)
    end,

    __post_init = function(self, parent)
        self:_Layout(parent)
    end,

    _Layout = function(self, parent)
        LayoutFor(self._check)
            :AtCenterIn(self)
            :Over(self)
    end,

    OnDestroy = function(self)
        self._option = nil
    end

}
