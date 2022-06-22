local function ApplySequentialAnimation(animation, delay, controls, initialDelay)
    if initialDelay ~= 0 then
        WaitSeconds(initialDelay)
    end
    for i, control in controls do
        animation:Apply(control)
        WaitSeconds(delay)
    end
end

SequentialAnimation = ClassSimple {
    __init = function(self, animation, delay, initialDelay)
        self._delay = delay
        self._animation = animation
        self._initialDelay = initialDelay or 0
    end,

    Apply = function(self, controls)
        ForkThread(ApplySequentialAnimation, self._animation, self._delay, controls, self._initialDelay)
    end
}
