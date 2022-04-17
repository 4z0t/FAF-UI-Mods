local CommonUnits = import('/mods/common/units.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local Text = import('/lua/maui/text.lua').Text
local UIUtil = import('/lua/ui/uiutil.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Prefs = import('/lua/user/prefs.lua')
local Dragger = import('/lua/maui/dragger.lua').Dragger

local mexCategories = {{
    name = "T1 idle",
    categories = categories.TECH1,
    isUpgrading = false,
    isPaused = nil,
    icon = "icon_structure1_mass"
}, {
    name = "T1 upgrading paused",
    categories = categories.TECH1,
    isUpgrading = true,
    isPaused = true,
    icon = "icon_structure1_mass"
}, {
    name = "T1 upgrading",
    categories = categories.TECH1,
    isUpgrading = true,
    isPaused = false,
    icon = "icon_structure1_mass"
}, {
    name = "T2 idle",
    categories = categories.TECH2,
    isUpgrading = false,
    isPaused = nil,
    icon = "icon_structure2_mass"
}, {
    name = "T2 upgrading paused",
    categories = categories.TECH2,
    isUpgrading = true,
    isPaused = true,
    icon = "icon_structure2_mass"
}, {
    name = "T2 upgrading",
    categories = categories.TECH2,
    isUpgrading = true,
    isPaused = false,
    icon = "icon_structure2_mass"
}, {
    name = "T3",
    categories = categories.TECH3,
    isUpgrading = false,
    isPaused = nil,
    icon = "icon_structure3_mass"
}}

local mexPanel
function init()
    if not IsDestroyed(mexPanel) then
        mexPanel:Destroy()
    end
    mexPanel = MexPanel(GetFrame(0))

end

local function MexPanelHandleEvent(control, event, category)

    if event.Type == 'MouseExit' then
        -- if hoverMexCategoryType ~= nil then
        --     hoverMexCategoryType.ui:InternalSetSolidColor('aa000000')
        -- end
        -- hoverMexCategoryType = nil

    elseif event.Type == 'MouseEnter' then
        -- hoverMexCategoryType = category
    elseif event.Type == 'ButtonPress' then
        if event.Modifiers.Right then
            if category.isPaused ~= nil then
                if event.Modifiers.Ctrl then
                    -- local sorted = GetUpgradingUnits(category)
                    -- local best = sorted[1]

                    -- if category.isPaused then
                    -- 	-- unpause the best
                    -- 	SetPaused({ best }, false)
                    -- else
                    -- 	-- pause all except the best
                    -- 	local worst = sorted[table.getn(sorted)]
                    -- 	SetPaused({ worst }, true)
                    -- end
                else
                    -- SetPaused(category.units, not category.isPaused)
                end
            else
                -- select only on screen
            end
        elseif event.Modifiers.Left then
            if event.Modifiers.Ctrl then

                -- local sorted = GetUpgradingUnits(category)
                -- local best = sorted[1]
                -- SelectUnits({ best })
            else

                -- SelectUnits(category.units)
                -- UIP.econtrol.ui.textLabel:SetText(category.name)

            end
        else
            --middle mouse button
            return false -- calls parent HandleEvent -> move the Panel
        end
    end

    -- if hoverMexCategoryType ~= nil then 
    -- 	hoverMexCategoryType.ui:InternalSetSolidColor('11ffffff')
    -- end

    return true
end

function Update()

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
            previous = panel
            table.insert(parent.panels, panel)
        end
    end,

    CreateMexCategoryPanel = function(self, parent, category)
        local group = Bitmap(parent)
        group:EnableHitTest()
        group:SetSolidColor('aa000000')
        LayoutHelpers.SetDimensions(group, 22, 50)
        group.category = category

        group.stratIcon = Bitmap(group)
        group.stratIcon:DisableHitTest()
        local iconName = '/textures/ui/common/game/strategicicons/' .. category.icon .. '_rest.dds'
        group.stratIcon:SetTexture(iconName)
        group.stratIcon:SetAlpha(0.3)
        LayoutHelpers.AtHorizontalCenterIn(group.stratIcon, group)
        LayoutHelpers.AtTopIn(group.stratIcon, group, 11)

        if category.isPaused then
            group.pauseIcon = Bitmap(group)
            group.pauseIcon:DisableHitTest()
            local iconName = '/textures/ui/common/game/strategicicons/pause_rest.dds'
            group.pauseIcon:SetTexture(iconName)
            LayoutHelpers.SetDimensions(group.pauseIcon, 24, 24)
            group.pauseIcon:SetAlpha(0.3)
            LayoutHelpers.AtHorizontalCenterIn(group.pauseIcon, group)
            LayoutHelpers.AtTopIn(group.pauseIcon, group, 8)
        end

        if category.isUpgrading then
            group.upgrIcon = Bitmap(group)
            group.upgrIcon:DisableHitTest()
            local iconName = '/mods/ui-party/textures/upgrade.dds'
            group.upgrIcon:SetTexture(iconName)
            LayoutHelpers.SetDimensions(group.upgrIcon, 8, 8)
            group.upgrIcon:SetAlpha(0.3)
            LayoutHelpers.AtHorizontalCenterIn(group.upgrIcon, group, 5)
            LayoutHelpers.AtTopIn(group.upgrIcon, group, 20)
        end

        group.countLabel = UIUtil.CreateText(group, "0", 9, UIUtil.bodyFont)
        group.countLabel:SetNewColor('ffaaaaaa')
        group.countLabel:DisableHitTest()
        LayoutHelpers.AtHorizontalCenterIn(group.countLabel, group)
        LayoutHelpers.AtTopIn(group.countLabel, group, 1)

        group.ProgressBars = {}
        group.BackGroundBars = {}
        for i = 0, 9 do

            local progress = Bitmap(group)
            progress:DisableHitTest()
            progress:SetSolidColor('1100ff00')
            progress.Width:Set(group.Width)
            LayoutHelpers.SetHeight(progress, 2)
            LayoutHelpers.AtLeftBottomIn(progress, group, 0, i * 2)

            local bg = Bitmap(group)
            bg:DisableHitTest()
            bg:SetSolidColor('3300ff00')
            LayoutHelpers.SetDimensions(bg, 2, 2)
            LayoutHelpers.AtLeftBottomIn(bg, group, 0, i * 2)

            table.insert(group.ProgressBars, progress)
            table.insert(group.BackGroundBars, bg)
        end

        group.HandleEvent = function(control, event)
            return MexPanelHandleEvent(control, event, control.category)
        end

        group.Update = function(self, units)

        end

        return group
    end,

    UpdateMexPanels = function(self, units)

    end,

    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            local offY = event.MouseY - self.Top()
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(x - offX)
                self.Top:Set(y - offY)
                GetCursor():SetTexture(UIUtil.GetCursor('MOVE_WINDOW'))
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
        return Prefs.GetFromCurrentProfile('EUTpos') or {
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
