local Dragger = import('/lua/maui/dragger.lua').Dragger
local Prefs = import('/lua/user/prefs.lua')
local Window = import('/lua/maui/window.lua').Window
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Edit = import('/lua/maui/edit.lua').Edit
local Text = import('/lua/maui/text.lua').Text
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup

CWAdd = Class(Group) {

    __init = function(self, parent, cWheel)
        Group.__init(self, parent)
        LayoutHelpers.SetDimensions(self, 400, 120)
        LayoutHelpers.AtCenterIn(self, parent)

        self._dialog = Popup(GetFrame(0), self)
        self._cw = cWheel
        self._title = UIUtil.CreateText(self, "Adding new phrase", 14, UIUtil.titleFont)
        LayoutHelpers.AtTopIn(self._title, self, 5)
        LayoutHelpers.AtHorizontalCenterIn(self._title, self)

        self._edit = Edit(self)

        LayoutHelpers.SetHeight(self._edit, 28)
        LayoutHelpers.Below(self._edit, self._title, 15)
        LayoutHelpers.AtRightIn(self._edit, self, 10)
        LayoutHelpers.AtLeftIn(self._edit, self, 10)
        UIUtil.SetupEditStd(self._edit, "ff00ff00", 'ff000000', "ffffffff", UIUtil.highlightColor, UIUtil.bodyFont, 26,
            200)
        self._edit:SetDropShadow(true)
        self._edit:ShowBackground(true)
        self._edit:SetText('')

        self._cb = UIUtil.CreateCheckbox(self, '/CHECKBOX/', "send message to all", true, 11)
        LayoutHelpers.AtBottomIn(self._cb, self, 15)
        LayoutHelpers.AtLeftIn(self._cb, self, 5)
        self._cb:SetCheck(true, false)

        self._okBtn = UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "<LOC _Ok>")
        LayoutHelpers.AtHorizontalCenterIn(self._okBtn, self)
        LayoutHelpers.AtBottomIn(self._okBtn, self, 5)

        self._okBtn.OnClick = function(control, modifiers)
            -- sending data
            if self:SetData() then
                self._dialog:Close()
                self._cw:AcquireKeyboardFocus(false)
                self:Destroy()
            end
        end
        self._edit.OnEnterPressed = function(control, text)
            self._okBtn:OnClick()
        end
        self._edit:AcquireKeyboardFocus(false)
    end,
    SetData = function(self)
        local text = self._edit:GetText()
        if string.len(text) ~= 0 then
            self._cw:AddData({
                text = text,
                all = self._cb:IsChecked()
            })
            return true
        end
        return false
    end

}
