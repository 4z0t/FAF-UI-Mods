
local originalCreateUI = CreateUI
function CreateUI(isReplay, parent)
    originalCreateUI(isReplay)
    import("/mods/Beer/modules/main.lua").Main(isReplay)
end
