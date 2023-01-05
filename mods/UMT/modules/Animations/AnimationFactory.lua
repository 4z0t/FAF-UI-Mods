---@module "Animations/AnimationFactory"

local emptyFunc = function() end
local Animation = import("Animation.lua")
local ColorUtils = UMT.ColorUtils

---@class BaseAnimationFactory
local BaseAnimationFactory = ClassSimple
{
    __init = function(self)
        self._onFrame = false
        self._onStart = false
        self._onFinish = false
    end,

    ---comment
    ---@param self BaseAnimationFactory
    ---@param func animationOnFrameFunc
    ---@return BaseAnimationFactory
    OnFrame = function(self, func)
        self._onFrame = func
        return self
    end,
    ---comment
    ---@param self BaseAnimationFactory
    ---@param func? animationOnStartFunc
    ---@return BaseAnimationFactory
    OnStart = function(self, func)
        self._onStart = func or emptyFunc
        return self
    end,

    ---comment
    ---@param self BaseAnimationFactory
    ---@param func? animationOnFinishFunc
    ---@return BaseAnimationFactory
    OnFinish = function(self, func)
        self._onFinish = func or emptyFunc
        return self
    end,

    ---comment
    ---@param self BaseAnimationFactory
    ---@param animator? Animator
    ---@return Animation
    Create = function(self, animator)
        assert(self._onStart and self._onFrame and self._onFinish, "Not complete animation")

        local animation = Animation.Create(self._onStart, self._onFrame, self._onFinish, animator)

        self._onStart = false
        self._onFrame = false
        self._onFinish = false

        return animation

    end
}
---@class AlphaAnimationFactory : BaseAnimationFactory
local AlphaAnimationFactory = Class(BaseAnimationFactory)
{
    ---comment
    ---@param self AlphaAnimationFactory
    ---@param startAlpha number
    ---@return AlphaAnimationFactory
    StartWith = function(self, startAlpha)
        self._startAlpha = math.clamp(startAlpha, 0., 1.)
        self._isStart = true
        return self
    end,

    ---comment
    ---@param self AlphaAnimationFactory
    ---@return AlphaAnimationFactory
    ToAppear = function(self)
        self._direction = 1
        return self
    end,

    ---comment
    ---@param self AlphaAnimationFactory
    ---@return AlphaAnimationFactory
    ToFade = function(self)
        self._direction = -1
        return self
    end,

    ---comment
    ---@param self AlphaAnimationFactory
    ---@param endAlpha number
    ---@return AlphaAnimationFactory
    EndWith = function(self, endAlpha)
        self._endAlpha = math.clamp(endAlpha, 0., 1.)
        return self
    end,

    ---comment
    ---@param self AlphaAnimationFactory
    ---@param duration number
    ---@return AlphaAnimationFactory
    For = function(self, duration)
        assert(duration > 0, "Duration of alpha animation cant be negative or 0")

        self._duration = duration
        return self
    end,

    ---comment
    ---@param self AlphaAnimationFactory
    ---@return AlphaAnimationFactory
    ApplyToChildren = function(self)
        self._children = true
        return self
    end,

    ---comment
    ---@param self AlphaAnimationFactory
    ---@param animator? Animator
    ---@return Animation
    Create = function(self, animator)
        assert(self._endAlpha and self._direction and self._duration, "Not complete Alpha animation")

        if self._direction == 1 then
            self._startAlpha = self._startAlpha or 0
        else
            self._startAlpha = self._startAlpha or 1
        end

        assert((self._endAlpha - self._startAlpha) * self._direction > 0,
            "End and Start alphas cant be same and must be correct with Appear/Fade")

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
        return BaseAnimationFactory.Create(self, animator)
    end
}

