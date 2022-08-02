local function ApplySequentialAnimation(animation, delay, controls, initialDelay)
    if initialDelay ~= 0 then
        WaitSeconds(initialDelay)
    end
    for i, control in controls do
        animation:Apply(control)
        WaitSeconds(delay)
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
        ForkThread(ApplySequentialAnimation, self._animation, self._delay, controls, self._initialDelay)
    end
}
