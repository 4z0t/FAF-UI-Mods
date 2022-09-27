do 
    local originalCreateUI = CreateUI
    function CreateUI(isReplay)
        originalCreateUI(isReplay)
        import("/mods/SRD/modules/main.lua").init(isReplay)
    end
end

