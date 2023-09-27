local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

if ExistGlobal "UMT" and UMT.Version >= 11 then
    changeScoreboardColors = function(colorsTbl)
        local scoreBoard = import('/lua/ui/game/score.lua').controls.scoreBoard
        if colorsTbl then
            for armyID, line in scoreBoard:GetArmyViews() do
                if colorsTbl[armyID] then
                    defaultScoreboardColors[armyID] = line.ArmyColor()
                    line.ArmyColor = colorsTbl[armyID]
                end
            end
        else
            for armyID, line in scoreBoard:GetArmyViews() do
                if defaultScoreboardColors[armyID] then
                    line.ArmyColor = defaultScoreboardColors[armyID]
                end
            end
        end
    end
else
    WARN("UI MOD TOOLS NOT FOUND! 4z0t's scoreboard requires UI MOD TOOLS to function!")
end
