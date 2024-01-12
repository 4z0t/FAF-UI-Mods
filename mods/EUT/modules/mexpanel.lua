local Bitmap = UMT.Controls.Bitmap
local Group = UMT.Controls.Group
local Text = UMT.Controls.Text
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Prefs = import("/lua/user/prefs.lua")
local Dragger = import("/lua/maui/dragger.lua").Dragger

local Options = UMT.Options.Mods["EUT"]
local From = import("/mods/UMT/modules/linq.lua").From
local LayoutFor = UMT.Layouter.ReusedLayoutFor

local mexCategories = import("mexcategories.lua").mexCategories
local MexManager = import("mexmanager.lua")

local mexPanel
local upgradeTexture = "/mods/EUT/textures/upgrade.dds"
local pausedTexture = "/textures/ui/common/game/strategicicons/pause_rest.dds"

function init()
    local parent = import("/lua/ui/game/gamemain.lua").GetStatusCluster()
    if not IsDestroyed(mexPanel) then
        mexPanel:Destroy()
    end
    mexPanel = MexPanel(parent)
end

local function MexPanelHandleEvent(control, event, category)
    local id = control.id
    if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
        if event.Modifiers.Right then
            if category.isPaused ~= nil then
                if event.Modifiers.Ctrl then
                    if category.isPaused then
                        MexManager.UnPauseBest(id)
                    else
                        MexManager.PauseWorst(id)
                    end
                else
                    MexManager.SetPausedAll(id, not category.isPaused)
                end
            else
                if event.Modifiers.Ctrl then
                    if id == 4 and Options.upgradeRounded() then
                        MexManager.UpgradeOnScreenCapped(id)
                    else
                        MexManager.UpgradeOnScreen(id)
                    end
                else
                    MexManager.SelectOnScreen(id)
                end
            end
        elseif event.Modifiers.Left then
            if category.isPaused ~= nil then
                if event.Modifiers.Ctrl then
                    MexManager.SelectBest(id)
                else
                    MexManager.SelectAll(id)
                end
            else
                if event.Modifiers.Ctrl then
                    if id == 4 and Options.upgradeRounded() then
                        MexManager.UpgradeAllCapped(id)
                    else
                        MexManager.UpgradeAll(id)
                    end
                else
                    MexManager.SelectAll(id)
                end
            end
        else
            -- middle mouse button
            return false -- calls parent HandleEvent -> move the Panel
        end
    end
    return true
end

-- data:
-- mexes={...}
-- progress = {}
function Update(data)
    if not IsDestroyed(mexPanel) then
        mexPanel:UpdateMexPanels(data)
    end
end

