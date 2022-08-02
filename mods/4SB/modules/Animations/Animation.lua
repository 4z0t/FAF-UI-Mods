---@module "Animations/Animation"
---@module "Animations/Animator"
local Animator = import("Animator.lua")

---@alias animationOnStartFunc fun(control : Control, state: ControlState, ...) : nil | ControlState
---@alias animationOnFrameFunc fun(control : Control, delta : number, state: ControlState) : boolean # if returns true then animation is finished
---@alias animationOnFinishFunc  fun(control : Control, state: ControlState)


---@class ControlState: table

---@class Animation
---@field OnStart animationOnStartFunc
---@field OnFrame animationOnFrameFunc
---@field OnFinish animationOnFinishFunc
local AnimationMetaTable = {}
AnimationMetaTable.__index = AnimationMetaTable



---applies animation to given control
---@param control Control
---@param ... any
function AnimationMetaTable:Apply(control, ...)
    Animator.ApplyAnimation(control, self, unpack(arg))
end

---comment
---@param onStart animationOnStartFunc
---@param onFrame animationOnFrameFunc
---@param onFinish animationOnFinishFunc
---@return Animation
function Create(onStart, onFrame, onFinish)

    return setmetatable(
        { OnStart = onStart,
            OnFrame = onFrame,
            OnFinish = onFinish }, AnimationMetaTable)
end
