local UIUtil = import('/lua/ui/uiutil.lua')

local OptionControl = import("OptionControl.lua").OptionControl

---@class  ReUI.Options.OptionCheckbox : ReUI.Options.OptionControl
---@field _checkbox ReUI.UI.Controls.CheckBox
---@field _text ReUI.UI.Controls.Text
OptionCheckbox = ReUI.Core.Class(OptionControl)
{
    ---@param self ReUI.Options.OptionCheckbox
    ---@param parent Control
    ---@param option ReUI.Options.ReactiveOption
    ---@param label string
    __init = function(self, parent, option, label)
        OptionControl.__init(self, parent, option)

        self._text = ReUI.UI.Controls.Text.Create(self, UIUtil.bodyFont, 14)
        self._text:SetText(label)

        self._checkbox = ReUI.UI.Controls.CheckBox.Create(self, "/dialogs/check-box_btn/")
        self._checkbox:SetCheck(option:Get(), true)
        self._checkbox.OnCheck = function(control, state)
            option:Set(state)
        end
    end,

    ---@param self ReUI.Options.OptionCheckbox
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)
        self._checkbox:HandleEvent(event)
        return true
    end,

    ---@param self ReUI.Options.OptionCheckbox
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self._checkbox)
            :AtLeftTopIn(self)

        layouter(self._text)
            :RightOf(self._checkbox)
            :AtVerticalCenterIn(self._checkbox)
            :DisableHitTest()

        layouter(self)
            :Width(layouter:Sum(self._checkbox.Width, self._text.Width))
            :Height(self._checkbox.Height)
    end,

    ---@param self ReUI.Options.OptionCheckbox
    ---@param option ReUI.Options.ReactiveOption
    ---@param value any
    ValueChanged = function(self, option, value)
        self._checkbox:SetCheck(value, true)
    end,
}
