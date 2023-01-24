do
    local OldCreateUI = CreateUI
    function CreateUI(isReplay)
        OldCreateUI(isReplay)
        import('/mods/BetterColors/modules/Options.lua').Init()
    end
end
