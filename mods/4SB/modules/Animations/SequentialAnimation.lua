local AnimationFactories = import("AnimationFactory.lua")
local delayedAnimationFactory = AnimationFactories.GetDelayAnimationFactory()


local delayAnimation = delayedAnimationFactory
    :Create()


local function ApplySequentialAnimation(animation, delay, controls, initialDelay)
    local curDelay = initialDelay or 0
    for i, control in controls do
        delayAnimation:Apply(control, curDelay, animation)
        curDelay = delay + curDelay
    end
end

---@class SequentialAnimation
---@field _animation Animation
---@field _delay number
---@field _initialDelay number
SequentialAnimation = ClassSimple {

    ---
    ---@param self SequentialAnimation
    ---@param animation Animation
    ---@param delay number
    ---@param initialDelay number
    __init = function(self, animation, delay, initialDelay)
        self._delay = delay
        self._animation = animation
        self._initialDelay = initialDelay or 0
    end,

    ---@param self SequentialAnimation
    ---@param controls Control[]
    Apply = function(self, controls)
        ApplySequentialAnimation(self._animation, self._delay, controls, self._initialDelay)
    end
}
