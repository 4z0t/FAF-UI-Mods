do 
    local originalCreateUI = CreateUI
    function CreateUI(isReplay, parent)
        originalCreateUI(isReplay)
        import("/mods/HBO/modules/main.lua").Main(isReplay)
    end
end
