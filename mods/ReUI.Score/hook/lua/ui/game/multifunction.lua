local function ChangeColors(colorsTbl)
    local scoreboard = ReUI.UI.Global["ScoreBoard"]
    if IsDestroyed(scoreboard) then
        return
    end
    if colorsTbl then
        for armyID, line in scoreboard:GetArmyViews() do
            if colorsTbl[armyID] then
                defaultScoreboardColors[armyID] = line.ArmyColor()
                line.ArmyColor = colorsTbl[armyID]
            end
        end
    else
        for armyID, line in scoreboard:GetArmyViews() do
            if defaultScoreboardColors[armyID] then
                line.ArmyColor = defaultScoreboardColors[armyID]
            end
        end
    end
end

changeScoreboardColors = function(colorsTbl)
    local ok, err = pcall(ChangeColors, colorsTbl)
    if not ok then
        WARN(err)
    end
end
