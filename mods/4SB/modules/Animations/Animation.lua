local Animator = import("Animator.lua")

---@class Animation
---@field OnStart fun(control : Control)
---@field OnFrame fun(control : Control, delta : number) : boolean # if returns true then animation is finished
---@field OnFinish fun(control : Control)
local AnimationMetaTable = {}
AnimationMetaTable.__index = AnimationMetaTable


function AnimationMetaTable:Apply(control)
    Animator.ApplyAnimation(control, self)
end

function Create(onStart,
                onFrame,
                onFinish)

    return setmetatable(
        { OnStart = onStart,
            OnFrame = onFrame,
            OnFinish = onFinish }, AnimationMetaTable)
end
