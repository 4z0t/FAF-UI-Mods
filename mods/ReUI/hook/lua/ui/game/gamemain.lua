do
    ---@diagnostic disable-next-line
    local _CreateUI = CreateUI
    function CreateUI(isReplay)
        ---@diagnostic disable-next-line:different-requires
        local ReUIOnCreateUI = import("/mods/ReUI/Core/Modules/OnCreateUI.lua")
        ReUIOnCreateUI.Init(isReplay)
        ReUIOnCreateUI.PreCreateUI(isReplay)
        _CreateUI(isReplay)
        ReUIOnCreateUI.PostCreateUI(isReplay)
        ReUIOnCreateUI.Dispose()
    end
end
