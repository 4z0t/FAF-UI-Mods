local OldCreateUI = CreateUI
function CreateUI(isReplay)

    OldCreateUI(isReplay)
    -- your mod's UI may start here
    import('/mods/BetterColors/modules/Options.lua').Init()

end



