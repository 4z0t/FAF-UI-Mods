local originalCreateUI = CreateUI
function CreateUI(isReplay, parent)
    originalCreateUI(isReplay)
    import("/mods/SRD/modules/main.lua").init(isReplay)
end
