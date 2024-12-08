local LayoutFor = UMT.Layouter.ReusedLayoutFor
local Animations = import("../Animations.lua")

local contractAnimation = Animations.contractAnimation
local expandAnimation = Animations.expandAnimation

local animationSpeed = 500




---A clear function for additional layout
---@param scoreboard ScoreBoard
local Clear = function(scoreboard)
    scoreboard._border:Destroy()
    scoreboard._border = nil

    scoreboard._bracket:Destroy()
    scoreboard._bracket = nil

    scoreboard._arrow:Destroy()
    scoreboard._arrow = nil
end

---inital animation for scoreboard
---@param scoreboard ReplayScoreBoard
local InitialAnimation = function(scoreboard)
    Animations.slideAnimation:Apply(scoreboard, animationSpeed, 25)
end



---A layout function for scoreboard
---@param scoreboard ReplayScoreBoard
---@param layouter LayouterFunctor
---@return fun(scoreboard : ReplayScoreBoard)
Layout = function(scoreboard, layouter)

    scoreboard:InitLayout(layouter)
    scoreboard.InitialAnimation = InitialAnimation

    scoreboard._bracket = UMT.Views.FactionRightBracket(scoreboard)
    scoreboard._border = UMT.Views.GlowBorder(scoreboard)
    scoreboard._arrow = UMT.Views.VerticalCollapseArrow(scoreboard)

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
        :AtTopIn(scoreboard, -13)
        :AtBottomIn(scoreboard, -13)
        :AtRightIn(scoreboard, -26)
        :Over(scoreboard, 10)


    layouter(scoreboard._border)
        :FillFixedBorder(scoreboard, -10)
        :Over(scoreboard)
        :DisableHitTest(true)

    layouter(scoreboard._dataPanel)
        :Width(scoreboard.Width)
    if scoreboard._title then
        layouter(scoreboard._title)
            :Width(scoreboard.Width)
    end
    layouter(scoreboard)
        :AtRightIn(GetFrame(0), 25)



    return Clear
end
