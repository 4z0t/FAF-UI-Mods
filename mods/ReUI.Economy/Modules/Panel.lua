local GetEconomyTotals = GetEconomyTotals
local GetSimTicksPerSecond = GetSimTicksPerSecond
local math = math

local UIUtil = import('/lua/ui/uiutil.lua')

local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap
local Text = ReUI.UI.Controls.Text

-- local StatusBar = import("StatusBar.lua").StatusBar
local StatusBar = import("/lua/maui/statusbar.lua").StatusBar

local contractAnimation = ReUI.UI.Animation.Factory.Base
    :OnStart(function(control, state, speed, offset)
        PlaySound(Sound { Cue = "UI_Score_Window_Close", Bank = "Interface" })
        return { speed = control.Layouter:ScaleNumber(speed), offset = offset }
    end)
    :OnFrame(function(control, delta, state)
        return control.Right() < GetFrame(0).Left() - control.Layouter:ScaleNumber(state.offset) or
            control.Left:Set(control.Left() - delta * state.speed)
    end)
    :OnFinish(function(control, state)
        local width = control.Width()
        control.Layouter(control)
            :Left(function() return GetFrame(0).Left() - width - control.Layouter:ScaleNumber(state.offset) end)
    end)
    :Create()

local expandAnimation = ReUI.UI.Animation.Factory.Base
    :OnStart(function(control, state, speed, offset)
        PlaySound(Sound { Cue = "UI_Score_Window_Open", Bank = "Interface" })
        return { speed = control.Layouter:ScaleNumber(speed), offset = offset }
    end)
    :OnFrame(function(control, delta, state)
        return control.Left() > GetFrame(0).Left() + control.Layouter:ScaleNumber(state.offset) or
            control.Left:Set(control.Left() + delta * state.speed)
    end)
    :OnFinish(function(control, state)
        control.Layouter(control)
            :AtLeftIn(GetFrame(0), state.offset)
    end)
    :Create()

local slideAnimation = ReUI.UI.Animation.Factory.Base
    :OnStart(function(control, state, speed, offset)
        local width = control.Width()
        control.Layouter(control)
            :Left(function() return GetFrame(0).Left() - width - control.Layouter:ScaleNumber(offset) end)
        return { speed = control.Layouter:ScaleNumber(speed), offset = offset }
    end)
    :OnFrame(function(control, delta, state)
        return control.Left() > GetFrame(0).Left() + control.Layouter:ScaleNumber(state.offset) or
            control.Left:Set(control.Left() + delta * state.speed)
    end)
    :OnFinish(function(control, state)
        control.Layouter(control)
            :AtLeftIn(GetFrame(0), state.offset)
    end)
    :Create()


local bgBlinkAnimation = ReUI.UI.Animation.Factory.Base
    :OnStart(function(control, state, flashMod)
        return {
            cycles = 0,
            ascending = 1,
            flashMod = flashMod,
        }
    end)
    :OnFrame(function(control, delta, state)
        local newAlpha = control:GetAlpha() + delta * state.flashMod * state.ascending
        if newAlpha > .5 then
            newAlpha = .5
            state.cycles = state.cycles + 1
            state.ascending = -1
        elseif newAlpha < 0 then
            newAlpha = 0
            state.ascending = 1
        end
        control:SetAlpha(newAlpha)
        return state.cycles >= 5
    end)
    :OnFinish()
    :Create()

local fadeAnimation = ReUI.UI.Animation.Factory.Alpha
    :ToFade()
    :For(1)
    :EndWith(0)
    :Create()

local animationSpeed = 500


local function FormatNumber(n)
    return math.round(math.clamp(n, 0, 99999999))
end

local MathAbs = math.abs
---Formats number as large one
---@param n number | nil
---@return string
local function FormatNumber(n)
    if n == nil then return "" end

    local an = MathAbs(n)
    if an < 1000 then
        return ("%01.0f"):format(n)
    elseif an < 10000 then
        return ("%01.1fk"):format(n / 1000)
    elseif an < 1000000 then
        return ("%01.0fk"):format(n / 1000)
    else
        return ("%01.1fm"):format(n / 1000000)
    end
end

