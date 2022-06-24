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
        assert(self._onStart and self._onFrame and self._onFinish, "Not complete animation")

        local animation = Animation.Create(self._onStart, self._onFrame, self._onFinish)

        self._onStart = false
        self._onFrame = false
        self._onFinish = false

        return animation

    end
}

local AlphaAnimationFactory = Class(BaseAnimationFactory)
{
    StartWith = function(self, startAlpha)
        self._startAlpha = math.clamp(startAlpha, 0., 1.)
        self._isStart = true
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
        assert(duration > 0, "Duration of alpha animation cant be negative or 0")

        self._duration = duration
        return self
    end,

    ApplyToChildren = function(self)
        self._children = true
        return self
    end,

    Create = function(self)
        assert(self._endAlpha and self._direction and self._duration, "Not complete Alpha animation")

        if self._direction == 1 then
            self._startAlpha = self._startAlpha or 0
        else
            self._startAlpha = self._startAlpha or 1
        end

        assert((self._endAlpha - self._startAlpha) * self._direction > 0, "End and Start alphas cant be same and must be correct with Appear/Fade")

        local startAlpha = self._startAlpha
        local endAlpha = self._endAlpha
        local direction = self._direction
        local duration = self._duration
        local diff = endAlpha - startAlpha
        local applyToChildren = self._children


        if direction == 1 then
            self._onFrame = function(control, delta)
                if control:GetAlpha() >= endAlpha then
                    return true
                end
                control:SetAlpha(math.clamp(control:GetAlpha() + delta * diff / duration, 0., 1.), applyToChildren)
            end
        else
            self._onFrame = function(control, delta)
                if control:GetAlpha() <= endAlpha then
                    return true
                end
                control:SetAlpha(math.clamp(control:GetAlpha() + delta * diff / duration, 0., 1.), applyToChildren)
            end
        end
        if self._onStart then
            local OnStart = self._onStart
            self._onStart = function(control)
                control:SetAlpha(startAlpha, applyToChildren)
                OnStart(control)
            end
        else
            if self._isStart then
                self._onStart = function(control)
                    control:SetAlpha(startAlpha, applyToChildren)
                end
            else
                self:OnStart()
            end
        end
        if self._onFinish then
            local OnFinish = self._onFinish
            self._onFinish = function(control)
                control:SetAlpha(endAlpha, applyToChildren)
                OnFinish(control)
            end
        else
            self._onFinish = function(control)
                control:SetAlpha(endAlpha, applyToChildren)
            end
        end


        self._startAlpha = false
        self._endAlpha = false
        self._direction = false
        self._duration = false
        self._children = false
        self._isStart = false
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
