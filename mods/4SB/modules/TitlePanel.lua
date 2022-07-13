local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutFor = LayoutHelpers.ReusedLayoutFor

local timeTextFont = "Zeroes Three"
local timeTextSize = 12

local qualityTextFont = timeTextFont
local qualityTextSize = 12

local unitCapTextFont = timeTextFont
local unitCapTextSize = 12

local titlePanelWidth = 300
local titlePanelHeight = 20

local bgColor = "ff000000"

TitlePanel = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self._gameSpeed = 0


        self._bg = Bitmap(self)
        self._time = Text(self)
        self._speed = Text(self)
        self._quality = Text(self)
        self._unitCap = Text(self)

    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)

        LayoutFor(self._bg)
            :Fill(self)
            :Color(bgColor)
            :Alpha(0.4)
            :DisableHitTest()

        LayoutFor(self._time)
            :AtLeftIn(self, 10)
            :AtVerticalCenterIn(self)
            :DisableHitTest()
        self._time:SetFont(timeTextFont, timeTextSize)


        LayoutFor(self._speed)
            :AtCenterIn(self, 0, -30)
            :DisableHitTest()
        self._speed:SetFont(qualityTextFont, qualityTextSize)

        LayoutFor(self._quality)
            :AtCenterIn(self, 0, 30)
            :DisableHitTest()
        self._quality:SetFont(qualityTextFont, qualityTextSize)

        LayoutFor(self._unitCap)
            :AtRightIn(self, 10)
            :AtVerticalCenterIn(self)
            :DisableHitTest()
        self._unitCap:SetFont(unitCapTextFont, unitCapTextSize)

        LayoutFor(self)
            :Width(titlePanelWidth)
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
