ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.LINQ >= 1.3.0",
    "ReUI.UI >= 1.1.0",
    "ReUI.UI.Color >= 1.0.0",
    "ReUI.UI.Animation >= 1.1.0",
    "ReUI.UI.Controls >= 1.0.0",
    "ReUI.UI.Views >= 1.1.0",
    "ReUI.Options >= 1.0.0"
}

function Main(isReplay)
    local _IsDestroyed = IsDestroyed

    local Utils = import("Modules/Utils.lua")

    local ScoreHook = ReUI.Core.HookModule "/lua/ui/game/score.lua"

    ScoreHook("CreateScoreUI", function(field, module)
        return function()
            if not _IsDestroyed(ReUI.UI.Global["ScoreBoard"]) then
                return
            end

            local options = ReUI.Options.Mods["ReUI.Score"]

            local isCampaign = import('/lua/ui/campaign/campaignmanager.lua').campaignMode

            local scoreboard
            if isReplay or IsObserver() then
                ---@diagnostic disable-next-line:assign-type-mismatch
                ReUI.Score.Layouts["minimal"]       = false
                ReUI.Score.Layouts["glow border"]   = import("Modules/Layouts/ReplayGlowBorder.lua").Layout
                ReUI.Score.Layouts["window border"] = import("Modules/Layouts/ReplayWindowFrame.lua").Layout

                ---@type ReUI.Score.ReplayScoreBoard
                scoreboard = ReUI.Score.ReplayScoreBoard(GetFrame(0), not isCampaign)

                options.replayStyle:Bind(function(var)
                    scoreboard.Layout = ReUI.Score.Layouts[var()]
                end)
            else
                ---@diagnostic disable-next-line:assign-type-mismatch
                ReUI.Score.Layouts["minimal"]       = false
                ReUI.Score.Layouts["glow border"]   = import("Modules/Layouts/GameGlowBorder.lua").Layout
                ReUI.Score.Layouts["window border"] = import("Modules/Layouts/GameWindowFrame.lua").Layout

                ---@type ReUI.Score.ScoreBoard
                scoreboard = ReUI.Score.ScoreBoard(GetFrame(0), not isCampaign)

                options.style:Bind(function(var)
                    scoreboard.Layout = ReUI.Score.Layouts[var()]
                end)
            end

            --#region Options
            scoreboard.Layouter.Scale = ReUI.UI.LayoutFunctions.Div(options.scoreboardScale:Raw(), 100)

            options.scoreboardScale.OnChange = function()
                scoreboard:ResetWidthComponents()
                scoreboard:ApplyToViews(function(armyId, view)
                    view:ResetFont()
                end)
            end

            options.teamColorAsBG.OnChange = function(var)

                local _teamColorAsBG = options.teamColorAsBG()
                local _teamColorAlpha = options.teamColorAlpha()

                scoreboard:ApplyToViews(function(armyId, armyView)
                    if _teamColorAsBG then
                        armyView.Layouter(armyView._color)
                            :Fill(armyView)
                            :Color(ReUI.UI.Color.SetAlpha(armyView._teamColorBG(), _teamColorAlpha))
                    else
                        armyView.Layouter(armyView._color)
                            :Top(armyView.Top)
                            :Bottom(armyView.Bottom)
                            :Right(armyView.Left)
                            :ResetLeft()
                            :Width(3)
                            :Color(armyView._teamColorBG)
                    end
                end)

            end

            options.teamColorAlpha.OnChange = options.teamColorAsBG.OnChange

            options.useDivisions:Bind(function(var)
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

            end)

            local ResourceDisplay = import("Modules/ResourceDisplay.lua")
            ---@type  table<string, IResourceDisplay>
            local displays =
            {
                ["default"]                   = ResourceDisplay.DefaultResourceDisplay(),
                ["income+storage"]            = ResourceDisplay.PairResourceDisplay(),
                ["income+storage+maxstorage"] = ResourceDisplay.FullResourceDisplay(),
            }

            options.displayMode:Bind(function(var)
                ---@type string
                local mode = var()

                scoreboard:SetDisplay(displays[mode] or displays["default"])

                scoreboard:ApplyToViews(function(armyId, armyView)
                    armyView:ResetFont()
                    ---@cast armyView AllyView
                    if armyView.isAlly then
                        scoreboard._display:Apply(armyView)
                    end
                end)
            end)

            options.player.color.name:Bind(function(opt)
                local mode = opt()

                scoreboard:ApplyToViews(function(armyId, armyView)
                    if mode == "plain" then
                        armyView.NameColor = armyView.PlainColor
                    elseif mode == "player color" then
                        armyView.NameColor = armyView.ArmyColor
                    elseif mode == "team color" then
                        armyView.NameColor = armyView.TeamColor
                    end
                end)
            end)

            options.player.color.icon:Bind(function(opt)
                local mode = opt()

                scoreboard:ApplyToViews(function(armyId, armyView)
                    if mode == "plain" then
                        armyView._faction.Mode = "plain"
                        armyView._faction.MaskColor = "ffffffff"
                    elseif mode == "player color" then
                        armyView._faction.Mode = "color"
                        armyView._faction.MaskColor = armyView.ArmyColor
                    elseif mode == "team color" then
                        armyView._faction.Mode = "color"
                        armyView._faction.MaskColor = armyView.TeamColor
                    end
                end)
            end)

            options.player.color.rating:Bind(function(opt)
                local mode = opt()

                scoreboard:ApplyToViews(function(armyId, armyView)
                    if mode == "plain" then
                        armyView.RatingColor = armyView.PlainColor
                    elseif mode == "player color" then
                        armyView.RatingColor = armyView.ArmyColor
                    elseif mode == "team color" then
                        armyView.RatingColor = armyView.TeamColor
                    end
                end)
            end)

            options.teamColorAlpha:OnChange()
            options.scoreboardScale:OnChange()
            --#endregion

            ReUI.UI.Global["ScoreBoard"] = scoreboard

            module.controls.scoreBoard = scoreboard

            local GM = import("/lua/ui/game/gamemain.lua")
            GM.AddBeatFunction(module.Update, true)

            scoreboard.OnDestroy = function(self)
                GM.RemoveBeatFunction(module.Update)
            end
        end
    end)

    ScoreHook("DisplayPing", function(field, module)
        return function(parent, pingData)
            local scoreboard = ReUI.UI.Global["ScoreBoard"]
            if _IsDestroyed(scoreboard) then
                return
            end

            scoreboard:DisplayPing(pingData)
        end
    end)

    ScoreHook("SetLayout", function(field, module)
        return function()
            local scoreboard = ReUI.UI.Global["ScoreBoard"]
            if _IsDestroyed(scoreboard) then
                return
            end

            local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

            local avatarsControls = import('/lua/ui/game/avatars.lua').controls
            LayoutHelpers.AnchorToBottom(avatarsControls.avatarGroup, scoreboard, 10)
            if import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
                local objectivesControls = import('/lua/ui/game/objectives2.lua').controls
                LayoutHelpers.AnchorToBottom(scoreboard, objectivesControls.bg.bracketBottom, 10)
            else
                LayoutHelpers.AtTopIn(scoreboard, GetFrame(0)--[[@as Frame]] , 20)
            end
        end
    end)

    ScoreHook("Update", function(field, module)
        local globalControls = ReUI.UI.Global
        return function()
            local scoreboard = globalControls["ScoreBoard"]
            if _IsDestroyed(scoreboard) then
                return
            end

            scoreboard:Update(module.currentScores and module.GetScoreCache())
        end
    end)

    ScoreHook("Contract", function(field, module)
        return function()
            local scoreboard = ReUI.UI.Global["ScoreBoard"]
            if _IsDestroyed(scoreboard) then
                return
            end
            scoreboard:Hide()
        end
    end)

    ScoreHook("Expand", function(field, module)
        return function()
            local scoreboard = ReUI.UI.Global["ScoreBoard"]
            if _IsDestroyed(scoreboard) then
                return
            end

            scoreboard:Show()
        end
    end)

    ScoreHook("ToggleScoreControl", function(field, module)
        return function(state)

        end
    end)

    ScoreHook("InitialAnimation", function(field, module)
        return function(state)
            local scoreboard = ReUI.UI.Global["ScoreBoard"]
            if _IsDestroyed(scoreboard) then
                return
            end
            scoreboard:InitialAnimation()
        end
    end)

    ScoreHook("NoteGameSpeedChanged", function(field, module)
        return function(newSpeed)
            local scoreboard = ReUI.UI.Global["ScoreBoard"]
            if _IsDestroyed(scoreboard) then
                return
            end

            scoreboard.GameSpeed = newSpeed
        end
    end)

    ScoreHook("ArmyAnnounce", function(field, module)
        return function(army, text)
            local scoreboard = ReUI.UI.Global["ScoreBoard"]
            if _IsDestroyed(scoreboard) then
                return
            end
            local armyLine = scoreboard:GetArmyViews()[army]
            import("/lua/ui/game/announcement.lua").CreateAnnouncement(LOC(text)--[[@as string]] , armyLine)
        end
    end)

    --- New function that caches score data
    ScoreHook("GetScoreCache", function(field, module)
        local scoresCache = false
        return function()
            local curScores = module.currentScores
            if curScores then
                module.currentScores = false
                scoresCache = curScores
            end
            return scoresCache
        end
    end)

    ReUI.Core.OnPostCreateUI(function(isReplay)
        import('/lua/ui/game/score.lua').CreateScoreUI()
    end)

    ReUI.Core.Hook("/lua/ui/controls/worldview.lua", "WorldView", function(WorldView, module)
        ---@class PingData
        ---@field Owner integer
        ---@field Location Vector
        ---@field ArrowColor  'red'|'yellow'| 'blue'
        ---@field Lifetime number
        ---@field Marker boolean
        ---@field Renew boolean

        local Text = ReUI.UI.Controls.Text
        local LazyVar = import('/lua/lazyvar.lua').Create
        local GetArmiesFormattedTable = Utils.GetArmiesFormattedTable

        ---@class TempMarker : ReUI.UI.Controls.Text
        ---@field PosX LazyVar<number>
        ---@field PosY LazyVar<number>
        ---@field _onFrameTime number
        ---@field _position Vector
        ---@field _worldView WorldView
        local TempMarker = ReUI.Core.Class(Text)
        {
            LifeTime = 5,

            __init = function(self, parent, position)
                Text.__init(self, parent)

                self._worldView = parent
                self._position = position
                self._onFrameTime = 0

                self.PosX = LazyVar()
                self.PosY = LazyVar()
                self.Left:Set(ReUI.UI.LayoutFunctions.Floor(function() return parent.Left() + self.PosX() -
                        self.Width() * 0.5
                end))
                self.Top:Set(ReUI.UI.LayoutFunctions.Floor(function() return parent.Top() + self.PosY() -
                        self.Height() * 0.5
                end))
                self:DisableHitTest()
                self:SetNeedsFrameUpdate(true)
            end,

            ---@param self TempMarker
            ---@param delta number
            OnFrame = function(self, delta)
                self._onFrameTime = self._onFrameTime + delta
                if self._onFrameTime > self.LifeTime then
                    self:Destroy()
                    return
                end
                local screenPos = self._worldView:Project(self._position)
                self.PosX:Set(screenPos.x)
                self.PosY:Set(screenPos.y)
            end
        }
        local WorldView__init = WorldView.__init
        local WorldViewDisplayPing = WorldView.DisplayPing

        WorldView.__init = function(self, ...)
            ---@diagnostic disable-next-line:deprecated
            WorldView__init(self, unpack(arg))
            self._isMiniMap = arg[4] or false
        end

        ---@param self WorldView
        ---@param pingData PingData
        WorldView.DisplayTempMarker = function(self, pingData)
            if pingData.Marker or pingData.Renew or self._isMiniMap then return end

            ---@type TempMarker
            local marker = TempMarker(self, pingData.Location)
            marker.LifeTime = pingData.Lifetime

            local playerData = ReUI.LINQ.Enumerate(GetArmiesFormattedTable())
                :First(function(v) return v.id == pingData.Owner + 1 end)

            marker:SetText(playerData.nickname)
            marker:Show()
            marker:SetFont("Arial", 13)
        end

        ---@param self WorldView
        ---@param pingData PingData
        WorldView.DisplayPing = function(self, pingData)
            import("/lua/ui/game/score.lua").DisplayPing(self, pingData)
            self:DisplayTempMarker(pingData)
            return WorldViewDisplayPing(self, pingData)
        end

        return WorldView
    end)

    local ScoreBoardModule = import("Modules/ScoreBoard.lua")

    return {
        Layouts = {},
        ScoreBoard = ScoreBoardModule.ScoreBoard,
        ReplayScoreBoard = ScoreBoardModule.ReplayScoreBoard,
    }
end
