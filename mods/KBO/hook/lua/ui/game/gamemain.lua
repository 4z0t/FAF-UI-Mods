
local originalCreateUI = CreateUI
function CreateUI(isReplay, parent)
    originalCreateUI(isReplay)
    import("/mods/KBO/modules/main.lua").init(isReplay)
end
