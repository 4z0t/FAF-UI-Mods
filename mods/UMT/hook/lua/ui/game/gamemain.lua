do
    local Fun = UMT.Functional.Functors
    local addUMTMods = Fun.enumerate(__active_mods)
        | Fun.where(function(v) return v.__umt and v.ui_only end)
        | Fun.select(function(v) return string.sub(v.location, 7) --[[cut "/mods/"]] end)
        | Fun.foreach(function(_, folderName)
            UMT.Mods.Add(folderName)
            LOG("UML: added " .. folderName)
        end)
        | Fun.execute

    local _CreateUI = CreateUI
    function CreateUI(isReplay)

        _CreateUI(isReplay)
        if false then
            UMT.Mods.Add "UMT"
        end
        UMT.Mods.Load(isReplay)

    end
end

local LOG = LOG
local WARN = WARN
local error = error
local StringFormat = string.format
local unpack = unpack

function _G.LogF(formatString, ...)
    LOG(StringFormat(formatString, unpack(arg)))
end

function _G.WarnF(formatString, ...)
    WARN(StringFormat(formatString, unpack(arg)))
end

function _G.ErrorF(formatString, ...)
    error(StringFormat(formatString, unpack(arg)))
end
