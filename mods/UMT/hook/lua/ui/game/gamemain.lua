do
    local OriginalCreateUI = CreateUI
    function CreateUI(isReplay, parent)
        OriginalCreateUI(isReplay)
        import("/mods/UMT/modules/main.lua").Main(isReplay)
    end
end
