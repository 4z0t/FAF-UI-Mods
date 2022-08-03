---@module "Animations/Animator"


local Group = import('/lua/maui/group.lua').Group

---@class Animator : Control
---@field _controls table<Control, Animation>
---@field _controlsStates table<Control, ControlState>
Animator = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self._controls = {}
        self._controlsStates = {}
        self.Left:Set(0)
        self.Top:Set(0)
        self.Width:Set(0)
        self.Height:Set(0)
        self:DisableHitTest()
    end,

    OnFrame = function(self, delta)
        local controlsStates = self._controlsStates
        for control, animation in self._controls do
            if IsDestroyed(control) then
                self:Remove(control, true)
            elseif animation.OnFrame(control, delta, controlsStates[control]) then
                self:Remove(control)
            end
        end
    end,

    ---comment
    ---@param self Animator
    ---@param control Control
    ---@param animation Animation
    Add = function(self, control, animation, ...)
        self._controls[control] = animation
        self._controlsStates[control] = animation.OnStart(control, self._controlsStates[control], unpack(arg))
        if not self:NeedsFrameUpdate() then
            self:SetNeedsFrameUpdate(true)
        end
    end,

    Remove = function(self, control, skip)
        if not skip then
            local animation = self._controls[control]
            if animation then
                animation.OnFinish(control, self._controlsStates[control])
            end
        end

        self._controls[control] = nil
        self._controlsStates[control] = nil

        if table.empty(self._controls) and self:NeedsFrameUpdate() then
            self:SetNeedsFrameUpdate(false)
        end
    end,

    OnDestroy = function(self)
        self._controls = nil
        self._controlsStates = nil
    end
}

---@type Animator
local globalAnimator

function Init()
    globalAnimator = Animator(GetFrame(0))
end

---global animator applies animation to control with additional args
---@param control Control
---@param animation Animation
---@param ... any
function ApplyAnimation(control, animation, ...)
    if IsDestroyed(globalAnimator) then
        error("There is no animator to animate controls")
    else
        globalAnimator:Add(control, animation, unpack(arg))
    end
end

---comment
---@param control Control
function StopAnimation(control, skip)
    if IsDestroyed(globalAnimator) then
        error("There is no animator to stop animation")
    else
        globalAnimator:Remove(control, skip)
    end
end

Init()
