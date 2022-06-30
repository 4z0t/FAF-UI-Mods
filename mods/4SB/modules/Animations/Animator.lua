local Group = import('/lua/maui/group.lua').Group

---@class Animator : Control
---@field _controls table<Control, Animation>
Animator = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self._controls = {}
        self.Left:Set(0)
        self.Top:Set(0)
        self.Width:Set(0)
        self.Height:Set(0)
        self:DisableHitTest()
    end,

    OnFrame = function(self, delta)
        for control, animation in self._controls do
            if animation.OnFrame(control, delta) then
                self:Remove(control)
            end
        end
    end,

    ---comment
    ---@param self Animator
    ---@param control Control
    ---@param animation Animation
    Add = function(self, control, animation)
        self._controls[control] = animation
        animation.OnStart(control)
        if not self:NeedsFrameUpdate() then
            self:SetNeedsFrameUpdate(true)
        end
    end,

    Remove = function(self, control)
        local animation = self._controls[control]
        if animation then
            animation.OnFinish(control)
            self._controls[control] = nil
        end
        if table.empty(self._controls) and self:NeedsFrameUpdate() then
            self:SetNeedsFrameUpdate(false)
        end
    end
}

---@type Animator
local animator

function Init()
    animator = Animator(GetFrame(0))
end

---comment
---@param control Control
---@param animation Animation
function ApplyAnimation(control, animation)
    if IsDestroyed(animator) then
        error("There is no animator to animate controls")
    else
        animator:Add(control, animation)
    end
end

---comment
---@param control Control
function StopAnimation(control)
    if IsDestroyed(animator) then
        error("There is no animator to stop animation")
    else
        animator:Remove(control)
    end
end


Init()