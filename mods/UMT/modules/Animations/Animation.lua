---@module "Animations/Animation"
---@module "Animations/Animator"
local Animator = import("Animator.lua")

---@alias ControlState table<any, any>

---@alias animationOnStartFunc fun(control : Control, state: ControlState?, ...) : nil | ControlState
---@alias animationOnFrameFunc fun(control : Control, delta : number, state: ControlState?) : boolean # if returns true then animation is finished
---@alias animationOnFinishFunc fun(control : Control, state: ControlState?)



---@class Animation
---@field OnStart animationOnStartFunc
---@field OnFrame animationOnFrameFunc
---@field OnFinish animationOnFinishFunc
---@field _animator Animator
local AnimationMetaTable = {}
AnimationMetaTable.__index = AnimationMetaTable



---applies animation to given control
---@param control Control
---@param ... any
function AnimationMetaTable:Apply(control, ...)
    if IsDestroyed(self._animator) then
        Animator.ApplyAnimation(control, self, unpack(arg))
    else
        self._animator:Add(control, self, unpack(arg))
    end
end

---comment
---@param onStart animationOnStartFunc
---@param onFrame animationOnFrameFunc
---@param onFinish animationOnFinishFunc
---@param animator? Animator
---@return Animation
function Create(onStart, onFrame, onFinish, animator)

    return setmetatable(
        { OnStart = onStart,
            OnFrame = onFrame,
            OnFinish = onFinish,
            _animator = animator
        }, AnimationMetaTable)
end
