local Animator = import("Animator.lua")

---@class ControlState: table

---@class Animation
---@field OnStart fun(control : Control, state: ControlState, ...) : nil | ControlState
---@field OnFrame fun(control : Control, delta : number, state: ControlState) : boolean # if returns true then animation is finished
---@field OnFinish fun(control : Control, state: ControlState)
local AnimationMetaTable = {}
AnimationMetaTable.__index = AnimationMetaTable


function AnimationMetaTable:Apply(control, ...)
    Animator.ApplyAnimation(control, self, unpack(arg))
end

function Create(onStart,
                onFrame,
                onFinish)

    return setmetatable(
        { OnStart = onStart,
            OnFrame = onFrame,
            OnFinish = onFinish }, AnimationMetaTable)
end
