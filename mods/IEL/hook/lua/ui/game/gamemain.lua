local originalCreateUI = CreateUI
function CreateUI(isReplay, parent)
    originalCreateUI(isReplay)
    import("/mods/IEL/modules/main.lua").main(isReplay)
end
