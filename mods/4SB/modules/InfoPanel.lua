local Group = UMT.Controls.Group
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = UMT.Controls.Bitmap
local Text = UMT.Controls.Text
local Tooltip = import('/lua/ui/game/tooltip.lua')

local Options = import("Options.lua")

local LayoutFor = UMT.Layouter.ReusedLayoutFor

local textSize = 12

local panelWidth = 300
local panelHeight = 20

---Retuns size in KM
---@param size number
---@return number
function GetSizeInKM(size)
    return size / 512 * 10
end

---Formats map name, returns name and true if map is generated
---@param name string
---@return string
---@return boolean
function FormatMapName(name)
    if name:find "neroxis_map_generator" then
        return "Neroxis Map Generator", true
    end
    return name, false
end

---@class InfoPanel : UMT.Group
InfoPanel = UMT.Class(Group)
{
    ---@param self InfoPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self._mapName = Text(self)
        self._mapSize = Text(self)
    end,

    __post_init = function(self)
        self:Layout()
    end,

    ---@param self InfoPanel
    ---@param layouter UMT.Layouter
    _Layout = function(self, layouter)
        local parent = self:GetParent()

        self._mapName:SetFont(Options.title.font.mapName:Raw(), textSize)
        layouter(self._mapName)
            :AtCenterIn(self)


        self._mapSize:SetFont(Options.title.font.mapSize:Raw(), textSize)
        layouter(self._mapSize)
            :AtVerticalCenterIn(self)
            :AtRightIn(self, 10)
            :DisableHitTest()

        layouter(self)
            :Width(parent.Width)
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
        self._mapSize:SetText(("%.1f x %.1f"):format(GetSizeInKM(mapWidth), GetSizeInKM(mapHeight)))


        local mapName, isMapGen = FormatMapName(sessionInfo.name)
        local mapDescription = sessionInfo.description
        if not mapDescription or mapDescription == "" then
            mapDescription = "No description set by the author."
        end

        mapDescription = ("%s\r\n\r\n%s: %s\r\n%s: %s"):format(
            LOC(mapDescription),
            LOC "<LOC map_version>Map version",
            tostring(sessionInfo.map_version),
            LOC "<LOC replay_id>Replay ID",
            tostring(UIUtil.GetReplayId())
        )
        self._mapName:SetText(mapName)

        Tooltip.AddForcedControlTooltipManual(self._mapName, sessionInfo.name, mapDescription)
    end,

}
