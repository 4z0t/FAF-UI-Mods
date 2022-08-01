local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local ExpandableSelectionGroup = import("Views/ExpandableSelectionGroup.lua").ExpandableSelectionGroup


local CheckBoxDropDown = Class(ExpandableSelectionGroup)
{

}

local LayoutFor = LayoutHelpers.ReusedLayoutFor

local textFont = "Zeroes Three"
local textSize = 12


local panelWidth = 300
local panelHeight = 20

local bgColor = "ff000000"

DataPanel = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        self._bg = Bitmap(self)
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

    

        LayoutFor(self)
            :Width(panelWidth)
            :Height(panelHeight)
    end,
}
