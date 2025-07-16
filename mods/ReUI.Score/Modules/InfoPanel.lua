--#region Header
--#region Upvalues

--#endregion

--#region Base Lua imports
local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')

--#endregion

--#region ReUI modules / classes
local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap
local Text = ReUI.UI.Controls.Text

--#endregion

--#region Local Modules

--#endregion

--#region Local Variables
local options = ReUI.Options.Mods["ReUI.Score"]

local textSize = 12
local panelWidth = 300
local panelHeight = 20

--#endregion
--#endregion

---Returns size in KM
---@param size number
---@return number
local function GetSizeInKM(size)
    return size / 512 * 10
end

---Formats map name, returns name and true if map is generated
---@param name string
---@return string
---@return boolean
local function FormatMapName(name)
    if name:find "neroxis_map_generator" then
        return "Neroxis Map Generator", true
    end
    return name, false
end

---@class InfoPanel : ReUI.UI.Controls.Group
---@field _mapName ReUI.UI.Controls.Text
---@field _mapSize ReUI.UI.Controls.Text
InfoPanel = ReUI.Core.Class(Group)
{
    ---@param self InfoPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self._mapName = Text(self)
        self._mapSize = Text(self)
    end,

    ---@param self InfoPanel
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        local parent = self:GetParent()

        self._mapName:SetFont(options.title.font.mapName:Raw(), textSize)
        layouter(self._mapName)
            :AtCenterIn(self)

        self._mapSize:SetFont(options.title.font.mapSize:Raw(), textSize)
        layouter(self._mapSize)
            :AtVerticalCenterIn(self)
            :AtRightIn(self, 10)
            :DisableHitTest()

        layouter(self)
            :Width(parent.Width)
            :Height(panelHeight)
            :DisableHitTest()
    end,

    ---@param self InfoPanel
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
