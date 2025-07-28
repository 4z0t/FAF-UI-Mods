ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.Economy >= 1.1.0",
}

function Main(isReplay)
    local Group = ReUI.UI.Controls.Group
    local Bitmap = ReUI.UI.Controls.Bitmap
    local Text = ReUI.UI.Controls.Text

    local UIUtil = import('/lua/ui/uiutil.lua')

    local animationSpeed = 500

    local contractAnimation = ReUI.UI.Animation.Factory.Base
        :OnStart(function(control, state, speed, offset)
            PlaySound(Sound { Cue = "UI_Score_Window_Close", Bank = "Interface" })
            return { speed = control.Layouter:ScaleNumber(speed), offset = offset }
        end)
        :OnFrame(function(control, delta, state)
            return control.Bottom() < GetFrame(0).Top() - control.Layouter:ScaleNumber(state.offset) or
                control.Top:Set(control.Top() - delta * state.speed)
        end)
        :OnFinish(function(control, state)
            local h = control.Height()
            control.Layouter(control)
                :Top(function() return GetFrame(0).Top() - h - control.Layouter:ScaleNumber(state.offset) end)
        end)
        :Create()

    local expandAnimation = ReUI.UI.Animation.Factory.Base
        :OnStart(function(control, state, speed, offset)
            PlaySound(Sound { Cue = "UI_Score_Window_Open", Bank = "Interface" })
            return { speed = control.Layouter:ScaleNumber(speed), offset = offset }
        end)
        :OnFrame(function(control, delta, state)
            return control.Top() > GetFrame(0).Top() + control.Layouter:ScaleNumber(state.offset) or
                control.Top:Set(control.Top() + delta * state.speed)
        end)
        :OnFinish(function(control, state)
            control.Layouter(control)
                :AtTopIn(GetFrame(0), state.offset)
        end)
        :Create()

    local slideAnimation = ReUI.UI.Animation.Factory.Base
        :OnStart(function(control, state, speed, offset)
            local height = control.Height()
            control.Layouter(control)
                :Top(function() return GetFrame(0).Top() - height - control.Layouter:ScaleNumber(offset) end)
            return { speed = control.Layouter:ScaleNumber(speed), offset = offset }
        end)
        :OnFrame(function(control, delta, state)
            return control.Top() > GetFrame(0).Top() + control.Layouter:ScaleNumber(state.offset) or
                control.Top:Set(control.Top() + delta * state.speed)
        end)
        :OnFinish(function(control, state)
            control.Layouter(control)
                :AtTopIn(GetFrame(0), state.offset)
        end)
        :Create()


    ReUI.Core.Hook("/lua/ui/game/layouts/tabs_mini.lua", "SetLayout", function(field, module)
        return function()
            field()
            local controls = import("/lua/ui/game/tabs.lua").controls
            ReUI.UI.FloorLayoutFor(controls.parent)
                :AtHorizontalCenterIn(GetFrame(0), 500)
        end
    end)

    ReUI.Core.Hook("/lua/ui/game/layouts/multifunction_mini.lua", "SetLayout", function(field, module)
        return function()
            field()
            local controls = import("/lua/ui/game/multifunction.lua").controls
            ReUI.UI.FloorLayoutFor(controls.bg)
                :AtTopIn(GetFrame(0), 75)

            ReUI.UI.FloorLayoutFor(controls.collapseArrow)
                :AtVerticalCenterIn(controls.bg)
        end
    end)

    ---@class BlockLayout : ReUI.UI.BaseLayout
    local BlockLayout = Class(ReUI.UI.BaseLayout)
    {
        ---@param self BlockLayout
        ---@param control ResourceBlock
        ---@param layouter? ReUILayouter
        Apply = function(self, control, layouter)
            layouter = layouter or control.Layouter

            ---@param control ResourceBlock
            ---@param mode "yellow"|"red"
            control.SetBGMode = function(control, mode)
                local bg = control._bg

                if mode == 'red' then
                    bg:SetSolidColor "red"
                elseif mode == 'yellow' then
                    bg:SetSolidColor "yellow"
                end
            end

            layouter(control._bg)
                :AtCenterIn(control, 0, -1)
                :Color "red"
                :FillFixedBorder(control, -6)
                :Alpha(0)

            layouter(control._icon)
                :Texture(UIUtil.UIFile(control.Style.icon.texture))
                :Width(control.Style.icon.width)
                :Height(control.Style.icon.height)
                :AtLeftIn(control, control.Style.icon.left)
                :AtVerticalCenterIn(control)

            layouter(control._bar)
                :AtLeftTopIn(control, 22, 2)
                :Width(100)
                :Height(10)

            control._bar._bar:SetTexture(UIUtil.UIFile(control.Style.barTexture))
            local color = control.Style.textColor
            -- control._bar.BarColor = color


            layouter(control._maxStorage)
                :AnchorToBottom(control._bar)
                :AtRightIn(control._bar)
                :Color(color)
                :DropShadow(true)

            layouter(control._curStorage)
                :AnchorToBottom(control._bar)
                :AtLeftIn(control._bar)
                :Color(color)
                :DropShadow(true)

            layouter(control._rate)
                :RightOf(control._bar, 5)
                :AtVerticalCenterIn(control)
                :DropShadow(true)

            layouter(control._percentage)
                :RightOf(control._rate, 2)
                :Color(color)
                :DropShadow(true)

            layouter(control._reclaimDelta)
                :AtRightTopIn(control, 2)
                :Color('ffb7e75f')
                :DropShadow(true)

            layouter(control._reclaimTotal)
                :AtRightBottomIn(control, 2)
                :Color(control.Style.reclaimTotalColor)
                :DropShadow(true)

            layouter(control._income)
                :AtRightTopIn(control, 49)
                :Color('ffb7e75f')
                :DropShadow(true)

            layouter(control._expense)
                :AtRightBottomIn(control, 49)
                :Color('fff30017')
                :DropShadow(true)

            layouter(control)
                :Width(296)
                :Height(25)
                :DisableHitTest(true)
        end,

        ---@param self BlockLayout
        ---@param control ResourceBlock
        Restore = function(self, control)
            control.SetBGMode = nil
        end
    }

    ---@class MiddleLayout : ReUI.UI.BaseLayout
    local MiddleLayout = Class(ReUI.UI.BaseLayout)
    {
        ---@param self EconomyPanel
        ---@param layouter ReUILayouter
        Layout = function(self, layouter)
            ---@param self EconomyPanel
            self.Contract = function(self)
                contractAnimation:Apply(self, animationSpeed, 15)
            end

            ---@param self EconomyPanel
            self.Expand = function(self)
                expandAnimation:Apply(self, animationSpeed, 15)
            end

            ---@param self EconomyPanel
            self.InitialAnimation = function(self)
                slideAnimation:Apply(self, animationSpeed, 15)
            end


            if self._glow then
                self._glow:Destroy()
                self._glow = nil
            end
            -- if self._bg then
            --     self._bg:Destroy()
            --     self._bg = nil
            -- end
            if self._bracket then
                self._bracket:Destroy()
                self._bracket = nil
            end
            if self._bracketGlow then
                self._bracketGlow:Destroy()
                self._bracketGlow = nil
            end

            if self._arrow then
                self._arrow:Destroy()
                self._arrow = nil
            end

            if self._border then
                self._border:Destroy()
            end
            self._border = ReUI.UI.Views.GlowBorder(self)


            layouter(self._mass)
                :AtCenterIn(self, 0, -162)

            layouter(self._energy)
                :AtCenterIn(self, 0, 162)

            self._mass.Layout = BlockLayout()
            self._energy.Layout = BlockLayout()

            layouter(self._bg)
                :Fill(self)
                :Color "aa000000"
                :DisableHitTest()

            layouter(self._border)
                :FillFixedBorder(self, -10)
                :Under(self)
                :DisableHitTest(true)

            self._arrow = ReUI.UI.Views.HorizontalCollapseArrow(self)
            self._arrow:SetCheck(false, true)

            self._arrow.OnCheck = function(arrow, checked)
                if not checked then
                    self:Expand()
                else
                    self:Contract()
                end
            end

            layouter(self._arrow)
                :AtHorizontalCenterIn(self)
                :DefaultScale(function(_layouter)
                    _layouter:AtTopIn(GetFrame(0), -3)
                end)
                :Over(self, 20)

            layouter(self)
                :Width(636)
                :Height(36)
                :AtTopCenterIn(self:GetParent(), 15)
        end,

        ---@param self EconomyPanel
        ---@param layouter ReUILayouter
        Clear = function(self, layouter)
            self.Contract = nil
            self.Expand = nil
            self.InitialAnimation = nil

            self._glow = ReUI.UI.Views.Brackets.RightGlow(self)

            if self._arrow then
                self._arrow:Destroy()
                self._arrow = nil
            end

            self._arrow = ReUI.UI.Views.VerticalCollapseArrow(self)
            self._arrow:SetCheck(true, true)

            self._arrow.OnCheck = function(arrow, checked)
                if checked then
                    self:Expand()
                else
                    self:Contract()
                end
            end

            -- self._bg = Bitmap(self)
            self._bracket = Bitmap(self)
            self._bracketGlow = Bitmap(self)

            if self._border then
                self._border:Destroy()
                self._border = nil
            end

            self._mass.Layout = nil
            self._energy.Layout = nil
        end,

        ---@param self MiddleLayout
        ---@param control EconomyPanel
        ---@param layouter? ReUILayouter
        Apply = function(self, control, layouter)
            self.Layout(control, layouter or control.Layouter)
        end,

        ---@param self MiddleLayout
        ---@param control EconomyPanel
        Restore = function(self, control)
            self.Clear(control, control.Layouter)
        end
    }

    ReUI.Economy.Layouts["middle"] = MiddleLayout()

end
