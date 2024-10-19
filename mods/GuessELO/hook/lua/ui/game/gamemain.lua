do
    local _GetArmiesTable = _G.GetArmiesTable
    _G.GetArmiesTable = function()
        local armiesTable = _GetArmiesTable()
        for i, client in ipairs(armiesTable.armiesTable) do
            if (not client.civilian) then
                client.nickname = string.format('Player %d', i)
            end
        end
        return armiesTable
    end


    local _GetRolloverInfo = _G.GetRolloverInfo
    _G.GetRolloverInfo = function()
        local _info = _GetRolloverInfo()
        if _info then
            _info.customName = nil
        end
        return _info
    end

end

do
    local _CreateUI = CreateUI
    function CreateUI(isReplay)
        _CreateUI(isReplay)
        ConExecute("ui_RenderCustomNames false")
    end

end
