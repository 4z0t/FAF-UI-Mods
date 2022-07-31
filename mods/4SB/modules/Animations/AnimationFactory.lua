-- move
-- fade in
-- fade out
-- color
-- blink
-- etc

local emptyFunc = function() end

local Animation = import("Animation.lua")

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
    ---@param func fun(control : Control, delta : number, state: ControlState) : boolean # if returns true then animation is finished
    ---@return BaseAnimationFactory
    OnFrame = function(self, func)
        self._onFrame = func
        return self
    end,
    ---comment
    ---@param self BaseAnimationFactory
    ---@param func? fun(control : Control, state: ControlState, ...) : nil | ControlState
    ---@return BaseAnimationFactory
    OnStart = function(self, func)
        self._onStart = func or emptyFunc
        return self
    end,

    ---comment
    ---@param self BaseAnimationFactory
    ---@param func? fun(control : Control, state: ControlState)
    ---@return BaseAnimationFactory
    OnFinish = function(self, func)
        self._onFinish = func or emptyFunc
        return self
    end,

    ---comment
    ---@param self BaseAnimationFactory
    ---@return Animation
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
        return BaseAnimationFactory.Create(self)
    end
}

local function norm(s)
    if string.len(s) == 1 then
        return "0" .. s
    end
    return s
end

local function setAlpha(color, alpha)
    return norm(STR_itox(alpha)) .. string.sub(color, 3)
end

local function setRed(color, red)
    return string.sub(color, 1, 2) .. norm(STR_itox(red)) .. string.sub(color, 5)
end

local function setGreen(color, green)
    return string.sub(color, 1, 4) .. norm(STR_itox(green)) .. string.sub(color, 7)
end

local function setBlue(color, blue)
    return string.sub(color, 1, 6) .. norm(STR_itox(blue))
end

local function getAlpha(color)
    return STR_xtoi(string.sub(color, 1, 2))
end

local function getRed(color)
    return STR_xtoi(string.sub(color, 3, 4))
end

local function getGreen(color)
    return STR_xtoi(string.sub(color, 5, 6))
end

local function getBlue(color)
    return STR_xtoi(string.sub(color, 7, 8))
end

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


    Create = function(self)


        self._onStart = function(control, state, endColor)
            local color = string.upper(control:GetColor())
            endColor = string.upper(endColor or self._endColor)

            state = {
                startColor = color,
                alpha = 'FF',
                sr = getRed(color),
                sg = getGreen(color),
                sb = getBlue(color),

                r = getRed(color),
                g = getGreen(color),
                b = getBlue(color),

                er = getRed(endColor),
                eg = getGreen(endColor),
                eb = getBlue(endColor),
                endColor = endColor,

                duration = self._duration
            }

            state.ir = (state.er - state.sr) / self._duration
            state.ig = (state.eg - state.sg) / self._duration
            state.ib = (state.eb - state.sb) / self._duration

            return state
        end
        self._onFrame = function(control, delta, state)
            state.r = math.clamp(state.r + state.ir * delta, math.min(state.sr, state.er), math.max(state.sr, state.er))
            state.g = math.clamp(state.g + state.ig * delta, math.min(state.sg, state.eg), math.max(state.sg, state.eg))
            state.b = math.clamp(state.b + state.ib * delta, math.min(state.sb, state.eb), math.max(state.sb, state.eb))
            local color = state.alpha ..
                norm(STR_itox(math.floor(state.r))) ..
                norm(STR_itox(math.floor(state.g))) ..
                norm(STR_itox(math.floor(state.b)))
            LOG(color)
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
        return BaseAnimationFactory.Create(self)
    end
}




local baseFactory
local alphaAnimationFactory
local colorAnimationFactory
local function Init()
    baseFactory           = BaseAnimationFactory()
    alphaAnimationFactory = AlphaAnimationFactory()
    colorAnimationFactory = ColorAnimationFactory()
end

function GetAnimationFactory()
    return baseFactory
end

function GetAlphaAnimationFactory()
    return alphaAnimationFactory
end

function GetColorAnimationFactory()
    return colorAnimationFactory
end

Init()
