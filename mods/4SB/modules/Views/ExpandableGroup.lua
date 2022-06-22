local Group = import('/lua/maui/group.lua').Group

local animationFactory = import("../Animations/AnimationFactory.lua").GetAnimationFactory()
local alphaAnimationFactory = import("../Animations/AnimationFactory.lua").GetAlphaAnimationFactory()

local animationSpeed = 300

local expandAnimation = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)

    end)
    :OnFinish(function(control)

    end)


local contractAnimation = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)

    end)
    :OnFinish(function(control)

    end)




ExpandableGroup = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self._controls = {}
        self._current = 1
    end,

    AddControls = function(self, controls, default)

    end,

    ClearControls = function(self)

    end,

    Expand = function(self)

    end,

    Contract = function(self)

    end


}
