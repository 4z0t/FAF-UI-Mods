local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group


local animationFactory = import("../Animations/AnimationFactory.lua").GetAnimationFactory()
local alphaAnimationFactory = import("../Animations/AnimationFactory.lua").GetAlphaAnimationFactory()

local animationSpeed = 300

local slideForward = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        if control.Right() < control.parent.Right() then
            return true
        end
        control.Right:Set(control.Right() - delta * animationSpeed)
    end)
    :OnFinish(function(control)
        control.Right:Set(control.parent.Right)
    end)
    :Create()

local slideBackWards = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        if control.Right() - control.parent.Right() > 50 then
            return true
        end
        control.Right:Set(control.Right() + delta * animationSpeed)
    end)
    :OnFinish(function(control)
        LayoutHelpers.AtRightIn(control, control.parent, -50)
    end)
    :Create()

local appearAnimation = alphaAnimationFactory
    :StartWith(0.1)
    :ToAppear()
    :For(1)
    :EndWith(1)
    :Create()

local fadeAnimation = alphaAnimationFactory
    :StartWith(1)
    :ToFade()
    :For(1)
    :EndWith(0.1)
    :Create()

Entry = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent
        self._speed = 300
        self._bg = Bitmap(self)
        self._bg:SetSolidColor("ff000000")
        LayoutHelpers.FillParent(self._bg, self)
        LayoutHelpers.SetDimensions(self, 100, 20)
    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            slideBackWards:Apply(self)
            fadeAnimation:Apply(self._bg)
            return true
        elseif event.Type == 'MouseEnter' then
            slideForward:Apply(self)
            appearAnimation:Apply(self._bg)
            return true
        end
        return false
    end,
}