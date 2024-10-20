do
    local _GetArmiesTable = _G.GetArmiesTable

    local function ShuffleColors()
        local armiesTable = _GetArmiesTable()
        local colors = {}
        for i, client in ipairs(armiesTable.armiesTable) do
            if (not client.civilian) then
                client.nickname = string.format('Player %d', i)
                table.insert(colors, client.color)
            end
        end
        colors = table.shuffle(colors)
        TeamColorMode(table.concat(colors, ","))
        TeamColorMode(true)
        for i, client in ipairs(armiesTable.armiesTable) do
            if (not client.civilian) then
                client.color = colors[i]
            end
        end
        return armiesTable
    end

    local once = true

    _G.GetArmiesTable = function()
        -- if once then
        --     once = false
        --     return ShuffleColors()
        -- end
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

    local _CreateUI = CreateUI
    function CreateUI(isReplay)
        _CreateUI(isReplay)
        ConExecute("ui_RenderCustomNames false")
    end

end
