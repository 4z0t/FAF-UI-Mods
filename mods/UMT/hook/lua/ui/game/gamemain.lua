do
    _ = __active_mods
        | UMT.LuaQ.where(function(v) return v.__umt and v.ui_only end)
        | UMT.LuaQ.select(function(v) return string.sub(v.location, 7) --[[cut "/mods/"]] end)
        | UMT.LuaQ.foreach(function(_, folderName)
            UMT.Mods.Add(folderName)
            LOG("UML: added " .. folderName)
        end)

    local _CreateUI = CreateUI
    function CreateUI(isReplay)

        _CreateUI(isReplay)
        if false then
            UMT.Mods.Add "UMT"
        end
        UMT.Mods.Load(isReplay)

    end
end
