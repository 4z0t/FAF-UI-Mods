local Dragger = import('/lua/maui/dragger.lua').Dragger
local Prefs = import('/lua/user/prefs.lua')
local Window = import('/lua/maui/window.lua').Window
local Edit = import('/lua/maui/edit.lua').Edit
local Text = import('/lua/maui/text.lua').Text
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Tooltip = import('/lua/ui/game/tooltip.lua')
local LazyVar = import('/lua/lazyvar.lua')


local options = Prefs.GetFromCurrentProfile('bcoptions') or {
    messageTextColor = 'ffffffff',
    ctrlKeyColor = 'ffffff00',
    defaultKeyColor = 'ffffffff',
    editTextColor = 'ffffff00',
    treeTextColor = 'ffffff00',
    pingTextColor = 'ff00ffff',
    altKeyColor = 'ffff0000',
    shiftKeyColor = 'ffff8000'
}

--options LazyVars for OptionsWindow

pingTextColor = LazyVar.Create(options['pingTextColor'] or 'ff00ffff')
messageTextColor = LazyVar.Create(options['messageTextColor'] or 'ffffffff')
treeTextColor = LazyVar.Create(options['treeTextColor'] or 'ffffff00')
editTextColor = LazyVar.Create(options['treeTextColor'] or 'ffffff00')

defaultKeyColor = LazyVar.Create(options['defaultKeyColor'] or 'ffffffff')
ctrlKeyColor = LazyVar.Create(options['ctrlKeyColor'] or 'ffffff00')
shiftKeyColor = LazyVar.Create(options['shiftKeyColor'] or 'ffff8000')
altKeyColor = LazyVar.Create(options['altKeyColor'] or 'ffff0000')