---@class ResourceBlock : ReUI.UI.Controls.Group
---@field _type ResourceType
---@field _lastReclaimTotal number
---@field _bg ReUI.UI.Controls.Bitmap
---@field _icon ReUI.UI.Controls.Bitmap
---@field _bar StatusBar
---@field _curStorage ReUI.UI.Controls.Text
---@field _maxStorage ReUI.UI.Controls.Text
---@field _income ReUI.UI.Controls.Text
---@field _expense ReUI.UI.Controls.Text
---@field _percentage ReUI.UI.Controls.Text
---@field _rate ReUI.UI.Controls.Text
---@field _reclaimDelta ReUI.UI.Controls.Text
---@field _reclaimTotal ReUI.UI.Controls.Text
ResourceBlock = ReUI.Core.Class(Group)
{
    AutoLayout = false,

    ---@class ResourceBlockStyleIcon
    ---@field texture FileName
    ---@field width number
    ---@field height number
    ---@field left number

    ---@class ResourceBlockStyle
    ---@field textColor Color
    ---@field barTexture FileName
    ---@field icon ResourceBlockStyleIcon
    ---@field warningColor Color
    ---@field reclaimTotalColor Color
    Style = {},

    ---@param self ResourceBlock
    ---@param parent Control
    ---@param resourceType ResourceType
    __init = function(self, parent, resourceType)
        Group.__init(self, parent)
        self._type = resourceType
        self._lastReclaimTotal = 0
        self._lastReclaimRate = 0

        self._bg = Bitmap(self)
        self._icon = Bitmap(self)

        self._bar = StatusBar(self, 0, 1, false, false,
            UIUtil.UIFile('/game/resource-mini-bars/mini-energy-bar-back_bmp.dds'),
            UIUtil.UIFile('/game/resource-mini-bars/mini-energy-bar_bmp.dds'), false)

        self._curStorage = Text.Create(self, UIUtil.bodyFont, 10)
        self._maxStorage = Text.Create(self, UIUtil.bodyFont, 10)
        self._income = Text.Create(self, UIUtil.bodyFont, 10)
        self._expense = Text.Create(self, UIUtil.bodyFont, 10)
        self._percentage = Text.Create(self, UIUtil.bodyFont, 10)
        self._rate = Text.Create(self, UIUtil.bodyFont, 18)
        self._reclaimDelta = Text.Create(self, UIUtil.bodyFont, 10)
        self._reclaimTotal = Text.Create(self, UIUtil.bodyFont, 10)

        self._bg._state = ''
    end,

    ---@param self ResourceBlock
    ---@param mode "yellow"|"red"
    SetBGMode = function(self, mode)
        local bg = self._bg

        if mode == 'red' then
            bg:SetFrame(0)
        elseif mode == 'yellow' then
            bg:SetFrame(1)
        end
    end,

    ---@param self ResourceBlock
    ---@param state "yellow"|"hide"|"red"
    SetBGState = function(self, state)
        local bg = self._bg
        if bg._state == state then
            return
        end
        bg._state = state

        if state == 'red' then
            self:SetBGMode "red"
            bgBlinkAnimation:Apply(bg, 1.6)
        elseif state == 'yellow' then
            self:SetBGMode "yellow"
            bgBlinkAnimation:Apply(bg, 1.25)
        elseif state == "hide" then
            fadeAnimation:Apply(bg)
        end
    end,

    ---@param self ResourceBlock
    ---@return boolean
    FlipFlop = function(self)
        self._blink = not self._blink
        return self._blink
    end,

    ---@param self ResourceBlock
    ---@param rateVal number
    ---@param storedVal number
    ---@param maxStorageVal number
    UpdateWarning = function(self, rateVal, storedVal, maxStorageVal)
    end,

    ---@param self ResourceBlock
    ---@param data EconomyTotals
    ---@param tps number
    Update = function(self, data, tps)
        local rtype = self._type

        local totalReclaimed = data.reclaimed[rtype]

        local thisTick = totalReclaimed - self._lastReclaimTotal

        self._lastReclaimTotal = totalReclaimed

        local reclaimRate = thisTick * tps

        self._reclaimDelta:SetText('+' .. FormatNumber(reclaimRate))
        self._reclaimTotal:SetText(FormatNumber(totalReclaimed))

        local maxStorageVal = data.maxStorage[rtype]
        local storedVal = data.stored[rtype]

        self._bar:SetRange(0, maxStorageVal)
        self._bar:SetValue(storedVal)

        self._curStorage:SetText(FormatNumber(storedVal))
        self._maxStorage:SetText(FormatNumber(maxStorageVal))

        local incomeVal = data.income[rtype]

        local incomeSec = math.max(0, incomeVal * tps)
        local generatedIncome = incomeSec - self._lastReclaimRate

        local expense
        if storedVal > 0.5 then
            expense = data.lastUseActual[rtype] * tps
        else
            expense = data.lastUseRequested[rtype] * tps
        end

        self._income:SetText(string.format("+%s", FormatNumber(generatedIncome)))
        self._expense:SetText(string.format("-%s", FormatNumber(expense)))

        self._lastReclaimRate = reclaimRate

        local rateVal = incomeSec - expense

        local effVal
        if expense == 0 then
            effVal = incomeSec * 100
        else
            effVal = math.round((incomeSec / expense) * 100)
        end

        self._percentage:SetText(string.format("%d%%", math.min(effVal, 100)))

        self._rate:SetText(string.format(rateVal > 0 and "+%s" or "%s", FormatNumber(rateVal)))

        self:UpdateWarning(rateVal, storedVal, maxStorageVal)
        --rateTxt:SetColor(getRateColour(rateVal, storedVal, maxStorageVal))
    end,

    ---@param self ResourceBlock
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        self._bg:SetTexture({
            UIUtil.UIFile('/game/resource-panel/alert-' .. self._type .. '-panel_bmp.dds'--[[@as FileName]] ),
            UIUtil.UIFile('/game/resource-panel/caution-' .. self._type .. '-panel_bmp.dds'--[[@as FileName]] )
        })
        layouter(self._bg)
            :AtCenterIn(self, 0, -1)
            :Alpha(0)

        layouter(self._icon)
            :Texture(UIUtil.UIFile(self.Style.icon.texture))
            :Width(self.Style.icon.width)
            :Height(self.Style.icon.height)
            :AtLeftIn(self, self.Style.icon.left)
            :AtVerticalCenterIn(self)

        layouter(self._bar)
            :AtLeftTopIn(self, 22, 2)
            :Width(100)
            :Height(10)

        self._bar._bar:SetTexture(UIUtil.UIFile(self.Style.barTexture))
        local color = self.Style.textColor
        -- self._bar.BarColor = color

        layouter(self._maxStorage)
            :AnchorToBottom(self._bar)
            :AtRightIn(self._bar)
            :Color(color)
            :DropShadow(true)

        layouter(self._curStorage)
            :AnchorToBottom(self._bar)
            :AtLeftIn(self._bar)
            :Color(color)
            :DropShadow(true)

        layouter(self._rate)
            :RightOf(self._bar, 5)
            :AtVerticalCenterIn(self)
            :DropShadow(true)

        layouter(self._percentage)
            :RightOf(self._rate, 2)
            :Color(color)
            :DropShadow(true)

        layouter(self._income)
            :AtRightTopIn(self, 2)
            :Color('ffb7e75f')
            :DropShadow(true)

        layouter(self._expense)
            :AtRightBottomIn(self, 2)
            :Color('fff30017')
            :DropShadow(true)

        layouter(self._reclaimDelta)
            :AtRightTopIn(self, 49)
            :Color('ffb7e75f')
            :DropShadow(true)

        layouter(self._reclaimTotal)
            :AtRightBottomIn(self, 49)
            :Color(self.Style.reclaimTotalColor)
            :DropShadow(true)

        layouter(self)
            :Width(296)
            :Height(25)
            :DisableHitTest(true)
    end,
}

