local OriginalCreateUI = CreateUI
function CreateUI(isReplay)
    OriginalCreateUI(isReplay)
    import('/lua/ui/game/score.lua').CreateScoreUI()
    --import("/mods/4SB/modules/main.lua").Main(isReplay)
end