BCLine = Class(Checkbox) {
    __init = function(self, parent, bcWindow, id, lineData, isFirst)
        self._window = bcWindow
        Checkbox.__init(self, self._window._lineGroup, UIUtil.SkinnableFile('/MODS/blank.dds'),
            UIUtil.SkinnableFile('/MODS/single.dds'), UIUtil.SkinnableFile('/MODS/single.dds'),
            UIUtil.SkinnableFile('/MODS/double.dds'), UIUtil.SkinnableFile('/MODS/disabled.dds'),
            UIUtil.SkinnableFile('/MODS/disabled.dds'), 'UI_Tab_Click_01', 'UI_Tab_Rollover_01')

        LayoutHelpers.DepthOverParent(self, parent, 1)

        self._id = id

        self._keyText = UIUtil.CreateText(self, '', 16, 'Arial Black', true)
        LayoutHelpers.AtLeftIn(self._keyText, self, 4)
        LayoutHelpers.AtVerticalCenterIn(self._keyText, self)
        self._keyText:DisableHitTest()

        self._bg = Bitmap(self)
        LayoutHelpers.FillParent(self._bg, self)
        self._bg:DisableHitTest()
        self._bg:SetSolidColor("ff000000")
        self._bg:SetAlpha(0.8)
        LayoutHelpers.DepthUnderParent(self._bg, self, 1)

        if isFirst then
            LayoutHelpers.AtLeftTopIn(self, parent, 2, 2)
            LayoutHelpers.AtRightIn(self, parent, 2)
        else
            LayoutHelpers.Below(self, parent, 4)
            LayoutHelpers.AtRightIn(self, parent)

        end
        LayoutHelpers.SetHeight(self, 20)

        self._text = UIUtil.CreateText(self, '', 16, 'Arial', true)
        self._text:Disable()
        LayoutHelpers.AtLeftIn(self._text, self, 40)
        LayoutHelpers.AtVerticalCenterIn(self._text, self)

        -- , "Send to team unless to all"
        self._teamCB = UIUtil.CreateCheckbox(self, '/CHECKBOX/')
        LayoutHelpers.AtRightIn(self._teamCB, self, 10)
        LayoutHelpers.AtVerticalCenterIn(self._teamCB, self)
        LayoutHelpers.DepthOverParent(self._teamCB, self)
        self._teamCB.OnCheck = function(control, checked)
            self._lock = true
            self._team = checked
            local data = {
                data = self._data,
                key = self._key,
                team = self._team,
                modifiers = self._modifiers

            }
            self._window:SetData(self._id, data)
            return true
        end
        Tooltip.AddCheckboxTooltip(self._teamCB, 'team_cb')

        self._teamCB.Activate = function(control, state)
            control:Show()
            control:Enable()
            if state ~= nil then
                control:SetCheck(state, true)
            end
        end
        self._teamCB.Deactivate = function(control)
            control:Hide()
            control:Disable()
            control:SetCheck(false, true)
        end
        self._teamCB:Deactivate()
        self:Hide()
        self:Disable()
        self:SetNeedsFrameUpdate(true)

    end,
    SetText = function(self, text, color)
        self._text:SetText(text)
        if color then
            self._text:SetColor(color)
        end
    end,
    HandleEvent = function(self, event)
        -- prevent modifictaion in shadow mode
        if self._window:GetShadowMode() then
            return
        end
        return Checkbox.HandleEvent(self, event)
    end,
    OnClick = function(self, modifiers)

        if self._lock then
            self._lock = false
            return
        end
        if self._data == nil then
            return
        end
        if modifiers.Left then
            if modifiers.Ctrl then
                self:SetText("press key to bind to", editTextColor)
                self._text:AcquireKeyboardFocus(false)
                self._text:Enable()
                self._text.HandleEvent = function(control, event)
                    if event.Type == 'KeyDown' then
                        if table.getsize(event.Modifiers) > 1 then
                            self:SetText('only one modifier allowed', editTextColor)
                        elseif self._window:SetKey(event.KeyCode, event.Modifiers, self._id) then
                            control:Disable()
                            self:SetModifiersColor(event.Modifiers)
                            self._modifiers = event.Modifiers
                            self._key = string.char(event.KeyCode)
                            self._keyText:SetText(self._key)
                            self:SetCheck(true, true)
                            self._window:AcquireKeyboard()
                            return true
                        else
                            self:SetText('key is already used', editTextColor)
                        end
                    end
                end

                self._text.OnLoseKeyboardFocus = function(control)
                    if self._title then
                        self:SetText(self._title, treeTextColor)
                    elseif self._ping then
                        self:SetText(self._data, pingTextColor)
                    else
                        self:SetText(self._data, messageTextColor)
                    end
                    self:SetModifiersColor(self._modifiers)

                    control:Disable()
                    self._window:AcquireKeyboard()
                end
                self._text.OnKeyboardFocusChange = function(control)
                    if self._title then
                        self:SetText(self._title, treeTextColor)
                    elseif self._ping then
                        self:SetText(self._data, pingTextColor)
                    else
                        self:SetText(self._data, messageTextColor)
                    end
                    self:SetModifiersColor(self._modifiers)
                    control:Disable()
                end
            else
                self._window:CallLine(self._id)
            end
        elseif modifiers.Right then
            -- edit text in line or remove it
            if modifiers.Ctrl then
                self._window:RemoveLine(self._id)
            else
                -- edit text
                local _edit = Edit(self)
                LayoutHelpers.AtLeftIn(_edit, self._text)
                LayoutHelpers.SetHeight(_edit, 16)
                LayoutHelpers.CenteredLeftOf(_edit, self._teamCB, 10)
                UIUtil.SetupEditStd(_edit, "ff00ff00", 'ff000000', "ffffffff", UIUtil.highlightColor, UIUtil.bodyFont,
                    16, 200)

                _edit:AcquireFocus()

                if self._title then
                    _edit:SetText(self._title)
                elseif self._ping then
                    _edit:SetText(self._data)
                else
                    _edit:SetText(self._data)
                end

                self._text:Hide()
                -- _edit:SetCaretPosition()
                _edit.OnEnterPressed = function(control, text)
                    self._text:SetText(text)
                    self._text:Show()

                    if self._title then
                        self._window:SetData(self._id, {
                            key = self._key,
                            data = self._data,
                            title = text,
                            modifiers = self._modifiers
                        })
                        self._title = text
                    elseif self._ping then
                        self._window:SetData(self._id, {
                            key = self._key,
                            ping = true,
                            data = text,
                            modifiers = self._modifiers
                        })
                        self._data = text
                    else
                        self._window:SetData(self._id, {
                            key = self._key,
                            data = text,
                            team = self._team,
                            modifiers = self._modifiers
                        })
                        self._data = text
                    end

                    -- control:Destroy()
                    self._window:AcquireKeyboard()
                end

                -- _edit.OnLoseKeyboardFocus = function(control)
                --     LOG('lost1')
                --     self._text:Show()

                --     control:Destroy()

                --     self._window:AcquireKeyboard()
                -- end
                _edit.OnKeyboardFocusChange = function(control)
                    self._text:Show()
                    control:Destroy()
                end

            end
        end
    end,
    SetModifiersColor = function(self, modifiers)
        if modifiers.Ctrl then
            self._keyText:SetColor(ctrlKeyColor) -- yellow
        elseif modifiers.Shift then
            self._keyText:SetColor(shiftKeyColor) -- orange
        elseif modifiers.Alt then
            self._keyText:SetColor(altKeyColor) -- red
        else
            self._keyText:SetColor(defaultKeyColor) -- white
        end
    end,

    SetData = function(self)
        if self._title then
            self._window:SetData(self._id, {
                key = self._key,
                data = self._data,
                title = self._title,
                modifiers = self._modifiers
            })
        elseif self._ping then
            self._window:SetData(self._id, {
                key = self._key,
                ping = true,
                data = self._data,
                modifiers = self._modifiers
            })
        else
            self._window:SetData(self._id, {
                key = self._key,
                data = self._data,
                team = self._team,
                modifiers = self._modifiers
            })
        end
    end,

    RenderData = function(self, lineData, id)
        self._data = nil
        if lineData then
            self:Show()
            self:Enable()
            self._bg:SetAlpha(0.8)
            self._id = id
            self._key = lineData.key
            self._modifiers = lineData.modifiers
            self._data = lineData.data
            self._keyText:SetText(self._key ~= '' and self._key or '?')
            self:SetModifiersColor(lineData.modifiers)
            self:SetCheck(self._key ~= '', true)
            if lineData.title then
                self._title = lineData.title
                self._ping = nil
                self._team = nil
                self:SetText(self._title, treeTextColor)
                self._teamCB:Deactivate()

            elseif lineData.ping then
                self._title = nil
                self._ping = true
                self._team = nil
                self:SetText(self._data, pingTextColor)
                self._teamCB:Deactivate()

            else
                self._title = nil
                self._ping = nil
                self:SetText(self._data, messageTextColor)
                self._team = lineData.team
                self._teamCB:Activate(self._team)
            end

        else
            self._bg:SetAlpha(0)

            self._teamCB:SetCheck(false, true)
            self._teamCB:Disable()
            self:SetText('')
            self._keyText:SetText('')
            -- self:Hide()
            self:Disable()

        end
        self:SetShadowMode(self._window:GetShadowMode())
    end,
    SetShadowMode = function(self, state)
        if state then
            self._shadowMode = true
            self:SetAlpha(0.3)
            self._bg:SetAlpha(0.1)
            self._teamCB:Deactivate()
            self:DisableHitTest()
        else
            self._shadowMode = false
            self:SetAlpha(1)
            self._bg:SetAlpha(0.8)
            self:EnableHitTest()
            if not self._title and not self._ping and self._data then
                self._teamCB:Activate(self._team)
            else
                self._teamCB:Deactivate()
            end
        end

    end,

    DisableCheckBoxes = function(self)

    end

}
