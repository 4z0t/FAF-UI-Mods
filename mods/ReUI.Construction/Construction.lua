ReUI.Require
{
    "ReUI.Core >= 1.5.0",
    "ReUI.LINQ >= 1.4.0",
    "ReUI.UI >= 1.4.0",
    "ReUI.UI.Color >= 1.0.0",
    "ReUI.UI.Animation >= 1.1.0",
    "ReUI.UI.Controls >= 1.0.0",
    "ReUI.UI.Views >= 1.2.0",
    "ReUI.UI.Views.Grid >= 1.1.0",
    "ReUI.Options >= 1.0.0",
    "ReUI.Units >= 1.0.0",
    "ReUI.Units.Enhancements >= 1.2.0",
}


function Main(isReplay)
    local pcall = pcall

    ---@type EnhancementSlot[]
    local slotNames =
    {
        "RCH",
        "Back",
        "LCH",
    }

    local slotFiles =
    {
        LCH = '/game/construct-tech_btn/left_upgrade_btn_',
        RCH = '/game/construct-tech_btn/r_upgrade_btn_',
        Back = '/game/construct-tech_btn/m_upgrade_btn_',
    }

    local Bitmap   = ReUI.UI.Controls.Bitmap
    local Text     = ReUI.UI.Controls.Text
    local CheckBox = ReUI.UI.Controls.CheckBox
    local Group    = ReUI.UI.Controls.Group

    local Enumerate = ReUI.LINQ.Enumerate
    local Contains = ReUI.LINQ.IPairsEnumerator:Contains()

    local LF = ReUI.UI.LayoutFunctions

    local UIUtil = import("/lua/ui/uiutil.lua")
    local Tooltip = import("/lua/ui/game/tooltip.lua")

    local HorizontalGridScroller = import("Modules/GridScroller.lua").HorizontalGridScroller
    local LazyGrid               = import("Modules/Views/LazyGrid.lua").LazyGrid
    local ButtonWithOverlay      = import("Modules/Views/ButtonWithOverlay.lua").ButtonWithOverlay
    local ConstructionBorder     = import("Modules/Views/Border.lua").Border
    local Event                  = import("Modules/Event.lua").Event
    local Item                   = import("Modules/Views/Item.lua").Item



    ---@alias UpdateReason
    ---| "selection"
    ---| "queue"
    ---| "refresh"
    ---| "tab"
    ---| "tech"

    ---@alias TechLevel
    ---| "NONE"
    ---| "TECH1"
    ---| "TECH2"
    ---| "TECH3"
    ---| "EXPERIMENTAL"

    ---@class ConstructionHandlerData
    ---@field tab TabNames
    ---@field name string
    ---@field displayMode "grid"|"list"
    ---@field actions string[]
    ---@field handler ASelectionHandler

    ---@class ConstructionContext
    ---@field selection UserUnit[]?
    ---@field tech TechLevel
    ---@field slot EnhancementSlot
    ---@field reason UpdateReason
    ---@field panel ReUI.Construction.Panel
    ---@field tab TabNames|"all"

    ---@class ReUI.Construction.Grid : LazyGrid
    ---@field panel ReUI.Construction.Panel
    ---@field _scroller HorizontalGridScroller
    ---@field _componentClasses table<string, fun(item:ReUI.Construction.Grid.Item):AItemComponent>
    ---@field _selectionHandlers ConstructionHandlerData[]
    ---@field _btnNext ButtonWithOverlay
    ---@field _btnPrev ButtonWithOverlay
    ---@field _btnStart ButtonWithOverlay
    ---@field _btnEnd ButtonWithOverlay
    ---@field _canScroll boolean
    local ConstructionGrid = ReUI.Core.Class(LazyGrid)
    {
        ItemClass = Item,
        AutoLayout = false,

        ---@param self ReUI.Construction.Grid
        ---@param parent ReUI.Construction.Panel
        ---@param componentClasses table<string, fun(item:ReUI.Construction.Grid.Item):AItemComponent>
        __init = function(self, parent, componentClasses)
            LazyGrid.__init(self, parent)

            self.panel = parent
            self._componentClasses = componentClasses
            self._canScroll = false
            self._scroller = HorizontalGridScroller(self)

            self._btnNext = ButtonWithOverlay(self)
            self._btnPrev = ButtonWithOverlay(self)
            self._btnStart = ButtonWithOverlay(self)
            self._btnEnd = ButtonWithOverlay(self)

            self._btnNext.OnClick = function(btn)
                if self._scroller:Next() then
                    self:Refresh()
                end
            end
            self._btnPrev.OnClick = function(btn)
                if self._scroller:Prev() then
                    self:Refresh()
                end
            end
            self._btnStart.OnClick = function(btn)
                if self._scroller:ScrollStart() then
                    self:Refresh()
                end
            end
            self._btnEnd.OnClick = function(btn)
                if self._scroller:ScrollEnd() then
                    self:Refresh()
                end
            end
        end,

        ---@param self ReUI.Construction.Grid
        ---@param layouter ReUI.UI.Layouter
        InitLayout = function(self, layouter)
            LazyGrid.InitLayout(self, layouter)

            layouter(self._btnNext)
                :RightOf(self, 1)
                :FillVertically(self)

            layouter(self._btnPrev)
                :LeftOf(self, 1)
                :FillVertically(self)

            layouter(self._btnEnd)
                :RightOf(self._btnNext, 1)
                :FillVertically(self)

            layouter(self._btnStart)
                :LeftOf(self._btnPrev, 1)
                :FillVertically(self)

            local textures = {
                midBtn = {
                    up = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_up.dds'),
                    selected = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_selected.dds'),
                    down = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                    over = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                    dis = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds')
                },
                minBtn = {
                    up = UIUtil.UIFile('/game/construct-sm_btn/left_btn_up.dds'),
                    down = UIUtil.UIFile('/game/construct-sm_btn/left_btn_over.dds'),
                    over = UIUtil.UIFile('/game/construct-sm_btn/left_btn_over.dds'),
                    dis = UIUtil.UIFile('/game/construct-sm_btn/left_btn_dis.dds')
                },
                maxBtn = {
                    up = UIUtil.UIFile('/game/construct-sm_btn/right_btn_up.dds'),
                    down = UIUtil.UIFile('/game/construct-sm_btn/right_btn_over.dds'),
                    over = UIUtil.UIFile('/game/construct-sm_btn/right_btn_over.dds'),
                    dis = UIUtil.UIFile('/game/construct-sm_btn/right_btn_dis.dds')
                },
                minIcon = {
                    on = UIUtil.UIFile('/game/construct-sm_btn/back_on.dds'),
                    off = UIUtil.UIFile('/game/construct-sm_btn/back_off.dds')
                },
                maxIcon = {
                    on = UIUtil.UIFile('/game/construct-sm_btn/forward_on.dds'),
                    off = UIUtil.UIFile('/game/construct-sm_btn/forward_off.dds')
                },
                pageMinIcon = {
                    on = UIUtil.UIFile('/game/construct-sm_btn/rewind_on.dds'),
                    off = UIUtil.UIFile('/game/construct-sm_btn/rewind_off.dds')
                },
                pageMaxIcon = {
                    on = UIUtil.UIFile('/game/construct-sm_btn/fforward_on.dds'),
                    off = UIUtil.UIFile('/game/construct-sm_btn/fforward_off.dds')
                }
            }

            self._btnNext:SetOverlayTextures(textures.maxIcon.off, textures.maxIcon.on)
            self._btnPrev:SetOverlayTextures(textures.minIcon.off, textures.minIcon.on)
            self._btnStart:SetOverlayTextures(textures.pageMinIcon.off, textures.pageMinIcon.on)
            self._btnEnd:SetOverlayTextures(textures.pageMaxIcon.off, textures.pageMaxIcon.on)

            self._btnNext:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over,
                textures.midBtn.dis)
            self._btnPrev:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over,
                textures.midBtn.dis)
            self._btnStart:SetNewTextures(textures.minBtn.up, textures.minBtn.down, textures.minBtn.over,
                textures.minBtn.dis)
            self._btnEnd:SetNewTextures(textures.maxBtn.up, textures.maxBtn.down, textures.maxBtn.over,
                textures.maxBtn.dis)

            self._btnNext:ApplyTextures()
            self._btnPrev:ApplyTextures()
            self._btnStart:ApplyTextures()
            self._btnEnd:ApplyTextures()

            layouter(self)
                :Color("99000000")
        end,

        ---@param self ReUI.Construction.Grid
        ---@param item ReUI.Construction.Grid.Item
        ---@param row number
        ---@param column number
        PositionItem = function(self, item, row, column)
            LazyGrid.PositionItem(self, item, row, column)
            local layouter = self.Layouter
            layouter(item)
                :Width(layouter:ScaleVar(self._columnWidth))
                :Height(layouter:ScaleVar(self._rowHeight))

        end,

        ---@param self ReUI.Construction.Grid
        Disable = function(self)
            self._btnEnd:Disable()
            self._btnNext:Disable()
            self._btnPrev:Disable()
            self._btnStart:Disable()
            self._scroller.ItemCount = 0
            self:DisableItems()
        end,

        ---@param self ReUI.Construction.Grid
        ---@param handlerData ConstructionHandlerData
        ---@param actions any[]
        ---@param context any
        Update = function(self, handlerData, actions, context)
            local scroller = self._scroller

            if table.empty(actions) then
                self:Disable()
                return
            end

            self:Show()

            scroller.ItemCount = table.getn(actions)

            local name = handlerData.name
            local index = scroller.StartIndex

            ---@param item ReUI.Construction.Grid.Item
            self:IterateItemsHorizontally(function(grid, item, row, column)
                local action = actions[index]
                if action then
                    item:EnableComponent(name, action, context)
                else
                    item:Disable()
                end
                index = index + 1
            end)

            if scroller:IsEnd() then
                self._btnEnd:Disable()
                self._btnNext:Disable()
            else
                self._btnEnd:Enable()
                self._btnNext:Enable()
            end
            if scroller:IsStart() then
                self._btnPrev:Disable()
                self._btnStart:Disable()
            else
                self._btnPrev:Enable()
                self._btnStart:Enable()
            end
        end,

        ---@param self ReUI.Construction.Grid
        Refresh = function(self)
            self.panel:Refresh()
        end,

        ---@param self ReUI.Construction.Grid
        ---@return table<string, fun(instance: BaseGridItem):AItemComponent>
        GetItemComponentClasses = function(self)
            return self._componentClasses
        end,

        ---@param self ReUI.Construction.Grid
        ---@param event KeyEvent
        HandleEvent = function(self, event)
            if self._canScroll and event.Type == 'WheelRotation' then
                if self._scroller:Scroll(event.WheelRotation < 0 and -1 or 1) then
                    self:Refresh()
                end
                return true
            end
            return false
        end,

        ---@param self ReUI.Construction.Grid
        OnDestroy = function(self)
            self._scroller:Destroy()
            self._scroller = nil
            self._btnNext = nil
            self._btnPrev = nil
            self._btnStart = nil
            self._btnEnd = nil
            self._componentClasses = nil
            self.panel = nil
            LazyGrid.OnDestroy(self)
        end,
    }


    ---@class Tab : ReUI.UI.Controls.CheckBox
    ---@field _hitArea ReUI.UI.Controls.Group
    local Tab = ReUI.Core.Class(CheckBox)
    {
        ---@param self Tab
        ---@param parent ReUI.Construction.Panel
        __init = function(self, parent)
            CheckBox.__init(self, parent)
            self._hitArea = Group(self)
        end,

        ---@param self Tab
        ---@param layouter ReUI.UI.Layouter
        InitLayout = function(self, layouter)
            layouter(self._hitArea)
                :Over(self)
                :OffsetIn(self, 8, 7, 8, 9)
                :EnableHitTest()

            layouter(self)
                :DisableHitTest()
        end,

        ---@param self Tab
        Disable = function(self)
            self._isDisabled = true
            self:OnDisable()
        end,

        ---@param self Tab
        Enable = function(self)
            self._isDisabled = false
            self:OnEnable()
        end,

        ---@param self Tab
        HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                PlaySound(Sound({ Bank = 'Interface', Cue = 'UI_Tab_Rollover_02' }))
            elseif event.Type == 'ButtonPress' then
                PlaySound(Sound({ Bank = 'Interface', Cue = 'UI_Tab_Click_02' }))
            end
            return CheckBox.HandleEvent(self, event)
        end
    }

    ---@alias TabNames
    ---| "selection"
    ---| "construction"
    ---| "enhancements"


    ---@type fun(selection: UserUnit[]): UnitBlueprint?
    local GetSingleBPFromSelection = ReUI.LINQ.IPairsEnumerator
        ---@param unit UserUnit
        :Select(function(unit)
            return unit:GetBlueprint()
        end)
        :Distinct()
        :Single()

    ---@param selection UserUnit[]?
    ---@return boolean
    local function HasEnhancementsForSelection(selection)
        if table.empty(selection) then
            return false
        end
        ---@cast selection -nil

        local bp = GetSingleBPFromSelection(selection)
        if not bp then
            return false
        end

        local enhancements = ReUI.Units.Enhancements.ResolveUpgradeChains(bp)
        if not enhancements then
            return false
        end
        return true
    end

    ---@class ConstructionTabs
    ---@field _currentTab TabNames
    ---@field _constructionPanel ReUI.Construction.Panel
    ---@field _constructionTab Tab
    ---@field _selectionTab Tab
    ---@field _enhancementsTab Tab
    ---@field _tabs table<TabNames, Tab>
    local ConstructionTabs = ReUI.Core.Class()
    {
        ---@param self ConstructionTabs
        ---@param parent ReUI.Construction.Panel
        __init = function(self, parent)
            self._constructionPanel = parent
            self._currentTab = "selection"

            ---@param checkBox Tab
            ---@param tab TabNames
            local function OnTabCheck(checkBox, tab)
                if not self:SetCurrentTab(tab) then
                    return
                end
                self._constructionPanel:OnTabChanged(tab)
            end

            self._constructionTab = Tab(self._constructionPanel)
            Tooltip.AddControlTooltip(self._constructionTab, 'construction_tab_construction')
            ---@param tab Tab
            ---@param checked boolean
            self._constructionTab.OnCheck = function(tab, checked)
                OnTabCheck(tab, "construction")
            end

            self._selectionTab = Tab(self._constructionPanel)
            Tooltip.AddControlTooltip(self._selectionTab, 'construction_tab_attached')
            ---@param tab Tab
            ---@param checked boolean
            self._selectionTab.OnCheck = function(tab, checked)
                OnTabCheck(tab, "selection")
            end

            self._enhancementsTab = Tab(self._constructionPanel)
            Tooltip.AddControlTooltip(self._enhancementsTab, 'construction_tab_enhancement')
            ---@param tab Tab
            ---@param checked boolean
            self._enhancementsTab.OnCheck = function(tab, checked)
                OnTabCheck(tab, "enhancements")
            end

            self._tabs = {
                construction = self._constructionTab,
                selection = self._selectionTab,
                enhancements = self._enhancementsTab,
            }
        end,

        ---@param self ConstructionTabs
        ---@param layouter ReUI.UI.Layouter
        InitLayout = function(self, layouter)
            local constructionPanel = self._constructionPanel

            local tabFiles = {
                construction = '/game/construct-tab_btn/top_tab_btn_',
                selection = '/game/construct-tab_btn/mid_tab_btn_',
                enhancement = '/game/construct-tab_btn/bot_tab_btn_',
            }

            ---@param name FileName
            ---@return FileName
            ---@return FileName
            ---@return FileName
            ---@return FileName
            ---@return FileName
            ---@return FileName
            local function GetTabTextures(name)
                return UIUtil.UIFile(name .. 'up_bmp.dds'),
                    UIUtil.UIFile(name .. 'sel_bmp.dds'),
                    UIUtil.UIFile(name .. 'over_bmp.dds'),
                    UIUtil.UIFile(name .. 'down_bmp.dds'),
                    UIUtil.UIFile(name .. 'dis_bmp.dds'),
                    UIUtil.UIFile(name .. 'dis_bmp.dds')
            end

            layouter(self._enhancementsTab)
                :AtLeftIn(constructionPanel, -10)
                :AtBottomIn(constructionPanel, -11)

            self._enhancementsTab:SetNewTextures(GetTabTextures(tabFiles.enhancement))

            layouter(self._selectionTab)
                :Above(self._enhancementsTab, -16)

            self._selectionTab:SetNewTextures(GetTabTextures(tabFiles.selection))

            layouter(self._constructionTab)
                :Above(self._selectionTab, -16)

            self._constructionTab:SetNewTextures(GetTabTextures(tabFiles.construction))
        end,

        ---@param self ConstructionTabs
        ---@param tabName TabNames
        ---@return boolean
        SetCurrentTab = function(self, tabName)
            if self._currentTab == tabName then
                return false
            end

            self._currentTab = tabName
            ---@param tab Tab
            for name, tab in self._tabs do
                tab:SetCheck(tabName == name, true)
            end
            return true
        end,

        ---@param self ConstructionTabs
        ---@param tabName TabNames
        ---@param enabled boolean
        SetTabEnabled = function(self, tabName, enabled)
            local tab = self._tabs[tabName]
            if tab then
                if enabled then
                    tab:Enable()
                else
                    tab:Disable()
                end
            end
        end
    }

    local ActionCheckBox = import("Modules/Views/ActionCheckBox.lua").ActionCheckBox

    local ActionCheckBoxBehavior = import("Modules/Views/ActionCheckBox.lua").ActionCheckBoxBehavior

    ---@class PauseBehavior : ReUI.Construction.ActionCheckBoxBehavior
    local PauseBehavior = ReUI.Core.Class(ActionCheckBoxBehavior)
    {
        ---@param self PauseBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        OnAttach = function(self, checkBox)
            checkBox:SetNewTextures(
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_up.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_selected.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds')
            )

            checkBox:SetOverlayTextures(
                UIUtil.UIFile('/game/construct-sm_btn/pause_off.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/pause_on.dds')
            )
        end,

        ---@param self PauseBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        ---@param paused boolean
        OnChecked = function(self, checkBox, paused)
            local selection = checkBox.Context.selection
            if table.empty(selection) then
                return
            end
            ---@cast selection -nil

            SetPaused(selection, paused)
            local checkedS = paused and "true" or "false"
            -- If we have exFacs platforms or exFac units selected, we'll pause their counterparts as well
            for _, exFac in EntityCategoryFilterDown(categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT,
                selection) do
                exFac:GetCreator():ProcessInfo('SetPaused', checkedS)
            end
        end,

        ---@param self PauseBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        OnUpdate = function(self, checkBox)
            local selection = checkBox.Context.selection
            if table.empty(selection) then
                checkBox:Disable()
                return
            end
            ---@cast selection -nil

            local orders = GetUnitCommandData(selection)
            local isPauseAvailable = Contains(orders, "RULEUCC_Pause")

            if isPauseAvailable then
                checkBox:SetCheck(GetIsPaused(selection), true)
                checkBox:Enable()
            else
                checkBox:Disable()
            end
        end,
    }

    ---@class RepeatBehavior : ReUI.Construction.ActionCheckBoxBehavior
    local RepeatBehavior = ReUI.Core.Class(ActionCheckBoxBehavior)
    {
        ---@param self RepeatBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        OnAttach = function(self, checkBox)
            checkBox:SetNewTextures(
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_up.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_selected.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds')
            )

            checkBox:SetOverlayTextures(
                UIUtil.UIFile('/game/construct-sm_btn/infinite_off.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/infinite_on.dds')
            )
        end,

        ---@param self RepeatBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        ---@param isChecked boolean
        OnChecked = function(self, checkBox, isChecked)
            local selection = checkBox.Context.selection
            if table.empty(selection) then
                return
            end
            ---@cast selection -nil

            local isRepeatBuild = isChecked and 'true' or 'false'
            ---@param unit UserUnit
            for _, unit in selection do
                unit:ProcessInfo('SetRepeatQueue', isRepeatBuild)
                if EntityCategoryContains(categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT, unit) then
                    unit:GetCreator():ProcessInfo('SetRepeatQueue', isRepeatBuild)
                end
            end
        end,

        ---@param self RepeatBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        OnUpdate = function(self, checkBox)
            local selection = checkBox.Context.selection
            if table.empty(selection) then
                checkBox:Disable()
                return
            end

            ---@cast selection -nil

            local allFactories = Enumerate(selection)
                ---@param unit UserUnit
                :All(function(unit)
                    return EntityCategoryContains(categories.FACTORY + categories.EXTERNALFACTORY, unit)
                end)

            if allFactories then
                local allRepeatQueue = Enumerate(selection)
                    ---@param unit UserUnit
                    :All(function(unit)
                        return unit:IsRepeatQueue()
                    end)

                checkBox:SetCheck(allRepeatQueue, true)
                checkBox:Enable()
            else
                checkBox:Disable()
            end
        end,
    }

    ---@class TabsRowProto
    ---@field name string
    ---@field file FileName

    ---@class TechTab : ReUI.UI.Controls.CheckBox
    ---@field name string
    ---@field file FileName
    local TechTab = ReUI.Core.Class(CheckBox)
    {
        AutoLayout = false,

        ---@param self TechTab
        ---@param parent Control
        ---@param name string
        ---@param file FileName
        __init = function(self, parent, name, file)
            CheckBox.__init(self, parent)

            self.mClickCue = 'UI_Tab_Click_02'
            self.mRolloverCue = 'UI_Tab_Rollover_02'

            self.name = name
            self.file = file
        end,

        ---@param self TechTab
        ---@param layouter ReUI.UI.Layouter
        InitLayout = function(self, layouter)
            local file = self.file
            self:SetNewTextures(
                UIUtil.UIFile(file .. 'up.dds'),
                UIUtil.UIFile(file .. 'selected.dds'),
                UIUtil.UIFile(file .. 'over.dds'),
                UIUtil.UIFile(file .. 'down.dds'),
                UIUtil.UIFile(file .. 'dis.dds'),
                UIUtil.UIFile(file .. 'dis.dds')
            )
        end,
    }


    ---@class TechTabs : ReUI.UI.Controls.Group
    ---@field _constructionPanel ReUI.Construction.Panel
    ---@field _tabs ReUI.UI.Controls.CheckBox[]
    local TechTabs = ReUI.Core.Class(Group)
    {
        AutoLayout = false,

        ---@param self TechTabs
        ---@param parent ReUI.Construction.Panel
        ---@param tabs TabsRowProto[]
        __init = function(self, parent, tabs)
            Group.__init(self, parent)

            self._constructionPanel = parent

            ---@param tab TechTab
            ---@param checked boolean
            local function OnTabCheck(tab, checked)
                self:OnTabCheck(tab.name)
            end

            self._tabs = {}
            for _, proto in ipairs(tabs) do
                local tab = TechTab(self, proto.name, proto.file)
                tab.OnCheck = OnTabCheck
                table.insert(self._tabs, tab)
            end
        end,

        ---@param self TechTabs
        ---@param tech TechLevel
        SetActiveTechTab = function(self, tech)
            ---@param tab TechTab
            for i, tab in self._tabs do
                tab:SetCheck(tab.name == tech, true)
            end
        end,

        ---@param self TechTabs
        ---@param techs table<TechLevel, boolean>
        SetAvailableTech = function(self, techs)
            for tech, enabled in techs do
                self:SetEnabledTab(tech, enabled)
            end
        end,

        ---@param self TechTabs
        ---@param name string
        ---@param enabled boolean
        SetEnabledTab = function(self, name, enabled)
            for i, tab in self._tabs do
                if tab.name == name then
                    if enabled then
                        tab:Enable()
                    else
                        tab:Disable()
                    end
                    break
                end
            end
        end,

        ---@param self TechTabs
        ---@param layouter ReUI.UI.Layouter
        InitLayout = function(self, layouter)

            local prev
            ---@param tab TechTab
            for i, tab in self._tabs do
                if prev then
                    layouter(tab)
                        :RightOf(prev)
                else
                    layouter(tab)
                        :AtRightBottomIn(self)
                end

                layouter(tab)
                    :PerformLayout()

                prev = tab
            end

            layouter(self)
                :Width(0)
                :Height(0)
                :DisableHitTest()
        end,

        ---@param self TechTabs
        ---@param name string
        OnTabCheck = function(self, name)
            ---@param tab TechTab
            for _, tab in self._tabs do
                if tab.name ~= name then
                    tab:SetCheck(false, true)
                end
            end

            self._constructionPanel:OnTechChanged(name)
        end,

        ---@param self TechTabs
        OnDestroy = function(self)
            self._tabs = nil
            self._constructionPanel = nil
            Group.OnDestroy(self)
        end
    }

    ---@class ReUI.Construction.Panel : ReUI.UI.Controls.Group
    ---@field _context ConstructionContext
    ---@field _componentClasses table<string, fun(instance: BaseGridItem):AItemComponent>
    ---@field _selectionHandlers table<string, ASelectionHandler>
    ---@field _actionsBehavior table<string, ReUI.Construction.ActionCheckBoxBehavior>
    ---@field _slots table<string, ReUI.UI.Controls.CheckBox>
    ---@field _constructionTabs ConstructionTabs
    ---@field _techTabs TechTabs
    ---@field _canScroll boolean
    ---@field _primary ReUI.Construction.Grid
    ---@field _enhancements ReUI.Construction.Grid
    ---@field _secondary ReUI.Construction.Grid
    ---@field _border ConstructionBorder
    ---@field _actionCheckBoxes ReUI.Construction.ActionCheckBox[]
    ---@field UpdateEvent Event
    local ConstructionPanel = ReUI.Core.Class(Group)
    {

        ---@type table<string, ReUI.Construction.ActionCheckBoxBehavior>
        Actions = {
            ["pause"]       = PauseBehavior,
            ["repeatBuild"] = RepeatBehavior,
        },

        ---@type TabsRowProto[]
        TechTabs = {
            { name = "TECH1", file = '/game/construct-tech_btn/t1_btn_', },
            { name = "TECH2", file = '/game/construct-tech_btn/t2_btn_', },
            { name = "TECH3", file = '/game/construct-tech_btn/t3_btn_', },
            { name = "EXPERIMENTAL", file = '/game/construct-tech_btn/t4_btn_', },
        },

        ---@type ConstructionHandlerData[]
        PrimaryHandlers = {
            {
                name = "BuildOptions",
                tab = "construction",
                displayMode = "grid",
                actions = { "repeatBuild", "pause" },
                handler = import("Modules/Components/BuildOptions.lua").BuildOptionsHandler,
            },
            {
                name = "BuildOptionsFactory",
                tab = "construction",
                displayMode = "grid",
                actions = { "repeatBuild", "pause" },
                handler = import("Modules/Components/BuildOptions.lua").BuildOptionsFactoryHandler
            },
            {
                name = "UpgradeChain",
                tab = "selection",
                displayMode = "list",
                actions = { "repeatBuild", "pause" },
                handler = import("Modules/Components/UpgradeChain.lua").UpgradeChainHandler,
            },
            {
                name = "Selection",
                tab = "selection",
                displayMode = "grid",
                actions = { "repeatBuild", "pause" },
                handler = import("Modules/Components/SelectedUnits.lua").SelectedUnitsListHandler
            },
            {
                name = "Enhancements",
                tab = "enhancements",
                displayMode = "list",
                actions = { "repeatBuild", "pause" },
                handler = import("Modules/Components/Enhancements.lua").EnhancementsHandler,
            },
        },

        ---@type ConstructionHandlerData[]
        SecondaryHandlers = {
            {
                name = "FactoryQueue",
                tab = "construction",
                handler = import("Modules/Components/QueueList.lua").QueueListHandler
            },
            {
                name = "BuildQueue",
                tab = "construction",
                handler = import("Modules/Components/BuildQueue.lua").BuildQueueHandler
            },
            {
                name = "TransportCargo",
                tab = "selection",
                handler = import("Modules/Components/TransportCargo.lua").TransportCargoHandler
            },
            {
                name = "CarrierCargo",
                tab = "selection",
                handler = import("Modules/Components/CarrierCargo.lua").CarrierCargoHandler
            },
            {
                name = "Selection",
                tab = "selection",
                handler = import("Modules/Components/SelectedUnits.lua").SelectedUnitsListHandler
            },
        },

        ---@param self ReUI.Construction.Panel
        ---@param parent Control
        __init = function(self, parent)
            Group.__init(self, parent)
            local options = ReUI.Options.Mods["ReUI.Construction"]

            self.Layouter = ReUI.UI.RoundLayouter(LF.Div(options.scale:Raw(), 100))
            self.AutoLayout = false

            self.UpdateEvent = Event()

            self._canScroll = false
            self._context = {
                tech = "NONE",
                slot = "Back",
                reason = "refresh",
                tab = "selection",
                selection = nil,
                panel = self,
                displayMode = "grid",
            }

            self._actionsBehavior = {}
            for name, behavior in self.Actions do
                self._actionsBehavior[name] = behavior()
            end

            self._selectionHandlers = {}
            self._componentClasses = {}
            for _, handlerData in self.PrimaryHandlers do
                local class = handlerData.handler.ComponentClass
                local name = handlerData.name
                if self._componentClasses[name] and
                    self._componentClasses[name] ~= class then
                    error("Duplicate handler name: " .. handlerData.name)
                end

                self._componentClasses[name] = class
                self._selectionHandlers[name] = handlerData.handler(self)
            end

            for _, handlerData in self.SecondaryHandlers do
                local class = handlerData.handler.ComponentClass
                local name = handlerData.name
                if self._componentClasses[name] and
                    self._componentClasses[name] ~= class then
                    error("Duplicate handler name: " .. handlerData.name)
                end

                self._componentClasses[name] = class
                self._selectionHandlers[name] = handlerData.handler(self)
            end

            self._constructionTabs = ConstructionTabs(self)
            self._primary = ReUI.Construction.Grid(self, self._componentClasses)
            self._secondary = ReUI.Construction.Grid(self, self._componentClasses)
            self._enhancements = ReUI.Construction.Grid(self, self._componentClasses)
            self._border = ConstructionBorder(self)
            self._techTabs = TechTabs(self, self.TechTabs)

            self._actionCheckBoxes = {
                ActionCheckBox(self, self._context),
                ActionCheckBox(self, self._context),
            }

            self._slots = {}

            local function OnCheckSlot(_slot, checked)
                ---@param slot ReUI.UI.Controls.CheckBox
                for _, slot in self._slots do
                    if slot ~= _slot then
                        slot:SetCheck(false, true)
                    end
                end

                self._context.slot = _slot.slot
                self:Refresh()
            end

            for i, s in slotNames do
                self._slots[i] = CheckBox(self)
                self._slots[i].slot = s
                self._slots[i].OnCheck = OnCheckSlot
                self._slots[i].mClickCue = 'UI_Tab_Click_02'
                self._slots[i].mRolloverCue = 'UI_Tab_Rollover_02'
            end

            local itemSize = 48

            self._primary.Rows = options.rows:Raw()
            self._primary.VerticalSpacing = 2
            self._primary.HorizontalSpacing = 2
            self._primary.RowHeight = itemSize
            self._primary.ColumnWidth = itemSize

            self._secondary.Rows = 1
            self._secondary.VerticalSpacing = 2
            self._secondary.HorizontalSpacing = 2
            self._secondary.RowHeight = itemSize
            self._secondary.ColumnWidth = itemSize

            self._enhancements.Rows = 1
            self._enhancements.VerticalSpacing = 2
            self._enhancements.HorizontalSpacing = 20
            self._enhancements.RowHeight = itemSize
            self._enhancements.ColumnWidth = itemSize

        end,

        ---@param self ReUI.Construction.Panel
        ---@param layouter ReUI.UI.Layouter
        InitLayout = function(self, layouter)
            self._primary.AutoWidth = false
            self._secondary.AutoWidth = false
            self._enhancements.AutoWidth = false

            layouter(self._secondary)
                :AtBottomIn(self, 5)
                :AtLeftIn(self, 140)
                :AtRightIn(self, 50)
                :PerformLayout()
                :ResetWidth()

            layouter(self._primary)
                :Above(self._secondary, 4)
                :AtLeftIn(self, 140)
                :AtRightIn(self, 50)
                :PerformLayout()
                :ResetWidth()

            layouter(self._enhancements)
                :Above(self._secondary, 4)
                :AtLeftIn(self, 140)
                :AtRightIn(self, 50)
                :PerformLayout()
                :ResetWidth()
                :Hide()


            layouter(self._actionCheckBoxes[1])
                :FillVertically(self._enhancements)
                :AtLeftIn(self, 65)

            layouter(self._actionCheckBoxes[2])
                :FillVertically(self._secondary)
                :AtLeftIn(self, 65)

            layouter(self._border)
                :Top(self.Top)
                :Bottom(self.Bottom)
                :AtLeftIn(self, 58)
                :Right(self.Right)
                :Under(self, 5)
                :DisableHitTest(true)

            layouter(self)
                :AtTopIn(self._primary, -5)
                :EnableHitTest()


            layouter(self._techTabs)
                :Above(self._primary, 3)
                :PerformLayout()

            for i, checkbox in self._actionCheckBoxes do
                checkbox.Behavior = nil
            end

            local prev
            ---@param slot ReUI.UI.Controls.CheckBox
            for i, slot in self._slots do
                if prev then
                    layouter(slot)
                        :RightOf(prev)
                else
                    layouter(slot)
                        :Above(self._enhancements)
                end

                local pre = slotFiles[slot.slot] --[[@as FileName]]
                slot:SetNewTextures(
                    UIUtil.UIFile(pre .. 'up.dds'),
                    UIUtil.UIFile(pre .. 'selected.dds'),
                    UIUtil.UIFile(pre .. 'over.dds'),
                    UIUtil.UIFile(pre .. 'down.dds'),
                    UIUtil.UIFile(pre .. 'dis.dds'),
                    UIUtil.UIFile(pre .. 'dis.dds')
                )

                prev = slot
            end

            self._constructionTabs:InitLayout(layouter)
        end,

        ---@param self ReUI.Construction.Panel
        ---@param event KeyEvent
        HandleEvent = function(self, event)
            if event.Type == "WheelRotation" then
                return self._canScroll
            end
            return false
        end,

        ---@param self ReUI.Construction.Panel
        ---@param techs table<TechLevel, boolean>
        SetAvailableTech = function(self, techs)
            self._techTabs:SetAvailableTech(techs)
        end,

        ---@param self ReUI.Construction.Panel
        ---@param tech TechLevel
        SetActiveTech = function(self, tech)
            self._techTabs:SetActiveTechTab(tech)
        end,

        ---@param self ReUI.Construction.Panel
        ---@param func fun(self: ReUI.Construction.Panel, slot:ReUI.UI.Controls.CheckBox)
        ApplyToSlots = function(self, func)
            for _, slot in self._slots do
                func(self, slot)
            end
        end,

        ---@param self ReUI.Construction.Panel
        ---@param cb ReUI.UI.Controls.CheckBox
        HideCheckBox = function(self, cb)
            cb:Hide()
        end,

        ---@param self ReUI.Construction.Panel
        ---@param cb ReUI.UI.Controls.CheckBox
        ShowCheckBox = function(self, cb)
            cb:Show()
        end,

        ---@param self ReUI.Construction.Panel
        ---@param name string
        ---@return ASelectionHandler?
        GetHandler = function(self, name)
            return self._selectionHandlers[name]
        end,

        ---@param self ReUI.Construction.Panel
        ---@param handlers ConstructionHandlerData[]
        ---@param anyTab? boolean
        ---@return ConstructionHandlerData?
        ---@return any[]?
        ---@return any?
        GetActionsFor = function(self, handlers, anyTab)
            local selfContext = self._context
            local activeTab = selfContext.tab
            local acceptAllTabs = activeTab == "all" or activeTab == "construction" or anyTab

            ---@param handlerData ConstructionHandlerData
            for _, handlerData in handlers do
                local tab = handlerData.tab
                if tab ~= activeTab and not acceptAllTabs then
                    continue
                end
                local name = handlerData.name
                local handler = self:GetHandler(name) --[[@as ASelectionHandler]]

                local actions, context = handler:Update(selfContext)
                if actions then
                    return handlerData, actions, context or selfContext
                end
            end
            return nil, nil, nil
        end,

        ---@param self ReUI.Construction.Panel
        ---@param reason UpdateReason
        InternalUpdate = function(self, reason)
            self._context.reason = reason

            local primaryHandlerData, primaryActions, primaryContext = self:GetActionsFor(self.PrimaryHandlers)
            local secondaryHandlerData, secondaryActions, secondaryContext = self:GetActionsFor(self.SecondaryHandlers,
                self._context.tab == "enhancements")

            if not primaryHandlerData and not secondaryHandlerData then
                self._constructionTabs:SetCurrentTab("none")
                self:Hide()
                return
            end
            --- This is never nil afterwards
            ---@cast primaryHandlerData -nil
            ---@cast primaryActions -nil

            local mode = primaryHandlerData.displayMode
            if mode == "grid" then
                self._primary:Update(primaryHandlerData, primaryActions, primaryContext)
                self._enhancements:Disable()
                self._enhancements:Hide()
                self:Layouter()
                    :AtTopIn(self._primary, -5)
            elseif mode == "list" then
                self._enhancements:Update(primaryHandlerData, primaryActions, primaryContext)
                self._primary:Disable()
                self._primary:Hide()
                self:Layouter()
                    :AtTopIn(self._enhancements, -5)
            end

            if secondaryHandlerData and secondaryHandlerData.name ~= primaryHandlerData.name then
                ---@cast secondaryActions -nil
                self._secondary:Update(secondaryHandlerData, secondaryActions, secondaryContext)
            else
                self._secondary:Disable()
            end

            local tab = primaryHandlerData.tab
            self._constructionTabs:SetCurrentTab(tab)

            if reason == "selection" then
                if tab == "construction" then
                    self._techTabs:Show()
                    self:ApplyToSlots(self.HideCheckBox)
                    self._constructionTabs:SetTabEnabled("construction", true)
                    self._constructionTabs:SetTabEnabled("selection", true)
                elseif tab == "selection" then
                    self._techTabs:Hide()
                    self:ApplyToSlots(self.HideCheckBox)
                    self._constructionTabs:SetTabEnabled("construction", false)
                    self._constructionTabs:SetTabEnabled("selection", true)
                elseif tab == "enhancements" then
                    self._techTabs:Hide()
                    self:ApplyToSlots(self.ShowCheckBox)
                end

                self._constructionTabs:SetTabEnabled("enhancements",
                    HasEnhancementsForSelection(self._context.selection))
            end

            local actions = primaryHandlerData.actions
            for i, checkbox in self._actionCheckBoxes do
                checkbox.Behavior = self._actionsBehavior[ actions[i] ]
                checkbox:Update()
            end

            self.UpdateEvent:Invoke(self, self._context)
        end,

        ---@param self ReUI.Construction.Panel
        ---@param reason UpdateReason
        Update = function(self, reason)
            local ok, err = pcall(self.InternalUpdate, self, reason)
            if not ok then
                WARN("[ReUI.Construction] Update failed: " .. err)
            end
        end,

        ---@param self ReUI.Construction.Panel
        Refresh = function(self)
            self:Update("refresh")
        end,

        ---@param self ReUI.Construction.Panel
        ---@param tab TabNames
        OnTabChanged = function(self, tab)
            self._context.tab = tab

            if tab == "construction" then
                self._techTabs:Show()
                self:ApplyToSlots(self.HideCheckBox)
            elseif tab == "selection" then
                self._techTabs:Hide()
                self:ApplyToSlots(self.HideCheckBox)
            elseif tab == "enhancements" then
                self._techTabs:Hide()
                for _, slot in self._slots do
                    slot:Show()
                    slot:SetCheck(slot.slot == self._context.slot, true)
                end
            end

            self:Update("tab")
        end,

        ---@param self ReUI.Construction.Panel
        ---@param selection UserUnit[]?
        OnSelectionChanged = function(self, selection)
            self:Show()

            if table.equal(self._context.selection, selection) then

            else
                self._context.tab = "all"
                self._context.selection = selection
                self._context.tech = "NONE"
                self._context.slot = "Back"
            end

            self:Update("selection")
        end,

        ---@param self ReUI.Construction.Panel
        ---@param tech TechLevel
        OnTechChanged = function(self, tech)
            self._context.tech = tech
            self:Update("tech")
        end,

        ---@param self ReUI.Construction.Panel
        ---@param canScroll boolean
        SetCanScroll = function(self, canScroll)
            self._canScroll = canScroll
            self._primary._canScroll = canScroll
            self._secondary._canScroll = canScroll
            self._enhancements._canScroll = canScroll
        end,

        ---@param self ReUI.Construction.Panel
        DestroyHandlers = function(self)
            if not self._selectionHandlers then
                return
            end

            for name, handler in self._selectionHandlers do
                handler:Destroy()
            end

            self._selectionHandlers = nil
        end,

        ---@param self ReUI.Construction.Panel
        OnDestroy = function(self)
            self._actionsBehavior = nil
            self._techTabs = nil
            self._border = nil
            self._actionCheckBoxes = nil
            self._primary = nil
            self._secondary = nil
            self._enhancements = nil
            self:DestroyHandlers()
            Group.OnDestroy(self)
        end
    }

    local ConstructionHook = ReUI.Core.HookModule "/lua/ui/game/construction.lua"

    ConstructionHook("OnQueueChanged", function(field, module)
        return function(newQueue)
            ---@type ReUI.Construction.Panel
            local panel = ReUI.UI.Global["Construction"]
            if not IsDestroyed(panel) then
                panel:Update("queue")
            end
        end
    end)

    ConstructionHook("RefreshUI", function(field, module)
        return function()
            ---@type ReUI.Construction.Panel
            local panel = ReUI.UI.Global["Construction"]
            if not IsDestroyed(panel) then
                panel:Update("refresh")
            end
        end
    end)

    ConstructionHook("Expand", function(field, module)
        return function()
            ---@type ReUI.Construction.Panel
            local panel = ReUI.UI.Global["Construction"]
            if not IsDestroyed(panel) then
                panel:Show()
                panel:Refresh()
            end
        end
    end)

    ConstructionHook("Contract", function(field, module)
        return function()
            ---@type ReUI.Construction.Panel
            local panel = ReUI.UI.Global["Construction"]
            if not IsDestroyed(panel) then
                panel:Hide()
            end
        end
    end)

    ConstructionHook("SetLayout", function(field, module)
        return function(layout)
            local LayoutFor = ReUI.UI.FloorLayoutFor

            ---@type ReUI.Construction.Panel
            local panel = ReUI.UI.Global["Construction"]
            if IsDestroyed(panel) then
                return
            end

            local mfdControl = module.mfdControl
            local ordersControl = module.ordersControl
            local parent = module.controlClusterGroup

            if ordersControl then
                LayoutFor(panel)
                    :AnchorToRight(ordersControl, 0)
            else
                LayoutFor(panel)
                    :AtLeftIn(parent)
            end

            LayoutFor(panel)
                :AtBottomIn(parent, 5)
                :AtRightIn(parent, 18)
                :Over(module.controlClusterGroup, 1)
                :PerformLayout()
                :ResetWidth()
                :Hide()
        end
    end)

    ConstructionHook("SetupConstructionControl", function(field, module)
        ---@param parent Control
        ---@param mfdControl Control
        ---@param ordersControl Control
        return function(parent, mfdControl, ordersControl)
            module.mfdControl = mfdControl or false
            module.ordersControl = ordersControl
            module.controlClusterGroup = parent

            local options = ReUI.Options.Mods["ReUI.Construction"]

            ---@type ReUI.Construction.Panel
            local panel = ReUI.Construction.Panel(parent)

            options.canScroll:Bind(function(opt)
                panel:SetCanScroll(opt())
            end)

            ReUI.Construction.Grid.ItemClass.TextColor:Set(options.color:Raw())

            module.controls.constructionGroup = panel
            ReUI.UI.Global["Construction"] = panel

            return panel
        end
    end)

    ConstructionHook("OnSelection", function(field, module)
        ---@param buildableCategories string[]
        ---@param selection UserUnit[]
        ---@param isOldSelection boolean
        return function(buildableCategories, selection, isOldSelection)
            ---@type ReUI.Construction.Panel
            local panel = ReUI.UI.Global["Construction"]
            if IsDestroyed(panel) then
                return
            end

            panel:OnSelectionChanged(selection)
        end
    end)

    --- This must be removed as well as corresponding keybind
    ConstructionHook("ToggleUnitPause", function(field, module)
        return function()
            local selection = GetSelectedUnits()
            if table.empty(selection) then
                return
            end
            ---@cast selection -nil

            local paused = not GetIsPaused(selection)
            SetPaused(selection, paused)
            local checkedS = paused and "true" or "false"
            -- If we have exFacs platforms or exFac units selected, we'll pause their counterparts as well
            for _, exFac in EntityCategoryFilterDown(categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT,
                selection) do
                exFac:GetCreator():ProcessInfo('SetPaused', checkedS)
            end
        end
    end)

    ConstructionHook("setIdRelations", function(field, module)
        return function(idRelations, upgradeKey)
            ---@type ReUI.Construction.Panel
            local panel = ReUI.UI.Global["Construction"]
            if IsDestroyed(panel) then
                return
            end

            local handler = panel:GetHandler "BuildOptions" --[[@as BuildOptionsHandler?]]
            if handler then
                handler:SetHotKeys(idRelations, upgradeKey)
            end
            local handler = panel:GetHandler "BuildOptionsFactory" --[[@as BuildOptionsHandler?]]
            if handler then
                handler:SetHotKeys(idRelations, upgradeKey)
            end

        end
    end)

    --TODO
    --[x] Fix queue display for engineers (upgrades, etc)
    --[x] Fix mobile factory queue logic (drag specifically)
    --[x] Add logic for enhancements
    --[x] Fix border of the panel
    --[ ] Expose toggles for shitty keybinds
    --[x] Progress bar for construction
    --[x] don't display count for upgrades of factories
    --[x] display keybinds in construction menu
    --[x] old selection check is incorrect and must be done elsewhere
    --[x] fix progress bar with enhancements and regular construction
    --[ ] fix order of items with queue and enhancements (including cases with deleting items and when upgrades are reset)
    --[x] tech enhancements don't show available construction options
    --[x] display support factories for acus if corresponding hq presents
    --[ ] improve items logic of the grid
    --[x] bottom panel doesn't display other things in enhancements mode
    --[x] add reui error messages into game chat
    --[x] fix tech switch when queue is changed
    --[x] fix queue and chain upgrades for t2 shields of UEF and Seraphim (use command queue instead of factory queue) (it has to be fixed on sim side.)
    --[ ] display upgrade keybinds in construction menu
    --[x] add logic for removing items from queue in build options of factories
    --[ ] fix construction tab disabling when current tab is selection
    -- Enhancement logic is terrible... please kill me AAAAAAAAAAAAAAAAAAAAAAAA

    return {
        Panel = ConstructionPanel,
        Grid = ConstructionGrid,
    }
end
