local OriginalCreateUI = CreateUI
function CreateUI(isReplay)
    OriginalCreateUI(isReplay)
    import("/mods/4SB/modules/main.lua").Main(isReplay)
end