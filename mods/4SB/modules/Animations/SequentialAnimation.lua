local function ApplySequentialAnimation(animation, delay, controls)
    for i, control in controls do
        animation:Apply(control)
        WaitSeconds(delay)
    end
end

SequentialAnimation = ClassSimple {
    __init = function(self, animation, delay)
        self._delay = delay
        self._animation = animation
    end,

    Apply = function(self, controls)
        ForkThread(ApplySequentialAnimation, self._animation, self._delay, controls)
    end
}
