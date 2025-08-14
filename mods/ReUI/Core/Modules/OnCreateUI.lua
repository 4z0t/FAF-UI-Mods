local TableInsert = table.insert
local _pcall = pcall

---@diagnostic disable-next-line:different-requires
local Loader = import("Loader.lua")

function Init()
    Loader.Init()
    for _, mod in __active_mods do
        if mod.ReUI and mod.ui_only then
            Loader.Load(mod.ReUI)
        end
    end
end

---@type OnCreateUICallback[]
local preCreateCallbacks
---@type OnCreateUICallback[]
local postCreateCallbacks
---@param isReplay boolean
function Load(isReplay)
    preCreateCallbacks = {}
    postCreateCallbacks = {}
    Loader.LoadMains(isReplay)
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

    local errors = Loader.GetErrors()

    local ok, r = pcall(function()
        local ReceiveChatFromSim = import("/lua/ui/game/chat.lua").ReceiveChatFromSim
        for _, err in errors do
            ReceiveChatFromSim(GetFocusArmy(), {
                Chat = true,
                to = 'notify',
                text = err,
            })
        end
    end)
    if not ok then
        WARN(r)
    end
end

function Dispose()
    ---@diagnostic disable-next-line:cast-local-type
    preCreateCallbacks = nil
    ---@diagnostic disable-next-line:cast-local-type
    postCreateCallbacks = nil
    Loader.Dispose()
end
