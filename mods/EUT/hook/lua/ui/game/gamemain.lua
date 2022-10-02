local oldCreateUI = CreateUI
function CreateUI(isReplay)
    oldCreateUI(isReplay)
    import('/mods/EUT/modules/main.lua').main(controls.status)
end