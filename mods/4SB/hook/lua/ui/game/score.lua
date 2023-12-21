local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

if ExistGlobal "UMT" and UMT.Version >= 11 then

    local ScoreBoards = import("/mods/4SB/modules/ScoreBoard.lua")
    local LayoutFor = UMT.Layouter.ReusedLayoutFor

    local layouts = {
        ["minimalictic"] = false,
        ["semi glow border"] = import("/mods/4SB/modules/Layouts/SemiGlowBorder.lua").Layout,
        ["glow border"] = import("/mods/4SB/modules/Layouts/GameGlowBorder.lua").Layout,
        ["window border"] = import("/mods/4SB/modules/Layouts/GameWindowFrame.lua").Layout
    }

    local replayLayouts = {
        ["minimalictic"] = false,
        ["glow border"] = import("/mods/4SB/modules/Layouts/ReplayGlowBorder.lua").Layout,
        ["window border"] = import("/mods/4SB/modules/Layouts/ReplayWindowFrame.lua").Layout
    }
    function CreateScoreUI()
        if not IsDestroyed(controls.scoreBoard) then return end


        local isCampaign = import('/lua/ui/campaign/campaignmanager.lua').campaignMode
        local isReplay   = import("/lua/ui/game/gamemain.lua").GetReplayState()

        local Options = import("/mods/4SB/modules/Options.lua")
        Options.Init(isReplay or IsObserver())

        local scoreboard
        if isReplay or IsObserver() then
            ---@type ReplayScoreBoard
            scoreboard = ScoreBoards.ReplayScoreBoard(GetFrame(0), not isCampaign)

            Options.replayStyle.OnChange = function(var)
                scoreboard.Layout = replayLayouts[var()]
            end
            scoreboard.Layout = replayLayouts[Options.replayStyle()]
        else
            ---@type ScoreBoard
            scoreboard = ScoreBoards.ScoreBoard(GetFrame(0), not isCampaign)

            Options.style.OnChange = function(var)
                scoreboard.Layout = layouts[var()]
            end
            scoreboard.Layout = layouts[Options.style()]

        end

        scoreboard.Layouter.Scale = function()
            return Options.scoreboardScale() / 100
        end

        Options.scoreboardScale.OnChange = function()
            scoreboard:ResetWidthComponents()
            scoreboard:ApplyToViews(function(armyId, view)
                view:ResetFont()
            end)
        end

        Options.player.font.name.OnChange = function(var)
            scoreboard:ResetWidthComponents()
            scoreboard:ApplyToViews(function(armyId, view)
                view:ResetFont()
            end)
        end

        Options.teamColorAsBG.OnChange = function(var)

            local _teamColorAsBG = var()
            local _teamColorAlpha = Options.teamColorAlpha()

            scoreboard:ApplyToViews(function(armyId, armyView)
                if _teamColorAsBG then
                    LayoutFor(armyView._color)
                        :Fill(armyView)
                        :Color(UMT.ColorUtils.SetAlpha(armyView.TeamColor(), _teamColorAlpha))
                else
                    LayoutFor(armyView._color)
                        :Top(armyView.Top)
                        :Bottom(armyView.Bottom)
                        :Right(armyView.Left)
                        :ResetLeft()
                        :Width(3)
                        :Color(armyView.TeamColor)
                end
            end)

        end

        Options.teamColorAlpha.OnChange = Options.teamColorAsBG.OnChange

        Options.useDivisions.OnChange = function(var)
            local _useDivisions = var()

            scoreboard:ApplyToViews(function(armyId, armyView)
                if _useDivisions and armyView.Division ~= "" then
                    armyView._div:SetAlpha(1)
                    armyView._rating:SetAlpha(0)
                else
                    armyView._rating:SetAlpha(1)
                    armyView._div:SetAlpha(0)
                end
            end)

        end

        Options.useNickNameArmyColor.OnChange = function(var)
            local useNickNameColor = var()
            scoreboard:ApplyToViews(function(armyId, armyView)
                if useNickNameColor then
                    armyView.NameColor = armyView.ArmyColor
                    armyView.RatingColor = armyView.PlainColor
                else
                    armyView.NameColor = armyView.PlainColor
                    armyView.RatingColor = armyView.ArmyColor
                end
            end)
        end

        controls.scoreBoard = scoreboard
        SetLayout()
        GameMain.AddBeatFunction(Update, true)

        scoreboard.OnDestroy = function(self)
            GameMain.RemoveBeatFunction(Update)
        end

        Options.snowflakes.OnChange = function(var)
            if var() then
                if scoreboard.snowflakes then
                    return
                end
                scoreboard.snowflakes = UMT.Controls.Group(scoreboard)
                LayoutFor(scoreboard.snowflakes)
                    :Fill(scoreboard)
                    :DisableHitTest(true)

                local SnowFlake = UMT.Views.Snowflake
                local snowFlakeCount = Options.snowflakesCount()
                local speed =  Options.snowflakesSpeed()
                for i = 1, snowFlakeCount do
                    SnowFlake(
                        scoreboard.snowflakes,
                        speed,
                        math.random() * 2,
                        math.random(scoreboard.snowflakes.Width()),
                        math.random(scoreboard.snowflakes.Height())
                    )
                end
            elseif scoreboard.snowflakes then
                scoreboard.snowflakes:Destroy()
                scoreboard.snowflakes = nil
            end
        end
        Options.snowflakesCount.OnChange = function()
            if not Options.snowflakes() then return end
            
            if scoreboard.snowflakes then
                scoreboard.snowflakes:Destroy()
            end
            
            scoreboard.snowflakes = UMT.Controls.Group(scoreboard)
            LayoutFor(scoreboard.snowflakes)
                :Fill(scoreboard)
                :DisableHitTest(true)
                
                local SnowFlake = UMT.Views.Snowflake
                local snowFlakeCount =  Options.snowflakesCount()
                local speed =  Options.snowflakesSpeed()
                for i = 1, snowFlakeCount do
                SnowFlake(
                    scoreboard.snowflakes,
                    speed,
                    math.random() * 2,
                    math.random(scoreboard.snowflakes.Width()),
                    math.random(scoreboard.snowflakes.Height())
                )
            end
        end

        Options.snowflakesSpeed.OnChange = Options.snowflakesCount.OnChange

        Options.useNickNameArmyColor:OnChange()
        Options.teamColorAlpha:OnChange()
        Options.teamColorAsBG:OnChange()
        Options.useDivisions:OnChange()
        Options.scoreboardScale:OnChange()
        Options.snowflakes:OnChange()
        Options.snowflakesCount:OnChange()
        Options.snowflakesSpeed:OnChange()

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
            LayoutHelpers.AtTopIn(controls.scoreBoard, GetFrame(0), 20)
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

else
    local OldCreateScoreUI = CreateScoreUI
    function CreateScoreUI()
        for i = 1, 10 do
            print "UI MOD TOOLS NOT FOUND! 4z0t's scoreboard requires UI MOD TOOLS to function!"
        end
        return OldCreateScoreUI()
    end

    WARN("UI MOD TOOLS NOT FOUND! 4z0t's scoreboard requires UI MOD TOOLS to function!")
end
function GetScoreCache()
    return ScoresCache
end
