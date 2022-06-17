-- move
-- fade in
-- fade out
-- color
-- blink
-- etc

local emptyFunc = function() end

local Animation = import("Animation.lua")

local BaseAnimationFactory = ClassSimple
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

local AlphaAnimationFactory = Class(BaseAnimationFactory)
{
    StartWith = function(self, startAlpha)
        self._startAlpha = math.clamp(startAlpha, 0., 1.)
        return self
    end,

    ToAppear = function(self)
        self._direction = 1
        return self
    end,

    ToFade = function(self)
        self._direction = -1
        return self
    end,

    EndWith = function(self, endAlpha)
        self._endAlpha = math.clamp(endAlpha, 0., 1.)
        return self
    end,

    For = function(self, duration)
        if duration <= 0 then
            error("Duration of alpha animation cant be negative or 0")
        end
        self._duration = duration
        return self
    end,

    Create = function(self)
        if not (self._endAlpha and self._startAlpha and self._direction and self._duration) then
            error("Not complete Alpha animation")
        end

        if (self._endAlpha - self._startAlpha) * self._direction <= 0 then
            error("End and Start alphas cant be same and must be correct with Appear/Fade")
        end

        local startAlpha = self._startAlpha
        local endAlpha = self._endAlpha
        local direction = self._direction
        local duration = self._duration
        local diff = endAlpha - startAlpha

        if direction == 1 then
            self._onFrame = function(control, delta)
                if control:GetAlpha() >= endAlpha then
                    return true
                end
                control:SetAlpha(math.clamp(control:GetAlpha() + delta * diff / duration, 0., 1.))
            end
        else
            self._onFrame = function(control, delta)
                if control:GetAlpha() <= endAlpha then
                    return true
                end
                control:SetAlpha(math.clamp(control:GetAlpha() + delta * diff / duration, 0., 1.))
            end
        end

        self._onStart = function(control)
            control:SetAlpha(startAlpha)
        end
        self._onFinish = function(control)
            control:SetAlpha(endAlpha)
        end

        self._startAlpha = false
        self._endAlpha = false
        self._direction = false
        self._duration = false
        return BaseAnimationFactory.Create(self)
    end
}

local baseFactory
local alphaAnimationFactory
local function Init()
    baseFactory           = BaseAnimationFactory()
    alphaAnimationFactory = AlphaAnimationFactory()
end

function GetAnimationFactory()
    return baseFactory
end

function GetAlphaAnimationFactory()
    return alphaAnimationFactory
end

Init()
