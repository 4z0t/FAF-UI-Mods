do
    local _SetLayout = SetLayout
    function SetLayout()
        _SetLayout()
        import("/mods/AGP/modules/Main.lua").SetLayout()
    end
end
