local Group = import('/lua/maui/group.lua').Group
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import("/lua/maui/text.lua").Text
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local LayoutFor =import("/mods/UMT/modules/Layouter.lua").ReusedLayoutFor
local Tooltip = import('/lua/ui/game/tooltip.lua')



local textFont = "Zeroes Three"
local textSize = 12

local panelWidth = 300
local panelHeight = 20

local bgColor = "ff000000"



function GetSizeInKM(size)
    return math.ceil(size / 51.2 - 0.5)
end

local pattern = "neroxis_map_generator"
function FormatMapGenName(name)
    if string.find(name, pattern) then
        return "Neroxis Map Generator", true
    end
    return name, false
end

InfoPanel = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        self._mapName = Text(self)
        self._mapSize = Text(self)



    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)


        self._mapName:SetFont(textFont, textSize)
        LayoutFor(self._mapName)
            :AtCenterIn(self)


        self._mapSize:SetFont(textFont, textSize)
        LayoutFor(self._mapSize)
            :AtVerticalCenterIn(self)
            :AtRightIn(self, 10)
            :DisableHitTest()

        LayoutFor(self)
            :Width(panelWidth)
            :Height(panelHeight)
            :DisableHitTest()
    end,



    Setup = function(self)
        local sessionInfo = SessionGetScenarioInfo()
        local mapWidth = sessionInfo.size[1]
        local mapHeight = sessionInfo.size[2]
        local areaData = Sync.NewPlayableArea
        if areaData then
            mapWidth = areaData[3] - areaData[1]
            mapHeight = areaData[4] - areaData[2]
        end
        self._mapSize:SetText(string.format("%dx%d", GetSizeInKM(mapWidth), GetSizeInKM(mapHeight)))


        local mapName, isMapGen = FormatMapGenName(sessionInfo.name)
        local mapDescription = sessionInfo.description
        if not mapDescription or mapDescription == "" then
            mapDescription = "No description set by the author."
        end

        mapDescription = string.format(
            "%s\r\n\r\n%s: %s\r\n%s: %s",
            LOC(mapDescription),
            LOC("<LOC map_version>Map version"),
            tostring(sessionInfo.map_version),
            LOC("<LOC replay_id>Replay ID"),
            tostring(UIUtil.GetReplayId())
        )
        self._mapName:SetText(mapName)

        Tooltip.AddForcedControlTooltipManual(self._mapName, sessionInfo.name, mapDescription)
    end,

}
