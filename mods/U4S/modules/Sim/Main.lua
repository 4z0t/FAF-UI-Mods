---@class CallBackData
---@field name string
---@field args any
---@field from integer

---@class SimToUISyncData
---@field name string
---@field fileName FileName
---@field functionName string
---@field args table?
---@field func fun(data: CallBackData) ?

---TODO
function ValidateArgs(args)
    return true
end

local callbacks = {}

function Add(name, func)
    callbacks[name] = func
end

function Remove(name)
    callbacks[name] = nil
end

function Process(name, args, from)
    if not callbacks[name] then return end

    callbacks[name] {
        name = name,
        args = args,
        from = from
    }
end