---@class MassBlock : ResourceBlock
MassBlock = ReUI.Core.Class(ResourceBlock)
{
    ---@param self MassBlock
    ---@param parent Control
    __init = function(self, parent)
        ResourceBlock.__init(self, parent, "MASS")
    end,

    ---@param self MassBlock
    ---@param rateVal number
    ---@param storedVal number
    ---@param maxStorageVal number
    UpdateWarning = function(self, rateVal, storedVal, maxStorageVal)
        local storedRatio = storedVal / maxStorageVal
        if storedRatio <= 0.8 then
            self:SetBGState('hide')
        elseif storedRatio <= 0.9 and rateVal > 0 then
            self:SetBGState('yellow')
        elseif storedRatio > 0.9 and rateVal > 0 then
            self:SetBGState('red')
        end

        if rateVal < 0 then
            if storedRatio > 0 then
                self._rate:SetColor('yellow')
            else
                self._rate:SetColor('red')
            end
        else
            if storedRatio >= 1 then
                self._rate:SetColor(self:FlipFlop() and "ffffffff" or "ff404040")
            else
                self._rate:SetColor('ffb7e75f')
            end
        end
    end,

    Style = {
        textColor = 'ffb7e75f',
        barTexture = '/game/resource-bars/mini-mass-bar_bmp.dds',
        icon = {
            texture = '/game/resources/mass_btn_up.dds',
            left = -14,
            width = 44,
            height = 36
        },
        warningColor = '8800ff00',
        reclaimTotalColor = 'FFB8F400'
    }
}

