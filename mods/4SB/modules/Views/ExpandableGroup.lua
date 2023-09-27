local Group = UMT.Controls.Group
local Bitmap = UMT.Controls.Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local animationFactory = UMT.Animation.Factory.Base
local alphaAnimationFactory = UMT.Animation.Factory.Alpha

local expandSpeed = 500

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
        control.Layouter(control)
            :AtCenterIn(control:GetParent())
        control:Hide()
    end)
    :Create()


ExpandableGroup = UMT.Class(Group)
{
    __init = function(self, parent, width, height)
        Group.__init(self, parent)

        self._expand = Group(self)

        self._controls       = {}
        self._active         = false
        self._animationIndex = 1
        self._isExpanded     = false
    end,

    __post_init = function(self, parent, width, height)
        local layouter = self.Layouter
        layouter(self)
            :Width(width)
            :Height(height)

        layouter(self._expand)
            :Width(width)
            :Height(height)
            :AtLeftTopIn(self)
    end,


    AddControls = function(self, controls, default)
        default = default or 1

        self._controls = {}
        for i, control in controls do
            self.Layouter(control):Over(self, 5)
            if i == default then
                self._active = control
                control:Show()
            else
                table.insert(self._controls, control)
                control:Hide()
            end
            self.Layouter(control):AtCenterIn(self)
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
        self.Layouter(control)
            :AtHorizontalCenterIn(self)
            :Top(function() return self.Top() + indexOffset * self.Height() - 0.5 * control.Height() end)
        control:Show()
        appearAnimation:Apply(control)
    end,

    OnContractControl = function(self)
        local index = self._animationIndex
        local control = self._controls[index]
        fadeAnimation:Apply(control)
    end


}
