local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutFor = LayoutHelpers.ReusedLayoutFor

local Animator = import("../Animations/Animator.lua")
local animationFactory = import("../Animations/AnimationFactory.lua").GetAnimationFactory()
local alphaAnimationFactory = import("../Animations/AnimationFactory.lua").GetAlphaAnimationFactory()
local Utils = import("../Utils.lua")
local FormatNumber = Utils.FormatNumber
local Border = import("Border.lua").Border
local ShareManager = import("../ShareManager.lua")


local bgColor = UIUtil.disabledColor
local bgColor = 'ff000000'

local armyViewTextPointSize = 12

local armyViewTextFont = "Zeroes Three"

local armyViewWidth = 250
local allyViewWidth = 350

local armyViewHeight = 20

local animationSpeed = 250

local slideForward = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        if control.Right() <= control.parent.Right() then
            return true
        end
        control.Right:Set(control.Right() - delta * animationSpeed)
    end)
    :OnFinish(function(control)
        control.Right:Set(control.parent.Right)
    end)
    :Create()

local slideBackWards = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        if control.parent.Right() < control._energyBtn.Left() then
            return true
        end
        control.Right:Set(control.Right() + delta * animationSpeed)
    end)
    :OnFinish(function(control)
        local offset = math.floor(control.Right() - control._massBtn.Left())
        control.Right:Set(function() return control.parent.Right() + offset end)
    end)
    :Create()


ArmyView = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent

        self.id = -1

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
            :Alpha(0.4)
            :DisableHitTest()


        LayoutFor(self._color)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :Right(self.Left)
            :Alpha(0.9)
            :Width(3)
            :DisableHitTest()

        LayoutFor(self._faction)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, 5)
            :Over(self, 5)
            :DisableHitTest()

        LayoutFor(self._border)
            :Fill(self._faction)
            :Alpha(0.5)
            :DisableHitTest(true)
        --:FillFixedBorder(self._faction, 1)


        LayoutFor(self._rating)
            :AtVerticalCenterIn(self)
            :Right(function() return self.Left() + 60 end)
            :DisableHitTest()

        LayoutFor(self._name)
            :AtVerticalCenterIn(self)
            :RightOf(self._rating, 7)
            :DisableHitTest()

        LayoutFor(self)
            :Width(armyViewWidth)
            :Height(armyViewHeight)

    end,

    SetStaticData = function(self, armyId, name, rating, faction, armyColor, teamColor)
        self.id = armyId

        self._color:SetSolidColor(armyColor)

        self._border:SetColor(teamColor)
        -- self._border._leftBitmap:Hide()
        -- self._border._rightBitmap:Hide()
        self._border:Hide()

        self._rating:SetColor(teamColor)
        self._rating:SetText(rating)
        self._rating:SetFont(armyViewTextFont, armyViewTextPointSize)

        self._name:SetText(name)
        self._name:SetFont(armyViewTextFont, armyViewTextPointSize)

        self._faction:SetTexture(UIUtil.UIFile(Utils.GetSmallFactionIcon(faction)), 0)
    end,

    Update = function(self, data)

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

        self._unitsBtn = Bitmap(self)

        self._mass:SetText("0")
        self._energy:SetText("0")


        self._massBtn.HandleEvent = function(control, event)
            if event.Type == "ButtonPress" then
                if event.Modifiers.Left then
                    ShareManager.GiveMassToPlayer(self.id)
                elseif event.Modifiers.Right then
                    ShareManager.RequestMassFromPlayer(self.id)
                else

                end
                return true
            end
        end
        self._energyBtn.HandleEvent = function(control, event)
            if event.Type == "ButtonPress" then
                if event.Modifiers.Left then
                    ShareManager.GiveEnergyToPlayer(self.id)
                elseif event.Modifiers.Right then
                    ShareManager.RequestEnergyFromPlayer(self.id)
                else
                end
                return true
            end
        end
        self._unitsBtn.HandleEvent = function(control, event)
            if event.Type == "ButtonPress" then
                if event.Modifiers.Left then
                    ShareManager.GiveUnitsToPlayer(self.id)
                elseif event.Modifiers.Right then
                    ShareManager.RequestUnitFromPlayer(self.id)
                else
                end
                return true
            end

        end
    end,

    _Layout = function(self)
        ArmyView._Layout(self)

        LayoutFor(self._unitsBtn)
            :AtRightIn(self, 5)
            :AtVerticalCenterIn(self)
            :Texture(UIUtil.UIFile('/textures/ui/icons_strategic/commander_generic.dds'))
            :Width(14)
            :Height(14)
            :Over(self, 5)
            :EnableHitTest()

        LayoutFor(self._energyBtn)
            :LeftOf(self._unitsBtn, 5)
            :AtVerticalCenterIn(self)
            :Texture(UIUtil.UIFile('/game/build-ui/icon-energy_bmp.dds'))
            :Width(14)
            :Height(14)
            :Over(self, 5)
            :EnableHitTest()


        LayoutFor(self._massBtn)
            :LeftOf(self._energyBtn, 5)
            :AtVerticalCenterIn(self)
            :Texture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
            :Width(14)
            :Height(14)
            :Over(self, 5)
            :EnableHitTest()

        LayoutFor(self._energy)
            :LeftOf(self._massBtn, 10)
            :AtVerticalCenterIn(self)
            :Color('fff7c70f')
            :DisableHitTest()
        self._energy:SetFont(armyViewTextFont, armyViewTextPointSize)



        LayoutFor(self._mass)
            :LeftOf(self._massBtn, 45)
            :AtVerticalCenterIn(self)
            :Color('ffb7e75f')
            :DisableHitTest()
        self._mass:SetFont(armyViewTextFont, armyViewTextPointSize)


        LayoutFor(self)
            :Width(allyViewWidth)
            :Height(armyViewHeight)
            :EnableHitTest()


    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            slideBackWards:Apply(self)
            return true
        elseif event.Type == 'MouseEnter' then
            slideForward:Apply(self)
            return true
        end

        return false
    end,

    Update = function(self, data)
        if self.id == GetFocusArmy() then
            -- self._energy:Hide()
            -- self._mass:Hide()

        else
        end
        if data then
            self._energy:SetText(FormatNumber(data.energyin.rate * 10))
            self._mass:SetText(FormatNumber(data.massin.rate * 10))

        else
            self._energy:SetText("")
            self._mass:SetText("")
        end

    end



}
