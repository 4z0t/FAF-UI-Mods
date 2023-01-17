local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

if ExistGlobal "UMT" and UMT.Version >= 8 then
    local OriginalCreateUI = CreateUI
    function CreateUI(isReplay)
        OriginalCreateUI(isReplay)
        import('/lua/ui/game/score.lua').CreateScoreUI()
    end
else
    WARN("UI MOD TOOLS NOT FOUND! 4z0t's scoreboard requires UI MOD TOOLS to function!")
end
