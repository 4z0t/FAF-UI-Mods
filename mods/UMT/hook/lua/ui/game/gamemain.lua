
local originalCreateUI = CreateUI
function CreateUI(isReplay, parent)
    originalCreateUI(isReplay)
    import("/mods/UMT/modules/main.lua").init(isReplay)
end
