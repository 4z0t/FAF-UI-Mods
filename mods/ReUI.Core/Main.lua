---@class Hook
---@field moduleName FileName
---@field fieldName string
---@field callback HookCallback

function Main()
    local setmetatable = setmetatable

    local weakKey = { __mode = 'k' }
    local weakValue = { __mode = 'v' }
    local weakKeyValue = { __mode = 'kv' }

    ---@param hook Hook
    local function MakeHook(hook)
        LOG(("ReUI.Core: Hooking '%s':%s"):format(hook.moduleName, hook.fieldName))
        local module = import(hook.moduleName)
        local originalField = module[hook.fieldName]
        local newField = hook.callback(originalField, module)
        module[hook.fieldName] = newField
    end

    ---@type Hook[]
    local hooks = {}

    ---@diagnostic disable-next-line:different-requires
    local ReUIOnCreateUI = import("Modules/OnCreateUI.lua")
    ReUIOnCreateUI.AddPreCreateCallback(function(isReplay)
        local pcall = pcall
        for _, hook in hooks do
            local ok, result = pcall(MakeHook, hook)
            if not ok then
                WARN(("ReUI.Core: Failed to hook '%s':%s"):format(hook.moduleName, hook.fieldName))
                WARN(result)
            end
        end
    end)

    ReUIOnCreateUI.AddPostCreateCallback(function(isReplay)
        ---@diagnostic disable-next-line:cast-local-type
        hooks = nil

        ---@param moduleName FileName
        ---@param fieldName string
        ---@param callback HookCallback
        ReUI.Core.Hook = function(moduleName, fieldName, callback)
            error(("ReUI.Core.Hook: Attempt to make hook after UI was created. Hooks is '%s':%s")
                :format(moduleName, fieldName))
        end
    end)

    ---@param moduleName FileName
    ---@param fieldName string
    ---@param callback HookCallback
    local function PerformHook(moduleName, fieldName, callback)
        --! Check for hooks that conflict
        table.insert(hooks, {
            moduleName = moduleName,
            fieldName = fieldName,
            callback = callback
        })
    end

    local ReUIClass = import("Modules/Class.lua")

    return {
        Hook = PerformHook,

        ---@param moduleName FileName
        HookModule = function(moduleName)
            ---@param fieldName string
            ---@param callback HookCallback
            return function(fieldName, callback)
                PerformHook(moduleName, fieldName, callback)
            end
        end,

        OnPreCreateUI = ReUIOnCreateUI.AddPreCreateCallback,
        OnPostCreateUI = ReUIOnCreateUI.AddPostCreateCallback,

        Weak = {
            ---Makes table weak by key
            ---@generic T : table
            ---@param t T
            ---@return T
            Key = function(t)
                return setmetatable(t, weakKey)
            end,
            ---Makes table weak by value
            ---@generic T : table
            ---@param t T
            ---@return T
            Value = function(t)
                return setmetatable(t, weakValue)
            end,
            ---Makes table weak by key and value
            ---@generic T : table
            ---@param t T
            ---@return T
            KeyValue = function(t)
                return setmetatable(t, weakKeyValue)
            end,
        },

        Class = ReUIClass.UIClass,
        Property = ReUIClass.Property,
    }
end