---@class EnergyBlock : ResourceBlock
EnergyBlock = ReUI.Core.Class(ResourceBlock)
{
    ---@param self EnergyBlock
    ---@param parent Control
    __init = function(self, parent)
        ResourceBlock.__init(self, parent, "ENERGY")
    end,

    ---@param self EnergyBlock
    ---@param rateVal number
    ---@param storedVal number
    ---@param maxStorageVal number
    UpdateWarning = function(self, rateVal, storedVal, maxStorageVal)
        local storedRatio = storedVal / maxStorageVal
        if storedRatio >= 0.2 then
            self:SetBGState('hide')
        elseif storedRatio > 0.1 and rateVal < 0 then
            self:SetBGState('yellow')
        elseif storedRatio <= 0.1 and rateVal < 0 then
            self:SetBGState('red')
        end

        if rateVal >= 0 then
            self._rate:SetColor('ffb7e75f')
        elseif storedRatio <= 0 then
            self._rate:SetColor('red')
        elseif storedRatio <= 0.2 then
            self._rate:SetColor(self:FlipFlop() and "ffffffff" or "ff404040")
        else
            self._rate:SetColor('yellow')
        end
    end,

    Style = {
        textColor = 'fff7c70f',
        barTexture = '/game/resource-bars/mini-energy-bar_bmp.dds',
        icon = {
            texture = '/game/resources/energy_btn_up.dds',
            left = -10,
            width = 36,
            height = 36
        },
        warningColor = '88ff9000',
        reclaimTotalColor = 'FFF8C000'
    }
}

---@class EconomyPanel : ReUI.UI.Controls.Group
---@field _bg ReUI.UI.Controls.Bitmap
---@field _bracket ReUI.UI.Controls.Bitmap
---@field _bracketGlow ReUI.UI.Controls.Bitmap
---@field _glow ReUI.UI.Views.RightGlow
---@field _mass ResourceBlock
---@field _energy ResourceBlock
---@field _arrow ReUI.UI.Views.VerticalCollapseArrow
EconomyPanel = ReUI.Core.Class(Group)
{
    ---@param self EconomyPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)
        self.Layouter = ReUI.UI.RoundLayouter(1)

        self._bg = Bitmap(self)
        self._bracket = Bitmap(self)
        self._bracketGlow = Bitmap(self)

        self._glow = ReUI.UI.Views.Brackets.RightGlow(self)

        self._mass = MassBlock(self)
        self._energy = EnergyBlock(self)

        self._arrow = ReUI.UI.Views.VerticalCollapseArrow(self)
        self._arrow:SetCheck(true, true)

        self._arrow.OnCheck = function(arrow, checked)
            if checked then
                self:Expand()
            else
                self:Contract()
            end
        end
    end,

    ---@param self EconomyPanel
    Update = function(self)
        local econData = GetEconomyTotals()
        local tps = GetSimTicksPerSecond()

        self._mass:Update(econData, tps)
        self._energy:Update(econData, tps)
    end,

    ---@param self EconomyPanel
    Contract = function(self)
        contractAnimation:Apply(self, animationSpeed, 16)
    end,

    ---@param self EconomyPanel
    Expand = function(self)
        expandAnimation:Apply(self, animationSpeed, 16)
    end,

    ---@param self EconomyPanel
    InitialAnimation = function(self)
        slideAnimation:Apply(self, animationSpeed, 16)
    end,

    ---@param self EconomyPanel
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self._bg)
            :Texture(UIUtil.SkinnableFile '/game/resource-panel/resources_panel_bmp.dds')
            :AtCenterIn(self)
            :Under(self)
            :DisableHitTest()

        layouter(self._bracket)
            :Texture(UIUtil.SkinnableFile '/game/filter-ping-panel/bracket-left_bmp.dds')
            :AnchorToLeft(self, -10)
            :AtVerticalCenterIn(self)
            :Over(self)
            :DisableHitTest()

        layouter(self._bracketGlow)
            :Texture(UIUtil.SkinnableFile '/game/filter-ping-panel/bracket-energy-l_bmp.dds')
            :AtLeftIn(self._bracket, 12)
            :Under(self._bracket)
            :AtVerticalCenterIn(self)
            :DisableHitTest()

        layouter(self._glow)
            :AnchorToRight(self._bg, 5)
            :AtTopIn(self._bg, 2)
            :AtBottomIn(self._bg, 2)

        layouter(self._mass)
            :AtCenterIn(self, -15)
            :PerformLayout()

        layouter(self._energy)
            :AtCenterIn(self, 15)
            :PerformLayout()

        layouter(self._arrow)
            :AtVerticalCenterIn(self)
            :DefaultScale(function(_layouter)
                _layouter:AtLeftIn(GetFrame(0), -3)
            end)
            :Over(self, 20)

        layouter(self)
            :Width(324)
            :Height(72)
            :AtLeftTopIn(self:GetParent(), 16, 3)
    end,

    ---@param self EconomyPanel
    ReLayout = function(self)
        self:Layout()
        self._mass:Layout()
        self._energy:Layout()
    end
}
