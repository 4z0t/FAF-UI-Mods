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
---@return fun(scoreboard : ReplayScoreBoard)
Layout = function(scoreboard)

    scoreboard:_Layout()
    scoreboard.InitialAnimation = InitialAnimation

    scoreboard._bracket = UMT.Views.FactionRightBracket(scoreboard)
    scoreboard._border = UMT.Views.GlowBorder(scoreboard)
    scoreboard._arrow = UMT.Views.VerticalCollapseArrow(scoreboard)

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
        :Over(scoreboard)
        :DisableHitTest(true)

    LayoutFor(scoreboard._dataPanel)
        :Width(scoreboard.Width)
    if scoreboard._title then
        LayoutFor(scoreboard._title)
            :Width(scoreboard.Width)
    end
    LayoutFor(scoreboard)
        :AtRightIn(GetFrame(0), 25)



    return Clear
end
