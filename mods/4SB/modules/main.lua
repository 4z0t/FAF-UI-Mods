local Group = import('/lua/maui/group.lua').Group
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Entry = import("Views/Entry.lua").Entry


local Animator = import("Animations/Animator.lua")
local AnimationFactory = import("Animations/AnimationFactory.lua")

local controls


function Main(isReplay)

    controls = Group(GetFrame(0))
    controls.Depth:Set(1000)
    LayoutHelpers.SetDimensions(controls, 200, 220)
    LayoutHelpers.AtLeftTopIn(controls, GetFrame(0), 200, 200)
    controls.entries = {}
    for i = 1, 10 do
        controls.entries[i] = Entry(controls)
        if i == 1 then

            LayoutHelpers.AtRightTopIn(controls.entries[i], controls)
        else
            LayoutHelpers.AnchorToBottom(controls.entries[i], controls.entries[i - 1], 2)
            LayoutHelpers.AtRightIn(controls.entries[i], controls)
        end
    end




end
