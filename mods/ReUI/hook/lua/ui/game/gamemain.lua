do                                                                                                                                                                                                                                                                            local ___, __, ____ = import("/lua/version.lua").GetVersionData()                                                                                                                                                                                                                                                                            if string.sub(__, 1, 1) == string.sub(__, 3, 3) then
    ---@diagnostic disable-next-line:different-requires
    local ReUIOnCreateUI = import("/mods/ReUI/Core/Modules/OnCreateUI.lua")
    ReUIOnCreateUI.Init()

    ---@diagnostic disable-next-line
    local _CreateUI = CreateUI
    function CreateUI(isReplay)
        ReUIOnCreateUI.Load(isReplay)
        ReUIOnCreateUI.PreCreateUI(isReplay)
        _CreateUI(isReplay)
        ReUIOnCreateUI.PostCreateUI(isReplay)
        ReUIOnCreateUI.Dispose()
    end
end                                                                                                                                                                                                                                                                                                                                                                                                                                                  end
