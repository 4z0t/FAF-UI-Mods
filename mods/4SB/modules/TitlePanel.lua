local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local InfoPanel = import("InfoPanel.lua").InfoPanel


local Options = import("/mods/4SB/modules/Options.lua")

local LayoutFor = UMT.Layouter.ReusedLayoutFor
local alphaAnimator = UMT.Animation.Animator(GetFrame(0))
local animationFactory = UMT.Animation.Factory.Base
local alphaAnimationFactory = UMT.Animation.Factory.Alpha

local timeTextSize = 12
local qualityTextSize = 12
local unitCapTextSize = 12


local titlePanelWidth = 300
local titlePanelHeight = 20

local bgColor = Options.title.color.bg:Raw()



local TopInfoPanel = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self._gameSpeed = 0


        self._time = Text(self)
        self._speed = Text(self)
        self._quality = Text(self)
        self._unitCap = Text(self)

    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)
        local parent = self:GetParent()
        LayoutFor(self._time)
            :AtLeftIn(self, 10)
            :AtVerticalCenterIn(self)
            :DisableHitTest()
        self._time:SetFont(Options.title.font.time:Raw(), timeTextSize)


        LayoutFor(self._speed)
            :AtCenterIn(self, 0, -30)
            :DisableHitTest()
        self._speed:SetFont(Options.title.font.gameSpeed:Raw(), qualityTextSize)

        LayoutFor(self._quality)
            :AtCenterIn(self, 0, 30)
            :DisableHitTest()
        self._quality:SetFont(Options.title.font.quality:Raw(), qualityTextSize)

        LayoutFor(self._unitCap)
            :AtRightIn(self, 10)
            :AtVerticalCenterIn(self)
            :DisableHitTest()
        self._unitCap:SetFont(Options.title.font.totalUnits:Raw(), unitCapTextSize)

        LayoutFor(self)
            :Width(parent.Width)
            :Height(titlePanelHeight)
    end,

    SetQuality = function(self, quality)
        if quality then
            self._quality:SetText(string.format("Q:%.2f%%", quality))
        else
            self._quality:SetText("")
        end
    end,

    Update = function(self, data, gameSpeed)
        if gameSpeed then
            self._gameSpeed = gameSpeed
        end
        self._speed:SetText(string.format("%+d / %+d", self._gameSpeed, GetSimRate()))
        self._time:SetText(GetGameTime())

        if data then
            local scoreData = data[GetFocusArmy()]
            if scoreData.general.currentcap then
                self._unitCap:SetText(string.format("%d/%d", scoreData.general.currentunits, scoreData.general.currentcap))
            else
                self._unitCap:SetText("")
            end
        end
    end
}
local animationSpeed = 300

local expandAnimation = animationFactory
    :OnStart(function(control, state, target)
        state = state or {}
        state.target = target
        return state
    end)
    :OnFrame(function(control, delta, state)

        if control.Top() > state.target.Bottom() then
            return true
        end
        control.Top:Set(control.Top() + delta * animationSpeed)
    end)
    :OnFinish(function(control, state)
        control.Top:Set(state.target.Bottom)
        control:EnableHitTest(true)
    end)
    :Create()

local contractAnimation = animationFactory
    :OnStart(function(control, state, target)
        state = state or {}
        state.target = target
        return state
    end)
    :OnFrame(function(control, delta, state)
        if control.Top() < state.target.Top() then
            return true
        end
        control.Top:Set(control.Top() - delta * animationSpeed)
    end)
    :OnFinish(function(control, state)
        control.Top:Set(state.target.Top)
        control:DisableHitTest(true)
    end)
    :Create()

local appearAnimation = alphaAnimationFactory
    :StartWith(0)
    :ToAppear()
    :For(0.3)
    :EndWith(1)
    :ApplyToChildren()
    :Create(alphaAnimator)

local fadeAnimation = alphaAnimationFactory
    :StartWith(1)
    :ToFade()
    :For(0.3)
    :EndWith(0)
    :ApplyToChildren()
    :Create(alphaAnimator)


TitlePanel = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        self._bg  = Bitmap(self)
        self._top = TopInfoPanel(self)

        self._info = InfoPanel(self)
        self._info:Setup()

        self._arrow = Text(self)
        self._arrow.state = true
        self._arrow:SetText("^")
        self._arrow.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                if control.state then
                    contractAnimation:Apply(self._info, self._top)
                    fadeAnimation:Apply(self._info)
                    control:SetText("v")
                else
                    expandAnimation:Apply(self._info, self._top)
                    appearAnimation:Apply(self._info)
                    control:SetText("^")
                end
                control.state = not control.state
                return true
            end
        end
        self._arrow:SetFont("Arial", 16)

    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)


        LayoutFor(self._bg)
            :Fill(self)
            :Color(bgColor)
            :DisableHitTest()

        LayoutFor(self._top)
            :AtRightTopIn(self)

        LayoutFor(self._info)
            :Top(self._top.Bottom)
            :Right(self.Right)

        LayoutFor(self._arrow)
            :AtRightTopIn(self._top, 2, 2)
            :Over(self._top)

        LayoutFor(self)
            :Width(titlePanelWidth)
            :Bottom(self._info.Bottom)
    end,

    SetQuality = function(self, quality)
        self._top:SetQuality(quality)
    end,

    Update = function(self, data, gameSpeed)
        self._top:Update(data, gameSpeed)
    end
}
