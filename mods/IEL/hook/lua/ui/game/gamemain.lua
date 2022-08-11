local originalCreateUI = CreateUI
function CreateUI(isReplay)
    originalCreateUI(isReplay)
    import("/mods/IEL/modules/main.lua").Main(isReplay)
end
