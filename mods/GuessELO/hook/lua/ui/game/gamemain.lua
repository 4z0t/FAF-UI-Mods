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

    ---@param armiesTable ArmyInfo[]
    local function CreatePlayersList(armiesTable)
        local UIUtil = import("/lua/ui/uiutil.lua")
        local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
        local sessionInfo = SessionGetScenarioInfo()
        local parent = GetFrame(0)
        local prev = nil
        for i, client in ipairs(armiesTable) do
            if (not client.civilian) then
                local text = UIUtil.CreateText(parent,
                    ("%d %s"):format(sessionInfo.Options.Ratings[client.nickname] or 0, client.nickname), 13, nil,
                    true)
                if prev then
                    LayoutHelpers.ReusedLayoutFor(text)
                        :Over(parent, parent:GetTopmostDepth() + 1)
                        :Below(prev, 4)
                        :Color(client.color)
                        :DisableHitTest()
                    else
                        LayoutHelpers.ReusedLayoutFor(text)
                        :Over(parent, parent:GetTopmostDepth() + 1)
                        :Left(10)
                        :Top(400)
                        :Color(client.color)
                        :DisableHitTest()
                end
                prev = text
            end
        end

    end

    local function CreateRevealButton()
        local UIUtil = import("/lua/ui/uiutil.lua")
        local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

        local parent = GetFrame(0)
        local btn = UIUtil.CreateButtonWithDropshadow(parent, '/BUTTON/medium/', "Reveal")
        LayoutHelpers.ReusedLayoutFor(btn)
            :Over(parent, parent:GetTopmostDepth() + 1)
            :Left(10)
            :Top(500)
            :EnableHitTest()
            :End()

        btn.OnClick = function(self, mods)
            local armiesTable = _GetArmiesTable()
            CreatePlayersList(armiesTable.armiesTable)
            self:Destroy()
        end

    end

    local _CreateUI = CreateUI
    function CreateUI(isReplay)
        _CreateUI(isReplay)
        ConExecute("ui_RenderCustomNames false")
        CreateRevealButton()
    end

end
