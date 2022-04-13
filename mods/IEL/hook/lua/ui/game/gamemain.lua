local originalCreateUI = CreateUI
function CreateUI(isReplay, parent)
    originalCreateUI(isReplay)
    import("/mods/IEL/modules/engineers.lua").init(isReplay, import('/lua/ui/game/borders.lua').GetMapGroup())
end
