local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local LayoutFor = UMT.Layouter.ReusedLayoutFor



---A clear function for additional layout
---@param scoreboard ScoreBoard
local Clear = function(scoreboard)
    scoreboard._bracket:Destroy()
    scoreboard._bracket = nil

    scoreboard._border:Destroy()
    scoreboard._border = nil
end


---A layout function for scoreboard
---@param scoreboard ScoreBoard
---@return fun(scoreboard:ScoreBoard)
Layout = function(scoreboard)

    scoreboard:_Layout()

    scoreboard._bracket = Group(scoreboard)
    scoreboard._bracket.top = Bitmap(scoreboard._bracket, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_t.dds"))
    scoreboard._bracket.middle = Bitmap(scoreboard._bracket,
        UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_m.dds"))
    scoreboard._bracket.bottom = Bitmap(scoreboard._bracket,
        UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_b.dds"))



    scoreboard._border = Group(scoreboard)
    scoreboard._border.t = Bitmap(scoreboard._border,
        UIUtil.SkinnableFile("/game/mini-map-glow-brd/mini-map-glow_brd_horz_um.dds"))
    scoreboard._border.tr = Bitmap(scoreboard._border,
        UIUtil.SkinnableFile("/game/mini-map-glow-brd/mini-map-glow_brd_ur.dds"))
    scoreboard._border.r = Bitmap(scoreboard._border,
        UIUtil.SkinnableFile("/game/mini-map-glow-brd/mini-map-glow_brd_vert_r.dds"))
    scoreboard._border.br = Bitmap(scoreboard._border,
        UIUtil.SkinnableFile("/game/mini-map-glow-brd/mini-map-glow_brd_lr.dds"))
    scoreboard._border.b = Bitmap(scoreboard._border,
        UIUtil.SkinnableFile("/game/mini-map-glow-brd/mini-map-glow_brd_lm.dds"))


    local last
    local first
    for i, armyView in scoreboard._lines do
        if i == 1 then
            if scoreboard._title then
                LayoutFor(armyView)
                    :AnchorToBottom(scoreboard._title)
                    :Right(scoreboard.Right)
            else
                LayoutFor(armyView)
                    :AtRightTopIn(scoreboard)
            end
            first = armyView
        else
            LayoutFor(armyView)
                :AnchorToBottom(scoreboard._lines[i - 1])
                :Right(scoreboard.Right)
        end
        last = armyView
    end
    if last then
        scoreboard.Bottom:Set(last.Bottom)
    end

    do -- border layout

        local leftTop = first.Left
        local leftBottom = last.Left
        if scoreboard._title then
            leftTop = scoreboard._title.Left
        end

        local offset = -10
        LayoutFor(scoreboard._border)
            :Top(scoreboard.Top)
            :Left(scoreboard.Right)
            :Bottom(scoreboard.Bottom)
            :Width(0)
            :Over(scoreboard, 5)
            :DisableHitTest(true)

        LayoutFor(scoreboard._border.tr)
            :AnchorToLeft(scoreboard._border, offset + 3)
            :AtTopIn(scoreboard._border, -10)
            :Alpha(0.5)


        LayoutFor(scoreboard._border.br)
            :AnchorToLeft(scoreboard._border, offset + 3)
            :AtBottomIn(scoreboard._border, -10)
            :Alpha(0.5)


        LayoutFor(scoreboard._border.r)
            :AnchorToLeft(scoreboard._border, offset + 5)
            :Top(scoreboard._border.tr.Bottom)
            :Bottom(scoreboard._border.br.Top)
            :Alpha(0.5)


        LayoutFor(scoreboard._border.t)
            :AtTopIn(scoreboard._border.tr, 1)
            :Right(scoreboard._border.tr.Left)
            :Left(leftTop)
            :Alpha(0.5)

        LayoutFor(scoreboard._border.b)
            :AtBottomIn(scoreboard._border.br, 1)
            :Right(scoreboard._border.br.Left)
            :Left(leftBottom)
            :Alpha(0.5)



    end
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

    LayoutFor(scoreboard)
        :Width(100)
        :Over(GetFrame(0), 1000)
        :AtRightIn(GetFrame(0), 20)
        :DisableHitTest()
        :NeedsFrameUpdate(true)

    return Clear
end
