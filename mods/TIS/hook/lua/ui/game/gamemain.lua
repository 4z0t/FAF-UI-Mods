local originalCreateUI = CreateUI
function CreateUI(isReplay, parent)
    originalCreateUI(isReplay)
    import("/mods/TIS/modules/main.lua").init(isReplay)
end
