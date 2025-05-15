local TableInsert = table.insert
local _pcall = pcall

local Loader = import("/mods/ReUI.Core/Modules/Loader.lua")


---@type OnCreateUICallback[]
local preCreateCallbacks
---@type OnCreateUICallback[]
local postCreateCallbacks
---@param isReplay boolean
function Init(isReplay)
    Loader.Init(isReplay)
    preCreateCallbacks = {}
    postCreateCallbacks = {}
    for _, mod in __active_mods do
        if mod.ReUI and mod.ui_only then
            Loader.Load(mod.ReUI)
        end
    end
end

---@param callback fun(isReplay:boolean)
function AddPreCreateCallback(callback)
    TableInsert(preCreateCallbacks, callback)
end

---@param callback fun(isReplay:boolean)
function AddPostCreateCallback(callback)
    TableInsert(postCreateCallbacks, callback)
end

---@param isReplay boolean
function PreCreateUI(isReplay)
    for _, callback in preCreateCallbacks do
        local ok, result = _pcall(callback, isReplay)
        if not ok then
            WARN(result)
        end
    end
end

---@param isReplay boolean
function PostCreateUI(isReplay)
    for _, callback in postCreateCallbacks do
        local ok, result = _pcall(callback, isReplay)
        if not ok then
            WARN(result)
        end
    end
end

function Dispose()
    ---@diagnostic disable-next-line:cast-local-type
    preCreateCallbacks = nil
    ---@diagnostic disable-next-line:cast-local-type
    postCreateCallbacks = nil
    Loader.Dispose()
end
