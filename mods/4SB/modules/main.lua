local Group = import('/lua/maui/group.lua').Group
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Entry = import("Views/Entry.lua").Entry


local Animator = import("Animations/Animator.lua")
local AnimationFactory = import("Animations/AnimationFactory.lua")
local SequentialAnimation = import("Animations/SequentialAnimation.lua").SequentialAnimation

local controls

local slideBackWards = AnimationFactory.GetAnimationFactory()
    :OnStart()
    :OnFrame(function(control, delta)
        if control.Right() - control.parent.Right() > 50 then
            return true
        end
        control.Right:Set(control.Right() + delta * 500)
    end)
    :OnFinish(function(control)
        LayoutHelpers.AtRightIn(control, control.parent, -50)
    end)
    :Create()

local colors = {
    "ff" .. "FF0000",
    "ff" .. "FF7F00",
    "ff" .. "FFFF00",
    "ff" .. "00FF00",
    "ff" .. "0000FF",
    "ff" .. "4B0082",
    "ff" .. "9400D3",
}

function Main(isReplay)

    controls = Group(GetFrame(0))
    controls.Depth:Set(1000)
    LayoutHelpers.SetDimensions(controls, 200, 220)
    LayoutHelpers.AtLeftTopIn(controls, GetFrame(0), 200, 200)
    controls.entries = {}
    for i = 1, 7 do
        controls.entries[i] = Entry(controls)

        controls.entries[i]._bg:SetSolidColor(colors[i])

        if i == 1 then

            LayoutHelpers.AtRightTopIn(controls.entries[i], controls)

        else
            LayoutHelpers.AnchorToBottom(controls.entries[i], controls.entries[i - 1], 2)
            LayoutHelpers.AtRightIn(controls.entries[i], controls)
        end
    end
    local sa = SequentialAnimation(slideBackWards, 0.1, 1)
    sa:Apply(controls.entries)




end
