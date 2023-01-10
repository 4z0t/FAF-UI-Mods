local originalCreateUI = CreateUI
function CreateUI(isReplay)
    originalCreateUI(isReplay)
    import("/mods/TUC/modules/main.lua").Main(isReplay)
end