---@class ColorAnimationFactory : BaseAnimationFactory
local ColorAnimationFactory = Class(BaseAnimationFactory)
{
    StartWith = function(self, color)
        if iscallable(color) then
            color = color()
        end
        self._startColor = string.upper(color)
        self._isStart = true
        return self
    end,


    EndWith = function(self, color)
        if iscallable(color) then
            color = color()
        end
        self._endColor = string.upper(color)
        return self
    end,

    For = function(self, duration)
        assert(duration > 0, "Duration of alpha animation cant be negative or 0")

        self._duration = duration
        return self
    end,


    ---comment
    ---@param self ColorAnimationFactory
    ---@param animator? Animator
    ---@return Animation
    Create = function(self, animator)
        local duration = self._duration

        self._onStart = function(control, state, endColor)
            local color = string.upper(control:GetColor())
            endColor = string.upper(endColor or self._endColor)

            state = {
                startColor = color,

                alpha = 'FF',

                sr = ColorUtils.GetRed(color),
                sg = ColorUtils.GetGreen(color),
                sb = ColorUtils.GetBlue(color),

                r = ColorUtils.GetRed(color),
                g = ColorUtils.GetGreen(color),
                b = ColorUtils.GetBlue(color),

                er = ColorUtils.GetRed(endColor),
                eg = ColorUtils.GetGreen(endColor),
                eb = ColorUtils.GetBlue(endColor),

                endColor = endColor,

                duration = duration
            }

            state.ir = (state.er - state.sr) / duration
            state.ig = (state.eg - state.sg) / duration
            state.ib = (state.eb - state.sb) / duration

            return state
        end
        self._onFrame = function(control, delta, state)
            state.r = math.clamp(state.r + state.ir * delta, math.min(state.sr, state.er), math.max(state.sr, state.er))
            state.g = math.clamp(state.g + state.ig * delta, math.min(state.sg, state.eg), math.max(state.sg, state.eg))
            state.b = math.clamp(state.b + state.ib * delta, math.min(state.sb, state.eb), math.max(state.sb, state.eb))

            local color = ColorUtils.ColorRGBA(math.floor(state.r), math.floor(state.g), math.floor(state.b))
            if color == state.endColor then
                return true
            end
            control:SetColor(color)
        end
        self._onFinish = function(control, state)
            control:SetColor(state.endColor)
        end
        self._startColor = false
        self._endColor = false
        self._isStart = false
        return BaseAnimationFactory.Create(self, animator)
    end
}

---@class DelayedAnimationFactory : BaseAnimationFactory
local DelayedAnimationFactory = Class(BaseAnimationFactory)
{
    Delay = function(self, delay)
        self._delay = delay
    end,



    ---comment
    ---@param self ColorAnimationFactory
    ---@param animator? Animator
    ---@return Animation
    Create = function(self, animator)
        local delay = self._delay
        self._delay = false
        local animation = nil
        if self._onFrame then
            animation = BaseAnimationFactory.Create(self, animator)
        end

        self
            :OnStart(function(control, state, _delay, _animation)
                return { time = 0, delay = _delay or delay, animation = _animation or animation }
            end)
            :OnFrame(function(control, delta, state)
                state.time = state.time + delta
                if state.time >= state.delay then
                    return true
                end
            end)
            :OnFinish(function(control, state)
                state.animation:Apply(control)
            end)
        return BaseAnimationFactory.Create(self, animator)
    end
}



local baseFactory
local alphaAnimationFactory
local colorAnimationFactory
local delayedAnimationFactory
local function Init()
    baseFactory             = BaseAnimationFactory()
    alphaAnimationFactory   = AlphaAnimationFactory()
    colorAnimationFactory   = ColorAnimationFactory()
    delayedAnimationFactory = DelayedAnimationFactory()
end

---comment
---@return BaseAnimationFactory
function GetAnimationFactory()
    return baseFactory
end

---comment
---@return AlphaAnimationFactory
function GetAlphaAnimationFactory()
    return alphaAnimationFactory
end

---comment
---@return ColorAnimationFactory
function GetColorAnimationFactory()
    return colorAnimationFactory
end

---comment
---@return DelayedAnimationFactory
function GetDelayAnimationFactory()
    return delayedAnimationFactory
end

Init()
