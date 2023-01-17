local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

if ExistGlobal "UMT" and UMT.Version >= 4 then
    local originalCreateUI = CreateUI
    function CreateUI(isReplay, parent)
        originalCreateUI(isReplay)
        import("/mods/TIS/modules/main.lua").main(isReplay)
    end
end