MexPanel = UMT.Class(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)
        self.Layouter = UMT.Layouter.RoundLayouter(UMT.Layouter.Functions.Div(Options.panelScale:Raw(), 100))

        local pos = self:_LoadPosition()
        LayoutHelpers.AtLeftTopIn(self, parent, pos.left, pos.top)

        self.Layouter(self)
            :Width(170)
            :Height(60)
            :EnableHitTest()
            :Over(parent, 100)

        self.contents = Group(self)

        self.Layouter(self.contents)
            :Width(168)
            :Height(50)
            :AtCenterIn(self)

        self:InitMexPanels(self.contents)
    end,

    InitMexPanels = function(self, parent)
        local previous
        parent.panels = {}
        for i, category in mexCategories do
            local panel = self:CreateMexCategoryPanel(parent, category)
            if previous then
                self.Layouter(panel):RightOf(previous, 2)
            else
                self.Layouter(panel):AtLeftTopIn(parent)
            end
            panel.id = i
            previous = panel
            table.insert(parent.panels, panel)
        end
    end,

    CreateMexCategoryPanel = function(self, parent, category)
        local group = Bitmap(parent)
        local layouter = self.Layouter

        layouter(group)
            :EnableHitTest()
            :Color("aa000000")
            :Width(22)
            :Height(50)


        group.category = category
        local iconName = "/textures/ui/common/game/strategicicons/" .. category.icon .. "_rest.dds"

        group.stratIcon = Bitmap(group)

        layouter(group.stratIcon)
            :DisableHitTest()
            :Texture(iconName)
            :Alpha(0.3)
            :AtTopCenterIn(group, 11)

        if category.isPaused then
            group.pauseIcon = Bitmap(group)
            layouter(group.pauseIcon)
                :DisableHitTest()
                :Texture(pausedTexture)
                :Width(24)
                :Height(24)
                :Alpha(0.3)
                :AtTopCenterIn(group, 8)
        end

        if category.isUpgrading then
            group.upgrIcon = Bitmap(group)

            layouter(group.upgrIcon)
                :DisableHitTest()
                :Texture(upgradeTexture)
                :Width(8)
                :Height(8)
                :Alpha(0.3)
                :AtTopCenterIn(group, 20, 5)
        end

        group.countLabel = Text(group)
        layouter(group.countLabel)
            :Color("ffaaaaaa")
            :DisableHitTest()
            :AtTopCenterIn(group, 1)
        group.countLabel:SetFont(UIUtil.bodyFont, 9)
        group.countLabel:SetText("0")

        if category.isUpgrading then
            group.ProgressBars = {}
            group.BackGroundBars = {}
            for i = 0, 9 do

                local progress = Bitmap(group)
                layouter(progress)
                    :DisableHitTest()
                    :Color("3300ff00")
                    :Width(group.Width)
                    :Height(2)
                    :AtLeftBottomIn(group, 0, i * 2)
                    :Hide()

                local bg = Bitmap(group)

                layouter(bg)
                    :DisableHitTest()
                    :Color("1100ff00")
                    :Width(group.Width)
                    :Height(2)
                    :AtLeftBottomIn(group, 0, i * 2)
                    :Hide()

                table.insert(group.ProgressBars, progress)
                table.insert(group.BackGroundBars, bg)
            end
        end

        group.HandleEvent = function(control, event)
            if event.Type == "MouseExit" then
                control:SetSolidColor("aa000000")
            elseif event.Type == "MouseEnter" then
                control:SetSolidColor("11ffffff")
            else
                return MexPanelHandleEvent(control, event, control.category)
            end
        end

        group.Update = function(control, data)
            local alpha
            if table.empty(data.mexes) then
                control.countLabel:SetText("")
                alpha = 0.3
            else
                local count = table.getn(data.mexes)
                alpha = 1
                control.countLabel:SetText(count)
            end

            control.stratIcon:SetAlpha(alpha)
            if control.upgrIcon then
                control.upgrIcon:SetAlpha(alpha)
            end
            if control.pauseIcon then
                control.pauseIcon:SetAlpha(alpha)
            end
            if control.ProgressBars then
                for i, bar in control.ProgressBars do
                    if data.progress then
                        local progress = data.progress[i] or 0
                        if progress > 0 then
                            control.ProgressBars[i]:Show()
                            control.BackGroundBars[i]:Show()
                            control.ProgressBars[i].Width:Set(control.BackGroundBars[i].Width() * progress)
                        else
                            control.ProgressBars[i]:Hide()
                            control.BackGroundBars[i]:Hide()
                        end
                    else
                        control.ProgressBars[i]:Hide()
                        control.BackGroundBars[i]:Hide()
                    end
                end
            end
        end

        return group
    end,

    UpdateMexPanels = function(self, data)
        if self:IsHidden() then
            return
        end
        for i, d in data do
            self.contents.panels[i]:Update(d)
        end
    end,

    HandleEvent = function(self, event)
        if event.Type == "ButtonPress" then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            local offY = event.MouseY - self.Top()
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(x - offX)
                self.Top:Set(y - offY)
                GetCursor():SetTexture(UIUtil.GetCursor("MOVE_WINDOW"))
            end
            drag.OnRelease = function(dragself)
                self:_SavePosition()
                GetCursor():Reset()
                drag:Destroy()
            end
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
        end
    end,

    _LoadPosition = function(self)
        return Prefs.GetFromCurrentProfile("EUTpos") or {
            left = 100,
            top = 50
        }
    end,

    _SavePosition = function(self)
        Prefs.SetToCurrentProfile("EUTpos", {
            left = LayoutHelpers.InvScaleNumber(self.Left()),
            top = LayoutHelpers.InvScaleNumber(self.Top())
        })
    end

}
