local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local LayoutFor = UMT.Layouter.ReusedLayoutFor
local ArmyViews = import("../ArmyView.lua")
local Animations = import("../Animations.lua")
local VerticalCollapseArrow = import("../Views/CollapseArrow.lua").VerticalCollapseArrow
local contractAnimation = Animations.contractAnimation
local expandAnimation = Animations.expandAnimation

local animationSpeed = 500


local slideAnimation = UMT.Animation.Factory.Base
    :OnStart(function(control)
        local width = control.Width()
        LayoutFor(control)
            :Right(function() return GetFrame(0).Right() + width end)
    end)
    :OnFrame(function(control, delta)
        return control.Right() < GetFrame(0).Right() - LayoutHelpers.ScaleNumber(25) or
            control.Right:Set(control.Right() - delta * animationSpeed)
    end)
    :OnFinish(function(control)
        LayoutFor(control)
            :AtRightIn(GetFrame(0), 25)
        LOG("Animation done")
    end)
    :Create()


---A clear function for additional layout
---@param scoreboard ScoreBoard
local Clear = function(scoreboard)
    scoreboard._border:Destroy()
    scoreboard._border = nil

    scoreboard._bracket:Destroy()
    scoreboard._bracket = nil

    scoreboard._arrow:Destroy()
    scoreboard._arrow = nil

    if scoreboard._title then
        LayoutFor(scoreboard._title)
            :Width(300)
    end

    for i, armyView in scoreboard:GetArmyViews() do
        LayoutFor(armyView)
            :Width(armyView.isAlly and ArmyViews.allyViewWidth or ArmyViews.armyViewWidth)
    end
end

---inital animation for scoreboard
---@param scoreboard ReplayScoreBoard
local InitialAnimation = function(scoreboard)
    slideAnimation:Apply(scoreboard)
end

---A layout function for scoreboard
---@param scoreboard ReplayScoreBoard
---@return fun(scoreboard : ReplayScoreBoard)
Layout = function(scoreboard)

    scoreboard:_Layout()
    scoreboard.InitialAnimation = InitialAnimation

    scoreboard._bracket = UMT.Views.FactionRightBracket(scoreboard)
    scoreboard._border = UMT.Views.GlowBorder(scoreboard)


    scoreboard._arrow = VerticalCollapseArrow(scoreboard)

    LayoutFor(scoreboard._arrow)
        :AtTopIn(scoreboard, 10)
        :AtRightIn(GetFrame(0), -3)
        :Over(scoreboard, 20)

    scoreboard._arrow.OnCheck = function(arrow, checked)
        if not checked then
            expandAnimation:Apply(scoreboard, animationSpeed, 25)
        else
            contractAnimation:Apply(scoreboard, animationSpeed, 25)
        end

    end


    LayoutFor(scoreboard._bracket)
        :AtTopIn(scoreboard, -13)
        :AtBottomIn(scoreboard, -13)
        :AtRightIn(scoreboard, -26)
        :Over(scoreboard, 10)


    LayoutFor(scoreboard._border)
        :FillFixedBorder(scoreboard, -10)
        :AtLeftIn(scoreboard, -11)
        :Over(scoreboard)
        :DisableHitTest(true)

    LayoutFor(scoreboard)
        :AtRightIn(GetFrame(0), 25)
        :Width(ArmyViews.allyViewWidth)

    if scoreboard._title then
        LayoutFor(scoreboard._title)
            :Width(scoreboard.Width)
    end

    for i, armyView in scoreboard:GetArmyViews() do
        LayoutFor(armyView)
            :Width(ArmyViews.allyViewWidth)
    end





    return Clear
end