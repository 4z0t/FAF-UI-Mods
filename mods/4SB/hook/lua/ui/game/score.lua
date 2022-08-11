local ScoreBoards = import("/mods/4SB/modules/ScoreBoard.lua")



function CreateScoreUI()
    if not IsDestroyed(controls.scoreBoard) then
        return
    end
    local isCampaign = import('/lua/ui/campaign/campaignmanager.lua').campaignMode
    local isReplay   = import("/lua/ui/game/gamemain.lua").GetReplayState()
    if isReplay or IsObserver() then
        controls.scoreBoard = ScoreBoards.ReplayScoreBoard(GetFrame(0), not isCampaign)
    else
        controls.scoreBoard = ScoreBoards.ScoreBoard(GetFrame(0), not isCampaign)
    end


    SetLayout()
    GameMain.AddBeatFunction(Update, true)

    controls.scoreBoard.OnDestroy = function(self)
        GameMain.RemoveBeatFunction(Update)
    end
end

function SetLayout()
    if IsDestroyed(controls.scoreBoard) then
        return
    end
    local avatarsControls = import('/lua/ui/game/avatars.lua').controls
    LayoutHelpers.AnchorToBottom(avatarsControls.avatarGroup, controls.scoreBoard, 10)
    if import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
        local objectivesControls = import('/lua/ui/game/objectives2.lua').controls
        LayoutHelpers.AnchorToBottom(controls.scoreBoard, objectivesControls.bg.bracketBottom, 10)
    else

    end
end

function Update()
    if IsDestroyed(controls.scoreBoard) then
        return
    end

    controls.scoreBoard:Update(currentScores)
    if currentScores then
        ScoresCache = currentScores
        currentScores = false
    end

end

function Contract()
    if IsDestroyed(controls.scoreBoard) then
        return
    end
    controls.scoreBoard:Hide()
end

function Expand()
    if IsDestroyed(controls.scoreBoard) then
        return
    end
    controls.scoreBoard:Show()
end

function ToggleScoreControl(state)
end

function InitialAnimation(state)

end

function NoteGameSpeedChanged(newSpeed)
    gameSpeed = newSpeed
    if not IsDestroyed(controls.scoreBoard) then
        controls.scoreBoard:UpdateGameSpeed(newSpeed)
    end
end

function ArmyAnnounce(army, text)
    LOG(army)
    LOG(text)
end

function GetScoreCache()
    return ScoresCache
end
