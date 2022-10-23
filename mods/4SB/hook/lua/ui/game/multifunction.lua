--TY STROGO FOR THIS PART OF CODE REALLY APPRECIATE
local function changeScoreboardColors(colorsTbl)
    local scoreBoard = import('/lua/ui/game/score.lua').controls.scoreBoard
    if colorsTbl then
        for armyID, line in scoreBoard:GetArmyViews() do
            if colorsTbl[armyID] then
                defaultScoreboardColors[armyID] = line:GetArmyColor()
                line:SetArmyColor(colorsTbl[armyID])
            end
        end
    else
        for armyID, line in scoreBoard:GetArmyViews() do
            if defaultScoreboardColors[armyID] then
                line:SetArmyColor(defaultScoreboardColors[armyID])
            end
        end
    end
end

local function calculateTeamColors()
    local finalString = ""
    local enemiesCounter = 1
    local alliesCounter = 1
    local armies = GetArmiesTable().armiesTable
    local focusArmy = GetFocusArmy()
    local colorsTbl = {}
    local tblSize

    colorsTbl[focusArmy] = teamColorSettings.colors.Player[1]

    for index, army in armies do
        if index ~= focusArmy then
            if army.civilian or IsNeutral(focusArmy, index) then
                colorsTbl[index] = teamColorSettings.colors.Neutral[1]
            elseif IsAlly(focusArmy, index) then
                colorsTbl[index] = teamColorSettings.colors.Allies[alliesCounter]
                alliesCounter = alliesCounter + 1
            else
                colorsTbl[index] = teamColorSettings.colors.Enemies[enemiesCounter]
                enemiesCounter = enemiesCounter + 1
            end
        end
    end
    if teamColorSettings.changeColorsInScore then
        changeScoreboardColors(colorsTbl)
    end

    tblSize = table.getn(colorsTbl)

    for k, v in colorsTbl do
        if k == 1 then
            finalString = string.lower(colorsTbl[k]) .. ","
        elseif k == tblSize then
            finalString = finalString .. string.lower(colorsTbl[k])
        else
            finalString = finalString .. string.lower(colorsTbl[k]) .. ","
        end
    end

    return finalString
end

