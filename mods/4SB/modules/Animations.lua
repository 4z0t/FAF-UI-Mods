local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local LayoutFor = UMT.Layouter.ReusedLayoutFor


contractAnimation = UMT.Animation.Factory.Base
    :OnStart(function(control, state, speed, offset)
        PlaySound(Sound { Cue = "UI_Score_Window_Close", Bank = "Interface" })
        return { speed = LayoutHelpers.ScaleNumber(speed), offset = offset }
    end)
    :OnFrame(function(control, delta, state)
        return control.Left() > GetFrame(0).Right() + LayoutHelpers.ScaleNumber(state.offset) or
            control.Right:Set(control.Right() + delta * state.speed)
    end)
    :OnFinish(function(control, state)
        local width = control.Width()
        LayoutFor(control)
            :Right(function() return GetFrame(0).Right() + width + LayoutHelpers.ScaleNumber(state.offset) end)
    end)
    :Create()

expandAnimation = UMT.Animation.Factory.Base
    :OnStart(function(control, state, speed, offset)
        PlaySound(Sound { Cue = "UI_Score_Window_Open", Bank = "Interface" })
        return { speed = LayoutHelpers.ScaleNumber(speed), offset = offset }
    end)
    :OnFrame(function(control, delta, state)
        return control.Right() < GetFrame(0).Right() - LayoutHelpers.ScaleNumber(state.offset) or
            control.Right:Set(control.Right() - delta * state.speed)
    end)
    :OnFinish(function(control, state)
        LayoutFor(control)
            :AtRightIn(GetFrame(0), state.offset)
    end)
    :Create()
