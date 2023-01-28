do
    local OldCreateUI = CreateUI
    function CreateUI(isReplay)

        OldCreateUI(isReplay)
        if true then
            UMT.Mods.Add "UMT"
        end
        UMT.Mods.Load(isReplay)

    end
end
