local Group = UMT.Controls.Group
local Bitmap = UMT.Controls.Bitmap
local Text = UMT.Controls.Text
local UIUtil = import('/lua/ui/uiutil.lua')
local InfoPanel = import("InfoPanel.lua").InfoPanel
local Options = import("Options.lua")


local LayoutFor = UMT.Layouter.ReusedLayoutFor
local alphaAnimator = UMT.Animation.Animator(GetFrame(0))
local animationFactory = UMT.Animation.Factory.Base
local alphaAnimationFactory = UMT.Animation.Factory.Alpha

local timeTextSize = 12
local qualityTextSize = 12
local unitCapTextSize = 12


local titlePanelWidth = 300
local titlePanelHeight = 20

local bgColor = Options.player.color.bg:Raw()

local function Split(pString, pPattern)
    local t = {}
    local fpat = "(.-)" .. pPattern
    local last_end = 1
    local s, e, cap = pString:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t, cap)
        end
        last_end = e + 1
        s, e, cap = pString:find(fpat, last_end)
    end
    if last_end <= string.len(pString) then
        cap = pString:sub(last_end)
        table.insert(t, cap)
    end
    return t
end

---@class Timer
---@field seconds number
---@field minutes number
---@field hours number
local Timer = Class()
{

    ---@param self Timer
    __init = function(self)
        self.seconds = 0
        self.minutes = 0
        self.hours = 0
    end,

    Set = function(self, hours, minutes, seconds)
        self.seconds = seconds
        self.minutes = minutes
        self.hours = hours
    end,

    ---@param self Timer
    ---@return string
    Format = function(self)
        return ("%02d:%02d:%02d"):format(self.hours, self.minutes, self.seconds)
    end,

    ---@param self Timer
    ---@return number
    ToSeconds = function(self)
        return (self.hours * 60 + self.minutes) * 60 + self.seconds
    end,

    ---@param self Timer
    ---@param seconds number
    ---@return boolean
    HasPassed = function(self, seconds)
        return self:ToSeconds() < seconds
    end,

    ---@param self Timer
    ---@param s string
    ---@return boolean
    ParseString = function(self, s)
        local splitS = Split(s, ':')
        if table.getn(splitS) ~= 3 then
            return false
        end
        self:Set(tonumber(splitS[1]), tonumber(splitS[2]), tonumber(splitS[3]))
        return true
    end
}

---@class TopInfoPanel : UMT.Group
---@field _timer Timer
local TopInfoPanel = UMT.Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self._gameSpeed = 0
        self._timer = nil

        self._time = Text(self)
        self._speed = Text(self)
        self._quality = Text(self)
        self._unitCap = Text(self)
    end,

    __post_init = function(self)
        self:Layout()
    end,

    ---@param self TopInfoPanel
    ---@param layouter UMT.Layouter
    _Layout = function(self, layouter)
        local parent = self:GetParent()
        layouter(self._time)
            :AtLeftIn(self, 10)
            :AtVerticalCenterIn(self)
            :Color(Options.title.color.time:Raw())
            :DisableHitTest()
        self._time:SetFont(Options.title.font.time:Raw(), timeTextSize)
        if SessionIsReplay() then
            self._time:EnableHitTest()
            self._time.HandleEvent = function(_, event)
                if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                    local dialog = UIUtil.CreateInputDialog(GetFrame(0), LOC("Enter time HH:MM:SS"),
                        function(_, newtime)
                            self._timer = Timer()
                            if not self._timer:ParseString(newtime) then
                                print("Invalid time passed!")
                                return
                            end
                            print(("Timer set to %s"):format(self._timer:Format()))
                        end
                    )
                    if self._timer then
                        dialog.inputBox:SetText(self._timer:Format())
                    end
                    return true
                end
            end
        end

        layouter(self._speed)
            :AtCenterIn(self, 0, -30)
            :Color(Options.title.color.gameSpeed:Raw())
            :DisableHitTest()
        self._speed:SetFont(Options.title.font.gameSpeed:Raw(), qualityTextSize)

        layouter(self._quality)
            :AtCenterIn(self, 0, 30)
            :Color(Options.title.color.quality:Raw())
            :DisableHitTest()
        self._quality:SetFont(Options.title.font.quality:Raw(), qualityTextSize)

        layouter(self._unitCap)
            :AtRightIn(self, 10)
            :AtVerticalCenterIn(self)
            :Color(Options.title.color.totalUnits:Raw())
            :DisableHitTest()
        self._unitCap:SetFont(Options.title.font.totalUnits:Raw(), unitCapTextSize)

        layouter(self)
            :Width(parent.Width)
            :Height(titlePanelHeight)
    end,

    SetQuality = function(self, quality)
        if quality then
            self._quality:SetText(("Q:%.2f%%"):format(quality))
        else
            self._quality:SetText("")
        end
    end,

    ---@param self TopInfoPanel
    ---@param data any
    ---@param gameSpeed any
    Update = function(self, data, gameSpeed)
        if gameSpeed then
            self._gameSpeed = gameSpeed
        end

        self._speed:SetText(("%+d / %+d"):format(self._gameSpeed, GetSimRate()))
        self._time:SetText(GetGameTime())

        if self._timer then
            local curSeconds = GameTick() / 10
            if self._timer:HasPassed(curSeconds) then
                self._timer = nil
                SessionRequestPause()
            end
        end

        if not data then return end

        local scoreData = data[GetFocusArmy()]
        if scoreData.general.currentcap then
            self._unitCap:SetText(("%d/%d"):format(scoreData.general.currentunits, scoreData.general.currentcap))
        else
            self._unitCap:SetText("")
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

---@class TitlePanel : UMT.Group
---@field _bg Bitmap
---@field _top TopInfoPanel
---@field _info InfoPanel
---@field _expanded boolean
TitlePanel = UMT.Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        self._bg  = Bitmap(self)
        self._top = TopInfoPanel(self)

        self._info = InfoPanel(self)
        self._info:Setup()

        self._expanded = true
    end,

    __post_init = function(self)
        self:Layout()
    end,

    _Layout = function(self, layouter)

        layouter(self._bg)
            :Fill(self)
            :Color(bgColor)
            :DisableHitTest()

        layouter(self._top)
            :AtRightTopIn(self)

        layouter(self._info)
            :Top(self._top.Bottom)
            :Right(self.Right)

        layouter(self)
            :Width(titlePanelWidth)
            :Bottom(self._info.Bottom)
    end,

    SetQuality = function(self, quality)
        self._top:SetQuality(quality)
    end,

    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            if self._expanded then
                contractAnimation:Apply(self._info, self._top)
                fadeAnimation:Apply(self._info)
            else
                expandAnimation:Apply(self._info, self._top)
                appearAnimation:Apply(self._info)
            end
            self._expanded = not self._expanded
            return true
        end
    end,

    Update = function(self, data, gameSpeed)
        self._top:Update(data, gameSpeed)
    end
}
