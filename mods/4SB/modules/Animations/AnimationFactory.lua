-- move
-- fade in
-- fade out
-- color
-- blink
-- etc

local emptyFunc = function() end

local Animation = import("Animation.lua")

local BaseFactory = Class
{
    __init = function(self)
        self._onFrame = false
        self._onStart = false
        self._onFinish = false
    end,

    OnFrame = function(self, func)
        self._onFrame = func
        return self
    end,

    OnStart = function(self, func)
        self._onStart = func or emptyFunc
        return self
    end,

    OnFinish = function(self, func)
        self._onFinish = func or emptyFunc
        return self
    end,

    Create = function(self)
        if self._onStart and
            self._onFrame and
            self._onFinish then

            local animation = Animation.Create(self._onStart, self._onFrame, self._onFinish)

            self._onStart = false
            self._onFrame = false
            self._onFinish = false

            return animation
        else
            error("Not complete animation")
        end
    end
}

local baseFactory

function Init()
    baseFactory = BaseFactory()
end

function AnimationFactory()
    return baseFactory
end

Init()
