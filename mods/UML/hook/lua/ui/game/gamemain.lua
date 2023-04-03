do
    _ = __active_mods | UMT.LuaQ.foreach(function(k, v)
        if v.__umt then
            local folderName = string.sub(v.location, 7) -- cut "/mods/"
            UMT.Mods.Add(folderName)
            LOG("UML: added " .. folderName)
        end
    end)
end
