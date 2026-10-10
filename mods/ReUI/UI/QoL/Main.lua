Version = "1.0.0"

ReUI.Require
{
    "ReUI.Core >= 1.2.0",
    "ReUI.Options >= 1.2.0",
    "ReUI.UI >= 1.4.0",
}

function Main()
    local Dragger = import("/lua/maui/dragger.lua").Dragger
    local UIUtil = import("/lua/ui/uiutil.lua")
    local Prefs = import("/lua/user/prefs.lua")
    local Group = import('/lua/maui/group.lua').Group
    local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
    local Edit = import("/lua/maui/edit.lua").Edit
    local CheckBox = import('/lua/maui/checkbox.lua').Checkbox

    local LayoutFor = ReUI.UI.FloorLayoutFor


    local options = ReUI.Options.Mods["ReUI.UI.QoL"]

    --- Set multifunction collapse arrow to its center
    ReUI.Core.Hook("/lua/ui/game/layouts/multifunction_mini.lua", "SetLayout", function(field, module)
        return function()
            field()
            local controls = import("/lua/ui/game/multifunction.lua").controls
            LayoutFor(controls.collapseArrow)
                :AtVerticalCenterIn(controls.bg)
        end
    end)

    if options.multifunctionPanelCollapsed.Value then
        ReUI.Core.Hook("/lua/ui/game/multifunction.lua", "InitialAnimation", function(field, module)
            return function()
                local controls = module.controls
                local savedParent = module.savedParent

                controls.bg.Left:Set(savedParent.Left() - controls.bg.Width() - 10)
                controls.collapseArrow:SetCheck(true, true)
                controls.bg:Hide()

                -- Game shows all controls at start and MULTIFUNCTION thinks it is expanded
                -- So we tell it to HIDE anyway
                ForkThread(function()
                    WaitSeconds(1)
                    module.ToggleMFDPanel(false)
                end)

            end
        end)
    end

    if options.menuPanelCollapsed.Value then
        ReUI.Core.Hook("/lua/ui/game/tabs.lua", "InitialAnimation", function(field, module)
            return function()
                local controls = module.controls
                local savedParent = controls.parent:GetParent()

                controls.parent.Top:Set(savedParent.Top() - controls.parent.Height())
                controls.collapseArrow:SetCheck(true, true)
                controls.parent:Hide()

                -- Game shows all controls at start and TABS thinks it is expanded
                -- So we tell it to HIDE anyway
                ForkThread(function()
                    WaitSeconds(1)
                    module.ToggleTabDisplay(false)
                end)
            end
        end)
    end

    if options.movableMenuPanel.Value then
        ---@param self Control
        ---@param x number
        local function SetPos(self, x)
            local f = self:GetRootFrame()
            x = math.clamp(x, f.Left(), f.Right())
            LayoutFor(self)
                :Left(function() return x + f.Left() - self.Width() * 0.5 end)
        end

        local function LoadPosition()
            return Prefs.GetFromCurrentProfile("MenuPanelPos")
        end

        local function SavePosition(x)
            Prefs.SetToCurrentProfile("MenuPanelPos", {
                left = x
            })
        end

        ReUI.Core.Hook("/lua/ui/game/tabs.lua", "CommonLogic", function(field, module)
            return function()
                field()
                local controls = module.controls

                controls.parent.HandleEvent = function(self, event)
                    if event.Type == "ButtonPress" and event.Modifiers.Middle then
                        local drag = Dragger()
                        local offX = event.MouseX - self.Left() - self.Width() * 0.5
                        drag.OnMove = function(dragself, x, y)
                            SetPos(self, x - offX)
                            GetCursor():SetTexture(UIUtil.GetCursor("W_E"))
                        end
                        drag.OnRelease = function(dragself, x, y)
                            SavePosition(x - offX)
                            GetCursor():Reset()
                            drag:Destroy()
                        end
                        PostDragger(self:GetRootFrame(), event.KeyCode, drag)
                        return true
                    end
                    return false
                end

                for i = 1, 3 do
                    local handleEvent = controls.tabs[i].HandleEvent
                    ---@param self MauiCheckbox
                    ---@param event KeyEvent
                    controls.tabs[i].HandleEvent = function(self, event)
                        if (event.Type == 'ButtonPress' or event.Type == 'ButtonDClick') and event.Modifiers.Middle then
                            return false
                        end
                        return handleEvent(self, event)
                    end
                end

            end
        end)

        ReUI.Core.Hook("/lua/ui/game/layouts/tabs_mini.lua", "SetLayout", function(field, module)
            return function()
                field()
                local controls = import("/lua/ui/game/tabs.lua").controls
                local panel = controls.parent

                local pos = LoadPosition()
                if pos then
                    SetPos(panel, pos.left)
                end
            end
        end)
    end

    if options.advancedPingDialog.Value then

        local QuickWindow = ReUI.UI.Quick.Window
        local QuickContainer = ReUI.UI.Quick.Container
        local QuickContext = ReUI.UI.Quick.Context

        ---@class ReUI.UI.QoL.PingDialog : Quick.Window
        local Dialog = ReUI.Core.Class(QuickWindow)
        {
            ContextClass = ReUI.Core.Class(QuickContext)
            {
                ---@class ReUI.UI.QoL.PingDialog.Container : Quick.Container
                ContainerClass = ReUI.Core.Class(QuickContainer)
                {
                    ---@param self ReUI.UI.QoL.PingDialog.Container
                    Input = function(self, cb, onEscape)
                        local edit = Edit(self._control)
                        edit:AcquireFocus()

                        edit.OnLoseKeyboardFocus = function(self)
                            edit:AcquireFocus()
                        end

                        LayoutFor(edit)
                            :Top(0)
                            :Left(0)
                            :Width(0)
                            :Height(24)

                        UIUtil.SetupEditStd(edit, "ff00ff00", 'ff000000', "ffffffff",
                            UIUtil.highlightColor, UIUtil.bodyFont, 20, 100)

                        edit.OnEnterPressed = function(e, text)
                            cb(text)
                            return true
                        end

                        edit.OnEscPressed = function(self, text)
                            onEscape(text)
                            return true
                        end

                        self:Builder():AddControl(edit, {
                            width = self:Builder():GetItemWidth(),
                            height = 24
                        })

                    end,

                    ---@param self ReUI.UI.QoL.PingDialog.Container
                    SelectorLine = function(self, text, cb)
                        local line = CheckBox(self._control,
                            UIUtil.SkinnableFile('/MODS/blank.dds'),
                            UIUtil.SkinnableFile('/MODS/single.dds'),
                            UIUtil.SkinnableFile('/MODS/single.dds'),
                            UIUtil.SkinnableFile('/MODS/double.dds'),
                            UIUtil.SkinnableFile('/MODS/disabled.dds'),
                            UIUtil.SkinnableFile('/MODS/disabled.dds'),
                            'UI_Tab_Click_01', 'UI_Tab_Rollover_01')

                        line.text = UIUtil.CreateText(line, '', 18, UIUtil.bodyFont, true)
                        line.text:SetText(text)

                        line.OnCheck = function(l, checked)
                            cb()
                        end

                        LayoutFor(line.text)
                            :Color('FFE9ECE9')
                            :DisableHitTest()
                            :AtLeftIn(line, 5)
                            :AtVerticalCenterIn(line)

                        self:Builder():AddControl(line, {
                            width = self:Builder():GetItemWidth(),
                            height = 30
                        })
                    end,

                }
            }
        }

        ReUI.Core.Hook("/lua/ui/game/ping.lua", "NamePing", function(field, module)
            local UTF = import("/lua/utf.lua")
            local Enumerate = ReUI.LINQ.Enumerate

            ---@type ReUI.Options.OptionRef
            local history = ReUI.Options.OptionRef { "PingHistory" }

            local function AddEntry(text)
                text = UTF.EscapeString(text)

                local prev = history:Get({})
                local i = Enumerate(prev):Select "text":Contains(text)

                if i then
                    prev[i].count = prev[i].count + 1
                else
                    table.insert(prev, { text = text, count = 1 })
                end

                history:Set(prev)
            end

            return function(callback, curName)
                if not IsDestroyed(ReUI.UI.Global["PingDialog"]) then
                    return
                end

                local function OnInput(text)
                    if not callback(text) then
                        AddEntry(text)
                        ReUI.UI.Global["PingDialog"]:Destroy()
                    end
                end

                ---@param q ReUI.UI.QoL.PingDialog.Container
                ReUI.UI.Global["PingDialog"] = Dialog(LOC("<LOC markers_0000>Enter Marker Name"), function(q)
                    q:PushItemWidth(324)
                    q:Input(OnInput, function()
                        ReUI.UI.Global["PingDialog"]:Destroy()
                    end)
                    q:PopItemWidth()

                    local list = history:Get({})
                    list       = Enumerate(list)
                        :OrderByDescending(function(v) return v.count end)
                        :Select(function(v) return UTF.UnescapeString(v.text) end)
                        :ToArray()

                    ---@param row ReUI.UI.QoL.PingDialog.Container
                    q:ScrollableList(0, 300, table.getn(list), 30, function(row, index)
                        local text = list[index]
                        row:SelectorLine(text, function(modifiers)
                            OnInput(text)
                        end)
                    end)

                    if q:Collapsible("History options", false) then
                        q:Button("clear history", function(modifiers)
                            history:Set({})
                            q:Context():UpdateWindow()
                        end)
                    end
                end, "ping_dialog")
            end
        end)
    end
end
