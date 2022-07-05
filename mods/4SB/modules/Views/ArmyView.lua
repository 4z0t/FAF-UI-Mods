local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutFor = LayoutHelpers.ReusedLayoutFor

local animationFactory = import("../Animations/AnimationFactory.lua").GetAnimationFactory()
local alphaAnimationFactory = import("../Animations/AnimationFactory.lua").GetAlphaAnimationFactory()
local Utils = import("../Utils.lua")

local Border = import("Border.lua").Border

local bgColor = UIUtil.disabledColor

local armyViewTextPointSize = 12

local armyViewTextFont = "Zeroes Three"

local armyViewWidth = 250
local allyViewWidth = 300

local armyViewHeight = 20


ArmyView = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        self.parent = parent

        self._bg = Bitmap(self)

        self._border = Border(self)

        self._color = Bitmap(self)
        self._faction = Bitmap(self)
        self._rating = Text(self)
        self._name = Text(self)







    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)

        LayoutFor(self._bg)
            :Fill(self)
            :Color(bgColor)
            :Alpha(0.2)


        LayoutFor(self._color)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :Right(self.Left)
            :Alpha(0.7)
            :Width(2)

        LayoutFor(self._faction)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, 5)
            :Over(self, 5)

        LayoutFor(self._border)
            :Fill(self._faction)
            :Alpha(0.75)
            :DisableHitTest(true)
        --:FillFixedBorder(self._faction, 1)


        LayoutFor(self._rating)
            :AtVerticalCenterIn(self)
            :Right(function() return self.Left() + 50 end)

        LayoutFor(self._name)
            :AtVerticalCenterIn(self)
            :RightOf(self._rating, 10)


        LayoutFor(self)
            :Width(armyViewWidth)
            :Height(armyViewHeight)

    end,

    SetStaticData = function(self, armyId, name, rating, faction, armyColor, teamColor)
        self._id = armyId

        self._color:SetSolidColor(teamColor)

        self._border:SetColor(armyColor)
        -- self._border._leftBitmap:Hide()
        -- self._border._rightBitmap:Hide()

        --self._rating:SetColor(armyColor)
        self._rating:SetText(rating)
        self._rating:SetFont(armyViewTextFont, armyViewTextPointSize)

        self._name:SetText(name)
        self._name:SetFont(armyViewTextFont, armyViewTextPointSize)

        self._faction:SetTexture(UIUtil.UIFile(Utils.GetSmallFactionIcon(faction)), 0)
    end
}


AllyView = Class(ArmyView)
{
    __init = function(self, parent)
        ArmyView.__init(self, parent)

        self._mass = Text(self)
        self._energy = Text(self)

        self._massBtn = Bitmap(self)
        self._energyBtn = Bitmap(self)



    end,

    _Layout = function(self)
        ArmyView._Layout(self)
    end,
}
