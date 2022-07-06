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


    if isCampaign then
        local objectivesControls = import('/lua/ui/game/objectives2.lua').controls
        LayoutHelpers.AnchorToBottom(controls.scoreBoard, objectivesControls.bg.bracketBottom, 10)
    else

    end

    GameMain.AddBeatFunction(_OnBeat, true)
end

function _OnBeat()
    if not controls.scoreBoard then
        return
    end
    if currentScores then

        currentScores = false
    end
end

function InitialAnimation(state)

end
