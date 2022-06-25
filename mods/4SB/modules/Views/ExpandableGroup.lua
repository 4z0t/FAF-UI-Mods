local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')


local animationFactory = import("../Animations/AnimationFactory.lua").GetAnimationFactory()
local alphaAnimationFactory = import("../Animations/AnimationFactory.lua").GetAlphaAnimationFactory()

local expandSpeed = 1000

local expandAnimation = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        local n = table.getn(control._controls) + 1
        local height = control.Height()
        local expandHeight = control._expand.Height()
        if (control._animationIndex + 1) * height < expandHeight then
            control:OnExpandControl()
            control._animationIndex = control._animationIndex + 1
        end

        if n * height < expandHeight then
            return true
        end
        control._expand.Height:Set(expandHeight + delta * expandSpeed)
    end)
    :OnFinish(function(control)
        local n = table.getn(control._controls) + 1
        local height = control.Height()
        control._expand.Height:Set(n * height)
        control._isExpanded = true
    end)
    :Create()

local contractAnimation = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        local n = table.getn(control._controls)
        local height = control.Height()
        local expandHeight = control._expand.Height()
        if (control._animationIndex - 1) * height > expandHeight then
            control._animationIndex = control._animationIndex - 1
            control:OnContractControl()
        end

        if height > expandHeight then
            return true
        end
        control._expand.Height:Set(expandHeight - delta * expandSpeed)

    end)
    :OnFinish(function(control)
        local height = control.Height()
        control._expand.Height:Set(height)
        control._isExpanded = false
    end)
    :Create()

local duration = 0.05

local appearAnimation = alphaAnimationFactory
    :StartWith(0)
    :ToAppear()
    :For(duration)
    :EndWith(1)
    :ApplyToChildren()
    :OnStart(function(control)
        control:Show()
    end)
    :Create()

local fadeAnimation = alphaAnimationFactory
    :StartWith(1)
    :ToFade()
    :For(duration)
    :EndWith(0)
    :ApplyToChildren()
    :OnFinish(function(control)
        LayoutHelpers.AtCenterIn(control, control:GetParent())
        control:Hide()
    end)
    :Create()


ExpandableGroup = Class(Group)
{
    __init = function(self, parent, width, height)
        Group.__init(self, parent)
        LayoutHelpers.SetDimensions(self, width, height)
        self._expand = Group(self)
        LayoutHelpers.AtLeftTopIn(self._expand, self)
        LayoutHelpers.SetDimensions(self._expand, width, height)
        self._controls       = {}
        self._active         = false
        self._animationIndex = 1
        self._isExpanded     = false
    end,

    AddControls = function(self, controls, default)
        default = default or 1

        self._controls = {}
        for i, control in controls do
            LayoutHelpers.DepthOverParent(control, self, 5)
            if i == default then
                self._active = control
                control:Show()
            else
                table.insert(self._controls, control)
                control:Hide()
            end
            LayoutHelpers.AtCenterIn(control, self)
        end

    end,

    ClearControls = function(self, doDestroy)
        if doDestroy then

        else

        end
    end,

    Expand = function(self)
        expandAnimation:Apply(self)
    end,

    Contract = function(self)
        contractAnimation:Apply(self)
    end,

    OnExpandControl = function(self)
        local index = self._animationIndex
        local control = self._controls[index]
        local indexOffset = (index + 0.5)
        LayoutHelpers.AtHorizontalCenterIn(control, self)
        control.Top:Set(function() return self.Top() + indexOffset * self.Height() - 0.5 * control.Height() end)
        control:Show()
        appearAnimation:Apply(control)
    end,

    OnContractControl = function(self)
        local index = self._animationIndex
        local control = self._controls[index]
        fadeAnimation:Apply(control)
    end


}
