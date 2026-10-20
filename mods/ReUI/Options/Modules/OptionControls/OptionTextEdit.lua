local UIUtil = import('/lua/ui/uiutil.lua')

local Edit = import("/lua/maui/edit.lua").Edit

local OptionControl = import("OptionControl.lua").OptionControl

---@class ReUI.Options.OptionTextEdit : ReUI.Options.OptionControl
---@field _name Text
---@field _edit Edit
OptionTextEdit = ReUI.Core.Class(OptionControl) {

    ---@param self ReUI.Options.OptionTextEdit
    __init = function(self, parent, option, name, charLimit)
        OptionControl.__init(self, parent, option)

        self._name = ReUI.UI.Controls.Text:Make(self, name, 14, UIUtil.bodyFont)

        self._edit = Edit(self)
        self._edit:SetMaxChars(charLimit or 100)

        self._edit.OnEnterPressed = function(e, text)
            option:Set(text)
            return true
        end
    end,

    ---@param self ReUI.Options.OptionTextEdit
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self)
            :Height(40)
            :Width(100)
            :Top(0)
            :Left(0)

        layouter(self._name)
            :AtLeftTopIn(self)
            :DisableHitTest()

        layouter(self._edit)
            :Below(self._name, 2)
            :Height(18)
            :AtLeftIn(self)
            :AtRightIn(self)

        self._edit:SetText(self.Option:Get() or "")
        UIUtil.SetupEditStd(self._edit, "ff00ff00", 'ff000000', "ffffffff", UIUtil.highlightColor, UIUtil.bodyFont, 16)
    end,

    ---@param self ReUI.Options.OptionTextEdit
    ---@param newValue string
    ValueChanged = function(self, option, newValue)
        if self._edit then
            self._edit:SetText(newValue)
        end
    end
}
