local ScoreBoards = import("/mods/4SB/modules/ScoreBoard.lua")



function CreateScoreUI()
    if controls.scoreBoard then
        return
    end
    local isCampaign = import('/lua/ui/campaign/campaignmanager.lua').campaignMode
    local isReplay   = import("/lua/ui/game/gamemain.lua").GetReplayState()
    if isReplay then
        controls.scoreBoard = ScoreBoards.ReplayScoreBoard(GetFrame(0))
    else
        controls.scoreBoard = ScoreBoards.ScoreBoard(GetFrame(0))
    end


    SetLayout()
    GameMain.AddBeatFunction(_OnBeat, true)
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

function _OnBeat()
    if IsDestroyed(controls.scoreBoard) then
        return
    end

    controls.scoreBoard:Update(currentScores)
    if currentScores then
        ScoresCache = currentScores
        currentScores = false
    end

end

function ToggleScoreControl(state)
end

function InitialAnimation(state)

end

function NoteGameSpeedChanged(newSpeed)

end

function ArmyAnnounce(army, text)

end

function GetScoreCache()
    return ScoresCache
end