local function CreateTeamColorSettings()
    if teamColorWindow then
        teamColorWindow:Destroy()
        teamColorWindow = nil
    end

    local window = teamColorWindow

    local width = 400
    local height = 350
    local columns = { [1] = 1, [2] = 8, [3] = 8, [4] = 1 }
    local columnsName = { [1] = "Player", [2] = "Allies", [3] = "Enemies", [4] = "Neutral" }

    local COLUMN_POSITIONS = { 1, 11, 47, 91, 133, 395, 465, 535, 605, 677, 749 }
    local COLUMN_WIDTHS = { 20, 20, 45, 45, 257, 59, 59, 59, 62, 62, 51 }

    window = CreateDropoutBG(false)
    window.Depth:Set(100)
    window.Width:Set(width)
    window.Height:Set(height)
    window:SetAlpha(0.95)
    LayoutHelpers.AtCenterIn(window, GetFrame(0))

    window.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            local offY = event.MouseY - self.Top()

            drag.OnMove = function(dragself, x, y)
                self.Left:Set(x - offX)
                self.Top:Set(y - offY)
                GetCursor():SetTexture(UIUtil.GetCursor('MOVE_WINDOW'))
            end

            drag.OnRelease = function(dragself)
                GetCursor():Reset()
                drag:Destroy()
            end

            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
        end
    end

    ---Close button---
    window.closeButton = UIUtil.CreateButtonStd(window, '/game/menu-btns/close', "", 12)
    LayoutHelpers.AtRightTopIn(window.closeButton, window, -10, -10)
    window.closeButton.OnClick = function(self, modifiers)
        window:Destroy()
        window = nil
    end

    --colorSelectors--
    local columnCounter = 1

    for key, val in columns do
        window[ columnsName[key] ] = {}
        while val > 0 do
            local newSlot = ColumnLayout(window, COLUMN_POSITIONS, COLUMN_WIDTHS)
            window[ columnsName[key] ][val] = newSlot
            newSlot.target = columnsName[key]
            newSlot.key = val
            newSlot.Width:Set(20)
            newSlot.Height:Set(10)
            if columnCounter == 1 then
                LayoutHelpers.AtLeftTopIn(newSlot, window, 30, 60 + 30 * (val - 1))
            else
                LayoutHelpers.AtLeftTopIn(newSlot, window, 30 + 90 * (columnCounter - 1), 60 + 30 * (val - 1))
            end

            newSlot.color = BitmapCombo(newSlot, gameColors, 1, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
            newSlot:AddChild(newSlot.color)
            LayoutHelpers.SetWidth(newSlot.color, COLUMN_WIDTHS[6])
            newSlot.color.OnClick = function(self, index)
                teamColorSettings.colors[newSlot.target][newSlot.key] = self._array[index]
                saveTeamColorsToPrefs()

                if GetButton('teamcolor')._checkState == "checked" then
                    TeamColorMode(calculateTeamColors())
                    TeamColorMode(true)
                end
            end

            if teamColorSettings.colors[newSlot.target][newSlot.key] then
                for k, color in newSlot.color._array do
                    if color == teamColorSettings.colors[newSlot.target][newSlot.key] then
                        newSlot.color:SetItem(k)
                        break
                    end
                end
            end
            val = val - 1
        end

        -- title
        local title = UIUtil.CreateText(window, columnsName[key], 20, UIUtil.bodyFont)
        LayoutHelpers.AtCenterIn(title, window[ columnsName[key] ][1], -30, 15)

        columnCounter = columnCounter + 1
    end

    --CheckBoxAutoEnable

    window.CheckBoxAutoEnable = UIUtil.CreateCheckbox(window, '/CHECKBOX/')
    window.CheckBoxAutoEnable.Height:Set(18)
    window.CheckBoxAutoEnable.Width:Set(18)

    if teamColorSettings.autoEnable == true then
        window.CheckBoxAutoEnable:SetCheck(true, true)
    else
        window.CheckBoxAutoEnable:SetCheck(false, true)
    end

    window.CheckBoxAutoEnable.OnCheck = function(self, checked)
        if checked then
            teamColorSettings.autoEnable = true
        else
            teamColorSettings.autoEnable = false
        end
        saveTeamColorsToPrefs()
    end

    LayoutHelpers.AtLeftBottomIn(window.CheckBoxAutoEnable, window, 20, 25)

    window.CheckBoxAutoEnable.text = UIUtil.CreateText(window, "Activate on game start", 14, UIUtil.bodyFont)

    LayoutHelpers.AtLeftTopIn(window.CheckBoxAutoEnable.text, window.CheckBoxAutoEnable, 20, 0)

    --CheckBoxScoreColors
    window.CheckBoxScoreColors = UIUtil.CreateCheckbox(window, '/CHECKBOX/')
    window.CheckBoxScoreColors.Height:Set(18)
    window.CheckBoxScoreColors.Width:Set(18)

    if teamColorSettings.changeColorsInScore == true then
        window.CheckBoxScoreColors:SetCheck(true, true)
    else
        window.CheckBoxScoreColors:SetCheck(false, true)
    end

    window.CheckBoxScoreColors.OnCheck = function(self, checked)
        if checked then
            teamColorSettings.changeColorsInScore = true
        else
            teamColorSettings.changeColorsInScore = false
        end
        saveTeamColorsToPrefs()
    end

    LayoutHelpers.AtLeftTopIn(window.CheckBoxScoreColors, window.CheckBoxAutoEnable, 0, 20)
    window.CheckBoxScoreColors.text = UIUtil.CreateText(window, "Change colors in scoreboard", 14, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(window.CheckBoxScoreColors.text, window.CheckBoxScoreColors, 20, 0)
end

function TeamColorHandler(self, modifiers)
    if modifiers.Right then
        CreateTeamColorSettings()
    else
        if self._checkState == "checked" then
            TeamColorMode(false)
            if teamColorSettings.changeColorsInScore then
                changeScoreboardColors()
            end
        else
            TeamColorMode(calculateTeamColors())
            TeamColorMode(true)
        end
    end
end

if teamColorSettings.autoEnable then
    ForkThread(function()
        WaitSeconds(0.5)
        TeamColorMode(calculateTeamColors())
        TeamColorMode(true)
        GetButton('teamcolor'):ToggleCheck()
    end)
end
