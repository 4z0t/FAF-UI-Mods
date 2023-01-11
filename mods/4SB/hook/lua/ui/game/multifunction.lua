local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

if ExistGlobal "UMT" and UMT.Version >= 8 then
    changeScoreboardColors = function(colorsTbl)
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
end
