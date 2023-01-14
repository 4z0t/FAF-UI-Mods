local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

if ExistGlobal "UMT" and UMT.Version >= 8 then

    local ScoreBoards = import("/mods/4SB/modules/ScoreBoard.lua")


    local layouts = {
        ["default"] = false,
        ["semi glow border"] = import("/mods/4SB/modules/Layouts/SemiGlowBorder.lua").Layout
    }

    local replayLayouts = {
        ["default"] = false,
        ["glow border"] = import("/mods/4SB/modules/Layouts/ReplayGlowBorder.lua").Layout
    }
    function CreateScoreUI()
        if not IsDestroyed(controls.scoreBoard) then return end


        local isCampaign = import('/lua/ui/campaign/campaignmanager.lua').campaignMode
        local isReplay   = import("/lua/ui/game/gamemain.lua").GetReplayState()

        local Options = import("/mods/4SB/modules/Options.lua")
        Options.Init()

        local scoreboard
        if isReplay or IsObserver() then
            scoreboard = ScoreBoards.ReplayScoreBoard(GetFrame(0), not isCampaign)

            Options.style.OnChange = function(var)
                scoreboard.Layout = replayLayouts[var()]
            end
            scoreboard.Layout = replayLayouts[Options.style()]
        else
            scoreboard = ScoreBoards.ScoreBoard(GetFrame(0), not isCampaign)

            Options.style.OnChange = function(var)
                scoreboard.Layout = layouts[var()]
            end
            scoreboard.Layout = layouts[Options.style()]

        end

        Options.player.font.name.OnChange = function(var)
            scoreboard:ResetArmyData()
        end


        SetLayout()
        GameMain.AddBeatFunction(Update, true)

        scoreboard.OnDestroy = function(self)
            GameMain.RemoveBeatFunction(Update)
        end

        controls.scoreBoard = scoreboard
    end

    function DisplayPing(parent, pingData)
        if IsDestroyed(controls.scoreBoard) then return end
        controls.scoreBoard:DisplayPing(pingData)

    end

    function SetLayout()
        if IsDestroyed(controls.scoreBoard) then return end


        local avatarsControls = import('/lua/ui/game/avatars.lua').controls
        LayoutHelpers.AnchorToBottom(avatarsControls.avatarGroup, controls.scoreBoard, 10)
        if import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
            local objectivesControls = import('/lua/ui/game/objectives2.lua').controls
            LayoutHelpers.AnchorToBottom(controls.scoreBoard, objectivesControls.bg.bracketBottom, 10)
        else

        end
    end

    function Update()
        if IsDestroyed(controls.scoreBoard) then return end

        controls.scoreBoard:Update(currentScores)
        if currentScores then
            ScoresCache = currentScores
            currentScores = false
        end

    end

    function Contract()
        if IsDestroyed(controls.scoreBoard) then return end

        controls.scoreBoard:Hide()
    end

    function Expand()
        if IsDestroyed(controls.scoreBoard) then return end


        controls.scoreBoard:Show()
    end

    function ToggleScoreControl(state)
    end

    function InitialAnimation(state)
        if IsDestroyed(controls.scoreBoard) then return end

        controls.scoreBoard:InitialAnimation()
    end

    function NoteGameSpeedChanged(newSpeed)
        gameSpeed = newSpeed
        if IsDestroyed(controls.scoreBoard) then return end


        controls.scoreBoard.GameSpeed = newSpeed

    end


end
function GetScoreCache()
    return ScoresCache
end
