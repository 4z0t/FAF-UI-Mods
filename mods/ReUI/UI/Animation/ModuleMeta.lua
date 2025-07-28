---@meta

---@class ReUI.UI.Animation : ReUI.Module
ReUI.UI.Animation = {}

---@type ReUI.UI.Animation.Animator | fun(parent?: Frame): ReUI.UI.Animation.Animator
ReUI.UI.Animation.Animator = ...

---@param control Control
---@param animation ReUI.UI.Animation.Animation
---@param ... any
function ReUI.UI.Animation.ApplyAnimation(control, animation, ...)
end

---@param control Control
---@param skip? boolean
function ReUI.UI.Animation.StopAnimation(control, skip)
end

---@param onStart ReAnimationOnStartFunc
---@param onFrame ReAnimationOnFrameFunc
---@param onFinish ReAnimationOnFinishFunc
---@param animator? ReUI.UI.Animation.Animator
---@return ReUI.UI.Animation.Animation
function ReUI.UI.Animation.CreateAnimation(onStart, onFrame, onFinish, animator)
end

ReUI.UI.Animation.Factory = {}

---@type BaseAnimationFactory
ReUI.UI.Animation.Factory.Base = ...

---@type AlphaAnimationFactory
ReUI.UI.Animation.Factory.Alpha = ...

---@type ColorAnimationFactory
ReUI.UI.Animation.Factory.Color = ...

---@type DelayedAnimationFactory
ReUI.UI.Animation.Factory.Delay = ...

---@type SequentialAnimation | fun(animation:ReUI.UI.Animation.Animation, delay:number, initialDelay?:number):SequentialAnimation
ReUI.UI.Animation.Sequential = ...
