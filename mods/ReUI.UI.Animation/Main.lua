ReUI.Require
{
    "ReUI.UI >= 1.0.0",
    "ReUI.UI.Color >= 1.0.0"
}

function Main(isReplay)
    local MAX_DELTA_ALLOWED = 0.05

    ---@diagnostic disable-next-line:deprecated
    local unpack = unpack
    local setmetatable = setmetatable
    local IsDestroyed = IsDestroyed
    local StringUpper = string.upper
    local math = math
    local MathClamp = math.clamp
    local MathFloor = math.floor
    local MathMax = math.max
    local MathMin = math.min

    local ColorUtils = ReUI.UI.Color

    local Group = import('/lua/maui/group.lua').Group

    local emptyFunc = function() end

    --#region Animator

    ---@class ReUI.UI.Animation.Animator : Group
    ---@field _controls table<ReControl, ReUI.UI.Animation.Animation>
    ---@field _controlsStates table<ReControl, ReControlState>
    local Animator = Class(Group)
    {
        __init = function(self, parent)
            Group.__init(self, parent or GetFrame(0))
            self._controls = {}
            self._controlsStates = {}
            self.Left:Set(0)
            self.Top:Set(0)
            self.Width:Set(0)
            self.Height:Set(0)
            self:DisableHitTest()
        end,

        ---@param self ReUI.UI.Animation.Animator
        ---@param delta number
        AnimateControls = function(self, delta)
            local controlsStates = self._controlsStates
            for control, animation in self._controls do
                if IsDestroyed(control) then
                    self:Remove(control, true)
                elseif animation.OnFrame(control, delta, controlsStates[control]) then
                    self:Remove(control)
                end
            end
        end,

        ---@param self ReUI.UI.Animation.Animator
        ---@param delta number
        OnFrame = function(self, delta)
            if delta > MAX_DELTA_ALLOWED then
                local n = math.ceil(delta / MAX_DELTA_ALLOWED)
                delta = delta / n
                for _ = 1, n do
                    self:AnimateControls(delta)
                end
            else
                self:AnimateControls(delta)
            end
        end,

        ---@param self ReUI.UI.Animation.Animator
        ---@param control ReControl
        ---@param animation ReUI.UI.Animation.Animation
        ---@param ... any
        Add = function(self, control, animation, ...)
            self._controls[control] = animation
            self._controlsStates[control] = animation.OnStart(control, self._controlsStates[control], unpack(arg))
            if not self:NeedsFrameUpdate() then
                self:SetNeedsFrameUpdate(true)
            end
        end,

        ---@param self ReUI.UI.Animation.Animator
        ---@param control ReControl
        ---@param skip? boolean
        Remove = function(self, control, skip)
            local animation = self._controls[control]
            local controlState = self._controlsStates[control]

            self._controls[control] = nil
            self._controlsStates[control] = nil

            if not skip then
                if animation then
                    animation.OnFinish(control, controlState)
                end
            end

            if table.empty(self._controls) and self:NeedsFrameUpdate() then
                self:SetNeedsFrameUpdate(false)
            end
        end,

        ---@param self ReUI.UI.Animation.Animator
        OnDestroy = function(self)
            self._controls = nil
            self._controlsStates = nil
        end
    }

    ---@type ReUI.UI.Animation.Animator
    local globalAnimator = Animator()


    ---global animator applies animation to control with additional args
    ---@param control ReControl
    ---@param animation ReUI.UI.Animation.Animation
    ---@param ... any
    local function ApplyAnimation(control, animation, ...)
        if IsDestroyed(globalAnimator) then
            error("There is no animator to animate controls")
        else
            globalAnimator:Add(control, animation, unpack(arg))
        end
    end

    ---Immediately removes control from animator
    ---@param control ReControl
    local function StopAnimation(control, skip)
        if IsDestroyed(globalAnimator) then
            error("There is no animator to stop animation")
        else
            globalAnimator:Remove(control, skip)
        end
    end

    ---@alias ReControl ReUI.UI.Controls.Control
    ---@alias ReControlState table

    ---@alias ReAnimationOnStartFunc fun(control : ReControl, state: ReControlState?, ...) : nil | ReControlState
    ---@alias ReAnimationOnFrameFunc fun(control : ReControl, delta : number, state: ReControlState?) : boolean # if returns true then animation is finished
    ---@alias ReAnimationOnFinishFunc fun(control : ReControl, state: ReControlState?)

    --#endregion

    --#region Animation

    ---@class ReUI.UI.Animation.Animation
    ---@field OnStart ReAnimationOnStartFunc
    ---@field OnFrame ReAnimationOnFrameFunc
    ---@field OnFinish ReAnimationOnFinishFunc
    ---@field _animator ReUI.UI.Animation.Animator
    local AnimationMetaTable = {}
    AnimationMetaTable.__index = AnimationMetaTable

    ---applies animation to given control
    ---@param control ReControl
    ---@param ... any
    function AnimationMetaTable:Apply(control, ...)
        if IsDestroyed(self._animator) then
            ApplyAnimation(control, self, unpack(arg))
        else
            self._animator:Add(control, self, unpack(arg))
        end
    end

    ---@param onStart ReAnimationOnStartFunc
    ---@param onFrame ReAnimationOnFrameFunc
    ---@param onFinish ReAnimationOnFinishFunc
    ---@param animator? ReUI.UI.Animation.Animator
    ---@return ReUI.UI.Animation.Animation
    local function CreateAnimation(onStart, onFrame, onFinish, animator)

        return setmetatable(
            {
                OnStart = onStart,
                OnFrame = onFrame,
                OnFinish = onFinish,
                _animator = animator
            },
            AnimationMetaTable)
    end

    --#endregion

    --#region Factories


    ---@class BaseAnimationFactory
    ---@field _onFrame ReAnimationOnFrameFunc
    ---@field _onStart ReAnimationOnStartFunc
    ---@field _onFinish ReAnimationOnFinishFunc
    local BaseAnimationFactory = ClassSimple
    {
        __init = function(self)
            self._onFrame = false
            self._onStart = false
            self._onFinish = false
        end,

        ---@param self BaseAnimationFactory
        ---@param func ReAnimationOnFrameFunc
        ---@return BaseAnimationFactory
        OnFrame = function(self, func)
            self._onFrame = func
            return self
        end,

        ---@param self BaseAnimationFactory
        ---@param func? ReAnimationOnStartFunc
        ---@return BaseAnimationFactory
        OnStart = function(self, func)
            self._onStart = func or emptyFunc
            return self
        end,

        ---@param self BaseAnimationFactory
        ---@param func? ReAnimationOnFinishFunc
        ---@return BaseAnimationFactory
        OnFinish = function(self, func)
            self._onFinish = func or emptyFunc
            return self
        end,

        ---@param self BaseAnimationFactory
        ---@param animator? ReUI.UI.Animation.Animator
        ---@return ReUI.UI.Animation.Animation
        Create = function(self, animator)
            assert(self._onStart and self._onFrame and self._onFinish, "Not complete animation")

            local animation = CreateAnimation(self._onStart, self._onFrame, self._onFinish, animator)

            self._onStart = false
            self._onFrame = false
            self._onFinish = false

            return animation

        end
    }
    ---@class AlphaAnimationFactory : BaseAnimationFactory
    local AlphaAnimationFactory = Class(BaseAnimationFactory)
    {
        ---@param self AlphaAnimationFactory
        ---@param startAlpha number
        ---@return AlphaAnimationFactory
        StartWith = function(self, startAlpha)
            self._startAlpha = MathClamp(startAlpha, 0., 1.)
            self._isStart = true
            return self
        end,

        ---@param self AlphaAnimationFactory
        ---@return AlphaAnimationFactory
        ToAppear = function(self)
            self._direction = 1
            return self
        end,

        ---@param self AlphaAnimationFactory
        ---@return AlphaAnimationFactory
        ToFade = function(self)
            self._direction = -1
            return self
        end,

        ---@param self AlphaAnimationFactory
        ---@param endAlpha number
        ---@return AlphaAnimationFactory
        EndWith = function(self, endAlpha)
            self._endAlpha = MathClamp(endAlpha, 0., 1.)
            return self
        end,

        ---@param self AlphaAnimationFactory
        ---@param duration number
        ---@return AlphaAnimationFactory
        For = function(self, duration)
            assert(duration > 0, "Duration of alpha animation cant be negative or 0")

            self._duration = duration
            return self
        end,

        ---@param self AlphaAnimationFactory
        ---@return AlphaAnimationFactory
        ApplyToChildren = function(self)
            self._children = true
            return self
        end,

        ---@param self AlphaAnimationFactory
        ---@param animator? ReUI.UI.Animation.Animator
        ---@return ReUI.UI.Animation.Animation
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
                    control:SetAlpha(MathClamp(control:GetAlpha() + delta * diff / duration, 0., 1.), applyToChildren)
                end
            else
                self._onFrame = function(control, delta)
                    if control:GetAlpha() <= endAlpha then
                        return true
                    end
                    control:SetAlpha(MathClamp(control:GetAlpha() + delta * diff / duration, 0., 1.), applyToChildren)
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
    ---@field _duration number
    local ColorAnimationFactory = Class(BaseAnimationFactory)
    {
        StartWith = function(self, color)
            if iscallable(color) then
                color = color()
            end
            self._startColor = StringUpper(color)
            self._isStart = true
            return self
        end,


        EndWith = function(self, color)
            if iscallable(color) then
                color = color()
            end
            self._endColor = StringUpper(color)
            return self
        end,

        For = function(self, duration)
            assert(duration > 0, "Duration of alpha animation cant be negative or 0")

            self._duration = duration
            return self
        end,


        ---@param self ColorAnimationFactory
        ---@param animator? ReUI.UI.Animation.Animator
        ---@return ReUI.UI.Animation.Animation
        Create = function(self, animator)
            local duration = self._duration
            local _endColor = self._endColor

            self._onStart = function(control, state, endColor)
                local color = StringUpper(control:GetColor())
                endColor = StringUpper(endColor or _endColor)

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
                state.r = MathClamp(state.r + state.ir * delta, MathMin(state.sr, state.er), MathMax(state.sr, state.er))
                state.g = MathClamp(state.g + state.ig * delta, MathMin(state.sg, state.eg), MathMax(state.sg, state.eg))
                state.b = MathClamp(state.b + state.ib * delta, MathMin(state.sb, state.eb), MathMax(state.sb, state.eb))

                local color = ColorUtils.ColorRGBA(MathFloor(state.r), MathFloor(state.g), MathFloor(state.b))
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
    ---@field _delay number
    local DelayedAnimationFactory = Class(BaseAnimationFactory)
    {
        ---@param self DelayedAnimationFactory
        ---@param delay number
        ---@return DelayedAnimationFactory
        Delay = function(self, delay)
            self._delay = delay
            return self
        end,

        ---@param self DelayedAnimationFactory
        ---@param animator? ReUI.UI.Animation.Animator
        ---@return ReUI.UI.Animation.Animation
        Create = function(self, animator)
            local delay = self._delay
            ---@diagnostic disable-next-line:assign-type-mismatch
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
                    return state.time >= state.delay
                end)
                :OnFinish(function(control, state)
                    state.animation:Apply(control)
                end)
            return BaseAnimationFactory.Create(self, animator)
        end
    }

    local baseFactory = BaseAnimationFactory()
    local alphaAnimationFactory = AlphaAnimationFactory()
    local colorAnimationFactory = ColorAnimationFactory()
    local delayedAnimationFactory = DelayedAnimationFactory()

    --#endregion

    return {
        Factory = {
            Base = baseFactory,
            Color = colorAnimationFactory,
            Alpha = alphaAnimationFactory,
            Delay = delayedAnimationFactory,
        },
        Animator = Animator,
        ApplyAnimation = ApplyAnimation,
        StopAnimation = StopAnimation,
        CreateAnimation = CreateAnimation,
    }
end
