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

    scoreboard._bracket = UMT.Views.FactionRightBracket(scoreboard)



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

    do -- border layout

        local leftTop = scoreboard._lines[1].Left
        local leftBottom = scoreboard._lines[scoreboard._lines | UMT.LuaQ.count].Left
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


        LayoutFor(scoreboard._border.br)
            :AnchorToLeft(scoreboard._border, offset + 3)
            :AtBottomIn(scoreboard._border, -10)



        LayoutFor(scoreboard._border.r)
            :AnchorToLeft(scoreboard._border, offset + 5)
            :Top(scoreboard._border.tr.Bottom)
            :Bottom(scoreboard._border.br.Top)


        LayoutFor(scoreboard._border.t)
            :AtTopIn(scoreboard._border.tr, 1)
            :Right(scoreboard._border.tr.Left)
            :Left(leftTop)

        LayoutFor(scoreboard._border.b)
            :AtBottomIn(scoreboard._border.br, 1)
            :Right(scoreboard._border.br.Left)
            :Left(leftBottom)



    end

    LayoutFor(scoreboard._bracket)
        :AtTopIn(scoreboard, -15)
        :AtBottomIn(scoreboard, -15)
        :AtRightIn(scoreboard, -21)
        :Over(scoreboard, 10)

    LayoutFor(scoreboard)
        :AtRightIn(GetFrame(0), 20)


    return Clear
end