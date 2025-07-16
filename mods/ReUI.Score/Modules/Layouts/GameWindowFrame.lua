local ArmyViews = import("../ArmyView.lua")
local Animations = import("../Animations.lua")

local contractAnimation = Animations.contractAnimation
local expandAnimation = Animations.expandAnimation

local animationSpeed = 500


---A clear function for additional layout
---@param scoreboard ScoreBoard
---@param layouter UMT.Layouter
local Clear = function(scoreboard, layouter)
    scoreboard._border:Destroy()
    scoreboard._border = nil

    scoreboard._bracket:Destroy()
    scoreboard._bracket = nil

    scoreboard._arrow:Destroy()
    scoreboard._arrow = nil

    if scoreboard._title then
        layouter(scoreboard._title)
            :Width(300)
        scoreboard._title._bg:Show()
    end

    for i, armyView in scoreboard:GetArmyViews() do
        layouter(armyView)
            :Width(armyView.isAlly and ArmyViews.allyViewWidth or ArmyViews.armyViewWidth)
        armyView._bg:Show()
    end
end
---inital animation for scoreboard
---@param scoreboard ScoreBoard
local InitialAnimation = function(scoreboard)
    Animations.slideAnimation:Apply(scoreboard, animationSpeed, 25)
end



---A layout function for scoreboard
---@param scoreboard ScoreBoard
---@param layouter LayouterFunctor
---@return fun(scoreboard : ScoreBoard)
Layout = function(scoreboard, layouter)

    scoreboard:InitLayout(layouter)
    scoreboard.InitialAnimation = InitialAnimation

    scoreboard._bracket = ReUI.UI.Views.Brackets.FactionRight(scoreboard)
    scoreboard._border = ReUI.UI.Views.WindowFrame(scoreboard)
    scoreboard._arrow = ReUI.UI.Views.VerticalCollapseArrow(scoreboard)

    layouter(scoreboard._arrow)
        :AtTopIn(scoreboard, 10)
        :NoScale(function(_layouter)
            _layouter:AtRightIn(GetFrame(0), -3)
        end)
        :Over(scoreboard, 20)

    scoreboard._arrow.OnCheck = function(arrow, checked)
        if not checked then
            expandAnimation:Apply(scoreboard, animationSpeed, 25)
        else
            contractAnimation:Apply(scoreboard, animationSpeed, 25)
        end

    end


    layouter(scoreboard._bracket)
        :AtTopIn(scoreboard, -11)
        :AtBottomIn(scoreboard, -12)
        :AtRightIn(scoreboard, -27)
        :Over(scoreboard, 10)


    layouter(scoreboard._border)
        :FillFixedBorder(scoreboard, -7)
        :Over(scoreboard)
        :DisableHitTest(true)

    layouter(scoreboard)
        :AtRightIn(GetFrame(0), 25)
        :Width(ArmyViews.allyViewWidth)

    if scoreboard._title then
        layouter(scoreboard._title)
            :Width(scoreboard.Width)
        layouter(scoreboard._title._bg)
            :Hide()
    end

    for i, armyView in scoreboard:GetArmyViews() do
        layouter(armyView)
            :Width(ArmyViews.allyViewWidth)
        layouter(armyView._bg)
            :Hide()
    end



    return Clear
end
