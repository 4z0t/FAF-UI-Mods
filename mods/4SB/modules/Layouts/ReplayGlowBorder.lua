local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local LayoutFor = UMT.Layouter.ReusedLayoutFor



---A clear function for additional layout
---@param scoreboard ScoreBoard
local Clear = function(scoreboard)
    scoreboard._border:Destroy()
    scoreboard._border = nil

    scoreboard._bracket:Destroy()
    scoreboard._bracket = nil
end


---A layout function for scoreboard
---@param scoreboard ReplayScoreBoard
---@return fun(scoreboard : ReplayScoreBoard)
Layout = function(scoreboard)

    scoreboard:_Layout()


    scoreboard._bracket = Group(scoreboard)
    scoreboard._bracket.top = Bitmap(scoreboard._bracket, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_t.dds"))
    scoreboard._bracket.middle = Bitmap(scoreboard._bracket,
        UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_m.dds"))
    scoreboard._bracket.bottom = Bitmap(scoreboard._bracket,
        UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_b.dds"))





    do -- bracket layout
        local offset = -12
        LayoutFor(scoreboard._bracket)
            :Top(scoreboard.Top)
            :Left(scoreboard.Right)
            :Bottom(scoreboard.Bottom)
            :Width(0)
            :Over(scoreboard, 10)
            :DisableHitTest(true)

        LayoutFor(scoreboard._bracket.top)
            :AnchorToRight(scoreboard._bracket, offset + 3)
            :AtTopIn(scoreboard._bracket, -13)


        LayoutFor(scoreboard._bracket.bottom)
            :AnchorToRight(scoreboard._bracket, offset + 3)
            :AtBottomIn(scoreboard._bracket, -13)


        LayoutFor(scoreboard._bracket.middle)
            :AnchorToRight(scoreboard._bracket, offset + 12)
            :Top(scoreboard._bracket.top.Bottom)
            :Bottom(scoreboard._bracket.bottom.Top)

    end

    scoreboard._border = UMT.Views.GlowBorder(scoreboard)
    LayoutFor(scoreboard._border)
        :FillFixedBorder(scoreboard, -10)
        --:AtLeftIn(scoreboard, -7)
        :Over(scoreboard)
        :DisableHitTest(true)

    LayoutFor(scoreboard._dataPanel)
        :Width(scoreboard.Width)
    if scoreboard._title then
        LayoutFor(scoreboard._title)
            :Width(scoreboard.Width)
    end
    LayoutFor(scoreboard)
        :AtRightIn(GetFrame(0), 20)



    return Clear
end
