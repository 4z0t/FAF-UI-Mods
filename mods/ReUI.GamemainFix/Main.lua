ReUI.Require
{
    "ReUI.Core >= 1.0.0",
}


function Main()
    ReUI.Core.Hook("/lua/ui/game/gamemain.lua", "GetGameParent", function(field, module)
        return function()
            ---@diagnostic disable-next-line:param-type-mismatch
            return import("/lua/ui/uiutil.lua").CreateScreenGroup(GetFrame(0), "GameMain ScreenGroup")
        end
    end)


    ReUI.Core.Hook("/lua/ui/uiutil.lua", "CreateScreenGroup", function(field, module)
        local gmScreenGroup
        return function(root, name)
            if name == "GameMain ScreenGroup" then
                gmScreenGroup = gmScreenGroup or field(root, name)
                return gmScreenGroup
            end
            return field(root, name)
        end
    end)
end
