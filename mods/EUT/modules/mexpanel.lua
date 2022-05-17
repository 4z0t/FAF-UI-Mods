local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Prefs = import("/lua/user/prefs.lua")
local Dragger = import("/lua/maui/dragger.lua").Dragger

local mexCategories = import("mexcategories.lua").mexCategories
local From = import("/mods/UMT/modules/linq.lua").From
local MexManager = import("mexmanager.lua")

local mexPanel
local upgradeTexture = "/mods/EUT/textures/upgrade.dds"
local pausedTexture = "/textures/ui/common/game/strategicicons/pause_rest.dds"

function init()
    if not IsDestroyed(mexPanel) then
        mexPanel:Destroy()
    end
    mexPanel = MexPanel(GetFrame(0))
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
                    MexManager.UpgradeOnScreen(id)
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
                    MexManager.UpgradeAll(id)
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

MexPanel = Class(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)
        self:EnableHitTest()
        LayoutHelpers.DepthOverParent(self, parent, 100)
        LayoutHelpers.SetDimensions(self, 170, 60)
        self.contents = Group(self)
        LayoutHelpers.SetDimensions(self.contents, 168, 50)
        LayoutHelpers.AtCenterIn(self.contents, self)
        self:InitMexPanels(self.contents)
        local pos = self:_LoadPosition()
        LayoutHelpers.AtLeftTopIn(self, parent, pos.left, pos.top)
    end,

    InitMexPanels = function(self, parent)
        local previous
        parent.panels = {}
        for i, category in mexCategories do
            local panel = self:CreateMexCategoryPanel(parent, category)
            if previous then
                LayoutHelpers.RightOf(panel, previous, 2)
            else
                LayoutHelpers.AtLeftTopIn(panel, parent)
            end
            panel.id = i
            previous = panel
            table.insert(parent.panels, panel)
        end
    end,

    CreateMexCategoryPanel = function(self, parent, category)
        local group = Bitmap(parent)
        group:EnableHitTest()
        group:SetSolidColor("aa000000")
        LayoutHelpers.SetDimensions(group, 22, 50)
        group.category = category

        group.stratIcon = Bitmap(group)
        group.stratIcon:DisableHitTest()
        local iconName = "/textures/ui/common/game/strategicicons/" .. category.icon .. "_rest.dds"
        group.stratIcon:SetTexture(iconName)
        group.stratIcon:SetAlpha(0.3)
        LayoutHelpers.AtHorizontalCenterIn(group.stratIcon, group)
        LayoutHelpers.AtTopIn(group.stratIcon, group, 11)

        if category.isPaused then
            group.pauseIcon = Bitmap(group)
            group.pauseIcon:DisableHitTest()
            group.pauseIcon:SetTexture(pausedTexture)
            LayoutHelpers.SetDimensions(group.pauseIcon, 24, 24)
            group.pauseIcon:SetAlpha(0.3)
            LayoutHelpers.AtHorizontalCenterIn(group.pauseIcon, group)
            LayoutHelpers.AtTopIn(group.pauseIcon, group, 8)
        end

        if category.isUpgrading then
            group.upgrIcon = Bitmap(group)
            group.upgrIcon:DisableHitTest()
            group.upgrIcon:SetTexture(upgradeTexture)
            LayoutHelpers.SetDimensions(group.upgrIcon, 8, 8)
            group.upgrIcon:SetAlpha(0.3)
            LayoutHelpers.AtHorizontalCenterIn(group.upgrIcon, group, 5)
            LayoutHelpers.AtTopIn(group.upgrIcon, group, 20)
        end

        group.countLabel = UIUtil.CreateText(group, "0", 9, UIUtil.bodyFont)
        group.countLabel:SetNewColor("ffaaaaaa")
        group.countLabel:DisableHitTest()
        LayoutHelpers.AtHorizontalCenterIn(group.countLabel, group)
        LayoutHelpers.AtTopIn(group.countLabel, group, 1)

        if category.isUpgrading then
            group.ProgressBars = {}
            group.BackGroundBars = {}
            for i = 0, 9 do

                local progress = Bitmap(group)
                progress:DisableHitTest()
                progress:SetSolidColor("3300ff00")
                progress.Width:Set(group.Width)
                LayoutHelpers.SetHeight(progress, 2)
                LayoutHelpers.AtLeftBottomIn(progress, group, 0, i * 2)
                progress:Hide()

                local bg = Bitmap(group)
                bg:DisableHitTest()
                bg:SetSolidColor("1100ff00")
                bg.Width:Set(group.Width)
                LayoutHelpers.SetHeight(bg, 2)
                LayoutHelpers.AtLeftBottomIn(bg, group, 0, i * 2)
                bg:Hide()

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
            left = self.Left(),
            top = self.Top()
        })
    end

}
