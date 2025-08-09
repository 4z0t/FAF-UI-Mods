ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.LINQ >= 1.4.0",
    "ReUI.UI >= 1.4.0",
    "ReUI.UI.Color >= 1.0.0",
    "ReUI.UI.Animation >= 1.1.0",
    "ReUI.UI.Controls >= 1.0.0",
    "ReUI.UI.Views >= 1.2.0",
    "ReUI.UI.Views.Grid >= 1.0.0",
    "ReUI.Options >= 1.0.0",
    "ReUI.Units >= 1.0.0",
    "ReUI.Units.Enhancements >= 1.2.0",
}


function Main(isReplay)
    local techLevels =
    {
        "TECH1",
        "TECH2",
        "TECH3",
        "EXPERIMENTAL"
    }

    local techFiles =
    {
        ["TECH1"] = '/game/construct-tech_btn/t1_btn_',
        ["TECH2"] = '/game/construct-tech_btn/t2_btn_',
        ["TECH3"] = '/game/construct-tech_btn/t3_btn_',
        ["EXPERIMENTAL"] = '/game/construct-tech_btn/t4_btn_',
    }

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

    local Bitmap = ReUI.UI.Controls.Bitmap
    local Text = ReUI.UI.Controls.Text
    local CheckBox = ReUI.UI.Controls.CheckBox
    local Group = ReUI.UI.Controls.Group
    local BaseGridItem = ReUI.UI.Views.Grid.BaseGridItem

    local Enumerate = ReUI.LINQ.Enumerate
    local Contains = ReUI.LINQ.IPairsEnumerator:Contains()

    local LF = ReUI.UI.LayoutFunctions

    local UIUtil = import("/lua/ui/uiutil.lua")
    local StrategicIconsFile = import("/lua/ui/game/straticons.lua")
    local Tooltip = import("/lua/ui/game/tooltip.lua")
    local LazyVar = import('/lua/lazyvar.lua').Create

    local HorizontalGridScroller = import("Modules/GridScroller.lua").HorizontalGridScroller
    local LazyGrid = import("Modules/Views/LazyGrid.lua").LazyGrid
    local ButtonWithOverlay = import("Modules/Views/ButtonWithOverlay.lua").ButtonWithOverlay
    local CheckBoxWithOverlay = import("Modules/Views/CheckBoxWithOverlay.lua").CheckBoxWithOverlay


    local validIcons = { land = true, air = true, sea = true, amph = true }
    ---@param unitID string
    ---@return FileName
    ---@return FileName
    ---@return FileName
    ---@return FileName
    local function GetBackgroundTextures(unitID)
        local bp = __blueprints[unitID]
        local icon = "land"
        if unitID and unitID ~= 'default' then
            local bpIcon = bp.General.Icon
            if not validIcons[bpIcon] then
                if bpIcon then
                    WARN(debug.traceback(nil, "Invalid icon" .. bpIcon .. " for unit " .. tostring(unitID)))
                end
                bp.General.Icon = "land"
            else
                icon = bpIcon
            end
        end

        return UIUtil.UIFile('/icons/units/' .. icon .. '_up.dds'--[[@as FileName]] ),
            UIUtil.UIFile('/icons/units/' .. icon .. '_down.dds'--[[@as FileName]] ),
            UIUtil.UIFile('/icons/units/' .. icon .. '_over.dds'--[[@as FileName]] ),
            UIUtil.UIFile('/icons/units/' .. icon .. '_up.dds'--[[@as FileName]] )
    end

    ---@class ReUI.Construction.Grid.Item : BaseGridItem
    ---@field _grid  ReUI.Construction.Grid
    ---@field _bg  ReUI.UI.Controls.Bitmap
    ---@field _icon  ReUI.UI.Controls.Bitmap
    ---@field _strategicIcon  ReUI.UI.Controls.Bitmap
    ---@field _text  ReUI.UI.Controls.Text
    local ConstructionPanelItem = ReUI.Core.Class(BaseGridItem)
    {
        ---@type Lazy<Color>
        TextColor = LazyVar("ffffffff"),

        ---@param self ReUI.Construction.Grid.Item
        ---@param parent ReUI.Construction.Grid
        __init = function(self, parent)
            BaseGridItem.__init(self, parent)
            self._grid = parent

            self._bg = Bitmap(self)
            self._icon = Bitmap(self)
            self._strategicIcon = Bitmap(self)
            self._text = Text(self)
        end,

        ---@param self ReUI.Construction.Grid.Item
        ---@param layouter ReUI.UI.Layouter
        InitLayout = function(self, layouter)
            BaseGridItem.InitLayout(self, layouter)
            layouter(self._bg)
                :Fill(self)
                :DisableHitTest()
                :Over(self, 1)

            layouter(self._icon)
                :Fill(self)
                :DisableHitTest()
                :Over(self, 2)

            layouter(self._strategicIcon)
                :AtLeftTopIn(self, 4, 4)
                :DisableHitTest()
                :Over(self, 3)

            layouter(self._text)
                :AtRightBottomIn(self)
                :Color(self.TextColor)
                :DropShadow(true)
                :DisableHitTest()
                :Over(self, 10)

            layouter(self)
                :Color "00000000"

            self._text:SetFont("Arial", 20)
        end,

        ---@type string
        ---@diagnostic disable-next-line:assign-type-mismatch
        Icon = ReUI.Core.Property
        {
            ---@param self ReUI.Construction.Grid.Item
            set = function(self, value)
                if value == nil then
                    self._icon:Hide()
                    return
                end

                if DiskGetFileInfo(UIUtil.UIFile('/icons/units/' .. value .. '_icon.dds'--[[@as FileName]] , true)) then
                    self._icon:SetTexture(UIUtil.UIFile('/icons/units/' .. value .. '_icon.dds'--[[@as FileName]] , true))
                else
                    self._icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
                end
                self._icon:Show()
            end
        },

        ---@type string
        ---@diagnostic disable-next-line:assign-type-mismatch
        IconColor = ReUI.Core.Property
        {
            ---@param self ReUI.Construction.Grid.Item
            set = function(self, value)
                if value == nil then
                    self._icon:Hide()
                    return
                end
                self._icon:SetSolidColor(value)
                self._icon:Show()
            end
        },

        ---@type string
        ---@diagnostic disable-next-line:assign-type-mismatch
        StrategicIcon = ReUI.Core.Property
        {
            ---@param self ReUI.Construction.Grid.Item
            set = function(self, value)
                if value == nil then
                    self._strategicIcon:Hide()
                    return
                end

                local iconName = __blueprints[value].StrategicIconName
                if not iconName then
                    self._strategicIcon:Hide()
                    return
                end

                local path = '/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds' --[[@as FileName]]
                if DiskGetFileInfo(path) then
                    self._strategicIcon:SetTexture(path)
                    self._strategicIcon:Show()
                    return
                end

                local icon = StrategicIconsFile.aSpecificStratIcons[value] or
                    StrategicIconsFile.aStratIconTranslation[iconName]

                if not icon then
                    self._strategicIcon:Hide()
                    return
                end

                local path = '/textures/ui/icons_strategic/' .. icon .. '.dds' --[[@as FileName]]
                if not DiskGetFileInfo(path) then
                    self._strategicIcon:Hide()
                    return
                end

                self._strategicIcon:SetTexture(path)
                self._strategicIcon:Show()
            end
        },

        ---@type string
        ---@diagnostic disable-next-line:assign-type-mismatch
        BackGround = ReUI.Core.Property
        {
            ---@param self ReUI.Construction.Grid.Item
            set = function(self, value)
                if value == nil then
                    self._bg:Hide()
                    return
                end

                self._bg:SetTexture(value)
                self._bg:Show()
            end
        },

        ---@type string|number
        ---@diagnostic disable-next-line:assign-type-mismatch
        Text = ReUI.Core.Property
        {
            ---@param self ReUI.Construction.Grid.Item
            set = function(self, value)
                if value == nil then
                    self._text:Hide()
                    return
                end

                self._text:SetText(value)
                self._text:Show()
            end
        },

        ---@param self ReUI.Construction.Grid.Item
        ---@param id string
        ---@param mode? "up"|"down"|"rest"|"disabled"
        DisplayBPID = function(self, id, mode)
            mode = mode or "rest"
            self.StrategicIcon = id
            self:SetBackGroundFromId(id, mode)
            self.Icon = id
        end,

        ---@param self ReUI.Construction.Grid.Item
        ClearDisplay = function(self)
            self.StrategicIcon = nil
            self.BackGround = nil
            self.Icon = nil
            self.Text = nil
            self._text:SetColor(self.TextColor)
        end,

        ---@param self ReUI.Construction.Grid.Item
        ---@param id string
        ---@param mode? "up"|"down"|"rest"|"disabled"
        SetBackGroundFromId = function(self, id, mode)
            if id == nil then
                self._bg:Hide()
                return
            end

            local up, down, rest, dis = GetBackgroundTextures(id)
            local texture = rest
            if mode == "up" then
                texture = up
            elseif mode == "rest" then
                texture = rest
            elseif mode == "down" then
                texture = down
            elseif mode == "disabled" then
                texture = dis
            end
            self._bg:SetTexture(texture)
            self._bg:Show()
        end,

        ---@param self ReUI.Construction.Grid.Item
        ---@param immediately? boolean
        UpdatePanel = function(self, immediately)
            local panel = self._grid.panel
            if immediately then
                panel:Refresh()
            else
                ForkThread(panel.Refresh, panel)
            end
        end,

        ---@param self ReUI.Construction.Grid.Item
        OnDestroy = function(self)
            self._grid = nil
            self._bg = nil
            self._icon = nil
            self._strategicIcon = nil
            self._text = nil
            BaseGridItem.OnDestroy(self)
        end,
    }

    ---@alias UpdateReason
    ---| "selection"
    ---| "queue"
    ---| "refresh"

    ---@alias TechLevel
    ---| "NONE"
    ---| "TECH1"
    ---| "TECH2"
    ---| "TECH3"
    ---| "EXPERIMENTAL"

    ---@class ConstructionHandlerData
    ---@field tab Tabs
    ---@field name string
    ---@field displayMode "grid"|"list"
    ---@field handler ASelectionHandler

    ---@class ConstructionContext
    ---@field selection UserUnit[]?
    ---@field tech TechLevel
    ---@field slot EnhancementSlot
    ---@field reason UpdateReason
    ---@field panel ReUI.Construction.Panel
    ---@field tab Tabs|"all"

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
        ItemClass = ConstructionPanelItem,

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

            self.AutoLayout = false
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
        OnResized = function(self)
            if self:IsHidden() then
                return
            end
            self:Refresh()
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
            ---@cast actions -nil
            ---@cast context -nil
            ---@cast handlerData -nil

            self:Show()

            scroller.ItemCount = table.getn(actions)

            local name = handlerData.name
            local index = scroller.StartIndex
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
            self._border = nil
            self._btnNext = nil
            self._btnPrev = nil
            self._btnStart = nil
            self._btnEnd = nil
            self._overlayNext = nil
            self._overlayPrev = nil
            self._overlayStart = nil
            self._overlayEnd = nil
            LazyGrid.OnDestroy(self)
        end,
    }

    ---@class ConstructionBorder : ReUI.UI.Views.WindowFrame
    local ConstructionBorder = ReUI.Core.Class(ReUI.UI.Views.WindowFrame)
    {
    }

    ---@class Tab : ReUI.UI.Controls.CheckBox
    local Tab = ReUI.Core.Class(CheckBox)
    {
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

    ---@alias Tabs
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

    ---@class ReUI.Construction.Panel : ReUI.UI.Controls.Group
    ---@field _context ConstructionContext
    ---@field _componentClasses table<string, fun(instance: BaseGridItem):AItemComponent>
    ---@field _selectionHandlers table<string, ASelectionHandler>
    ---@field _tabs table<string, ReUI.UI.Controls.CheckBox>
    ---@field _slots table<string, ReUI.UI.Controls.CheckBox>
    ---@field _currentTab Tabs
    ---@field _canScroll boolean
    ---@field _primary ReUI.Construction.Grid
    ---@field _enhancements ReUI.Construction.Grid
    ---@field _secondary ReUI.Construction.Grid
    ---@field _border ConstructionBorder
    ---@field _pause CheckBoxWithOverlay
    ---@field _repeat CheckBoxWithOverlay
    ---@field _constructionTab Tab
    ---@field _selectionTab Tab
    ---@field _enhancementsTab Tab
    local ConstructionPanel = ReUI.Core.Class(Group)
    {
        ---@type ConstructionHandlerData[]
        PrimaryHandlers = {
            {
                tab = "construction",
                name = "BuildOptions",
                displayMode = "grid",
                handler = import("Modules/Components/BuildOptions.lua").BuildOptionsHandler
            },
            {
                tab = "construction",
                name = "BuildOptionsFactory",
                displayMode = "grid",
                handler = import("Modules/Components/BuildOptions.lua").BuildOptionsFactoryHandler
            },
            {
                tab = "selection",
                name = "UpgradeChain",
                displayMode = "list",
                handler = import("Modules/Components/UpgradeChain.lua").UpgradeChainHandler,
            },
            {
                tab = "selection",
                name = "Selection",
                displayMode = "grid",
                handler = import("Modules/Components/SelectedUnits.lua").SelectedUnitsListHandler
            },
            {
                tab = "enhancements",
                name = "Enhancements",
                displayMode = "list",
                handler = import("Modules/Components/Enhancements.lua").EnhancementsHandler,
            },
        },

        ---@type ConstructionHandlerData[]
        SecondaryHandlers = {
            {
                tab = "construction",
                name = "FactoryQueue",
                handler = import("Modules/Components/QueueList.lua").QueueListHandler
            },
            {
                tab = "construction",
                name = "BuildQueue",
                handler = import("Modules/Components/BuildQueue.lua").BuildQueueHandler
            },
            {
                tab = "selection",
                name = "TransportCargo",
                handler = import("Modules/Components/TransportCargo.lua").TransportCargoHandler
            },
            {
                tab = "selection",
                name = "CarrierCargo",
                handler = import("Modules/Components/CarrierCargo.lua").CarrierCargoHandler
            },
            {
                tab = "selection",
                name = "Selection",
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
            self._currentTab = "selection"
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

            self._primary = ReUI.Construction.Grid(self, self._componentClasses)
            self._secondary = ReUI.Construction.Grid(self, self._componentClasses)
            self._enhancements = ReUI.Construction.Grid(self, self._componentClasses)
            self._border = ConstructionBorder(self)

            self._pause = CheckBoxWithOverlay(self)
            self._pause.OnCheck = function(pause, checked)
                self:OnPause(checked)
            end

            self._repeat = CheckBoxWithOverlay(self)
            self._repeat.OnCheck = function(repeat_, checked)
                self:OnRepeat(checked)
            end

            self._tabs = {}

            local function OnCheck(_tab, checked)
                ---@param tab ReUI.UI.Controls.CheckBox
                for _, tab in self._tabs do
                    if tab ~= _tab then
                        tab:SetCheck(false, true)
                    end
                end

                self._context.tech = _tab.tech
                self:Refresh()
            end

            for i, t in techLevels do
                self._tabs[i] = CheckBox(self)
                self._tabs[i].tech = t
                self._tabs[i].OnCheck = OnCheck
                self._tabs[i].mClickCue = 'UI_Tab_Click_02'
                self._tabs[i].mRolloverCue = 'UI_Tab_Rollover_02'
            end

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

            self._constructionTab = Tab(self)
            Tooltip.AddControlTooltip(self._constructionTab, 'construction_tab_construction')
            ---@param tab Tab
            ---@param checked boolean
            self._constructionTab.OnCheck = function(tab, checked)
                self:OnCheckedConstructionTab()
            end

            self._selectionTab = Tab(self)
            Tooltip.AddControlTooltip(self._selectionTab, 'construction_tab_attached')
            ---@param tab Tab
            ---@param checked boolean
            self._selectionTab.OnCheck = function(tab, checked)
                self:OnCheckedSelectionTab()
            end

            self._enhancementsTab = Tab(self)
            Tooltip.AddControlTooltip(self._enhancementsTab, 'construction_tab_enhancement')
            ---@param tab Tab
            ---@param checked boolean
            self._enhancementsTab.OnCheck = function(tab, checked)
                self:OnCheckedEnhancementsTab()
            end

            self._primary.Rows = options.rows:Raw()
            self._primary.VerticalSpacing = 2
            self._primary.HorizontalSpacing = 2
            self._primary.RowHeight = 50
            self._primary.ColumnWidth = 50

            self._secondary.Rows = 1
            self._secondary.VerticalSpacing = 2
            self._secondary.HorizontalSpacing = 2
            self._secondary.RowHeight = 50
            self._secondary.ColumnWidth = 50

            self._enhancements.Rows = 1
            self._enhancements.VerticalSpacing = 2
            self._enhancements.HorizontalSpacing = 20
            self._enhancements.RowHeight = 50
            self._enhancements.ColumnWidth = 50

        end,

        ---@param self ReUI.Construction.Panel
        ---@param layouter ReUI.UI.Layouter
        InitLayout = function(self, layouter)
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

            self._primary.AutoWidth = false
            self._secondary.AutoWidth = false
            self._enhancements.AutoWidth = false

            layouter(self._secondary)
                :AtBottomIn(self, 5)
                :AtLeftIn(self, 85)
                :AtRightIn(self, 50)
                :PerformLayout()
                :ResetWidth()

            layouter(self._primary)
                :Above(self._secondary, 3)
                :AtLeftIn(self, 85)
                :AtRightIn(self, 50)
                :PerformLayout()
                :ResetWidth()

            layouter(self._enhancements)
                :Above(self._secondary, 3)
                :AtLeftIn(self, 85)
                :AtRightIn(self, 50)
                :PerformLayout()
                :ResetWidth()
                :Hide()

            layouter(self._repeat)
                :FillVertically(self._enhancements)
                :AtLeftIn(self, 10)

            self._repeat:SetNewTextures(
                textures.midBtn.up,
                textures.midBtn.selected,
                textures.midBtn.over,
                textures.midBtn.over,
                textures.midBtn.dis,
                textures.midBtn.dis
            )

            self._repeat:SetOverlayTextures(
                UIUtil.UIFile('/game/construct-sm_btn/infinite_off.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/infinite_on.dds')
            )

            layouter(self._pause)
                :FillVertically(self._secondary)
                :AtLeftIn(self, 10)

            self._pause:SetNewTextures(
                textures.midBtn.up,
                textures.midBtn.selected,
                textures.midBtn.over,
                textures.midBtn.over,
                textures.midBtn.dis,
                textures.midBtn.dis
            )
            self._pause:SetOverlayTextures(
                UIUtil.UIFile('/game/construct-sm_btn/pause_off.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/pause_on.dds')
            )


            layouter(self._border)
                :FillFixedBorder(self, -2)
                :Under(self, 5)
                :DisableHitTest(true)

            layouter(self)
                :AtTopIn(self._primary, -5)
                :EnableHitTest()

            local prev
            ---@param tab ReUI.UI.Controls.CheckBox
            for i, tab in self._tabs do
                if prev then
                    layouter(tab)
                        :RightOf(prev)
                else
                    layouter(tab)
                        :Above(self._primary, 3)
                end

                local pre = techFiles[tab.tech] --[[@as FileName]]
                tab:SetNewTextures(
                    UIUtil.UIFile(pre .. 'up.dds'),
                    UIUtil.UIFile(pre .. 'selected.dds'),
                    UIUtil.UIFile(pre .. 'over.dds'),
                    UIUtil.UIFile(pre .. 'down.dds'),
                    UIUtil.UIFile(pre .. 'dis.dds'),
                    UIUtil.UIFile(pre .. 'dis.dds')
                )

                prev = tab
            end
            prev = nil

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
                :AnchorToLeft(self, -6)
                :AtBottomIn(self, -10)

            self._enhancementsTab:SetNewTextures(GetTabTextures(tabFiles.enhancement))
            self._enhancementsTab:UseAlphaHitTest(true)

            layouter(self._selectionTab)
                :Above(self._enhancementsTab, -16)

            self._selectionTab:SetNewTextures(GetTabTextures(tabFiles.selection))
            self._selectionTab:UseAlphaHitTest(true)

            layouter(self._constructionTab)
                :Above(self._selectionTab, -16)

            self._constructionTab:SetNewTextures(GetTabTextures(tabFiles.construction))
            self._constructionTab:UseAlphaHitTest(true)
        end,

        HandleEvent = function(self, event)
            if event.Type == "WheelRotation" then
                return self._canScroll
            end
            return false
        end,

        ---@param self ReUI.Construction.Panel
        OnCheckedConstructionTab = function(self)
            if self._currentTab == "construction" then
                return
            end

            self:ApplyToTabs(self.ShowCheckBox)
            self:ApplyToSlots(self.HideCheckBox)

            self._context.tab = "construction"
            self:SetCurrentTab("construction")
            self:Refresh()
        end,

        ---@param self ReUI.Construction.Panel
        OnCheckedSelectionTab = function(self)
            if self._currentTab == "selection" then
                return
            end

            self:ApplyToTabs(self.HideCheckBox)
            self:ApplyToSlots(self.HideCheckBox)

            self._context.tab = "selection"
            self:SetCurrentTab("selection")
            self:Refresh()
        end,

        ---@param self ReUI.Construction.Panel
        OnCheckedEnhancementsTab = function(self)
            if self._currentTab == "enhancements" then
                return
            end
            self:ApplyToTabs(self.HideCheckBox)
            for _, slot in self._slots do
                slot:Show()
                slot:SetCheck(slot.slot == self._context.slot, true)
            end
            self._context.tab = "enhancements"
            self:SetCurrentTab("enhancements")
            self:Refresh()
        end,

        ---@param self ReUI.Construction.Panel
        ---@param tab Tabs
        SetCurrentTab = function(self, tab)
            self._currentTab = tab
            self._constructionTab:SetCheck(tab == "construction", true)
            self._selectionTab:SetCheck(tab == "selection", true)
            self._enhancementsTab:SetCheck(tab == "enhancements", true)
        end,

        ---@param self ReUI.Construction.Panel
        ---@param techs table<TechLevel, boolean>
        SetAvailableTech = function(self, techs)
            ---@param tab ReUI.UI.Controls.CheckBox
            for i, tab in self._tabs do
                local enabled = techs[tab.tech]
                if enabled then
                    tab:Enable()
                else
                    tab:Disable()
                end
            end
        end,

        ---@param self ReUI.Construction.Panel
        ---@param tech TechLevel
        SetActiveTech = function(self, tech)
            ---@param tab ReUI.UI.Controls.CheckBox
            for i, tab in self._tabs do
                tab:SetCheck(tab.tech == tech, true)
            end
        end,

        ---@param self ReUI.Construction.Panel
        ---@param paused boolean
        OnPause = function(self, paused)
            local selection = self._context.selection
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

        ---@param self ReUI.Construction.Panel
        OnRepeat = function(self, repeat_)
            local selection = self._context.selection
            if table.empty(selection) then
                return
            end
            ---@cast selection -nil

            local isRepeatBuild = repeat_ and 'true' or 'false'
            ---@param unit UserUnit
            for _, unit in selection do
                unit:ProcessInfo('SetRepeatQueue', isRepeatBuild)
                if EntityCategoryContains(categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT, unit) then
                    unit:GetCreator():ProcessInfo('SetRepeatQueue', isRepeatBuild)
                end
            end
        end,

        ---@param self ReUI.Construction.Panel
        UpdatePause = function(self)
            local selection = self._context.selection
            if table.empty(selection) then
                self._pause:Disable()
                return
            end
            ---@cast selection -nil

            local orders = GetUnitCommandData(selection)
            local isPauseAvailable = Contains(orders, "RULEUCC_Pause")

            if isPauseAvailable then
                self._pause:SetCheck(GetIsPaused(selection), true)
                self._pause:Enable()
            else
                self._pause:Disable()
            end

        end,

        ---@param self ReUI.Construction.Panel
        UpdateRepeat = function(self)
            local selection = self._context.selection
            if table.empty(selection) then
                self._repeat:Disable()
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

                self._repeat:SetCheck(allRepeatQueue, true)
                self._repeat:Enable()
            else
                self._repeat:Disable()
            end
        end,

        ---@param self ReUI.Construction.Panel
        ---@param func fun(self: ReUI.Construction.Panel, slot:ReUI.UI.Controls.CheckBox)
        ApplyToSlots = function(self, func)
            for _, slot in self._slots do
                func(self, slot)
            end
        end,

        ---@param self ReUI.Construction.Panel
        ---@param func fun(self: ReUI.Construction.Panel, slot:ReUI.UI.Controls.CheckBox)
        ApplyToTabs = function(self, func)
            for _, tab in self._tabs do
                func(self, tab)
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
                local handler = self._selectionHandlers[name]

                local actions, context = handler:Update(selfContext)
                if actions then
                    return handlerData, actions, context or selfContext
                end
            end
            return nil, nil, nil
        end,

        ---@param self ReUI.Construction.Panel
        ---@param reason UpdateReason
        Update = function(self, reason)
            self._context.reason = reason

            local primaryHandlerData, primaryActions, primaryContext = self:GetActionsFor(self.PrimaryHandlers)
            local secondaryHandlerData, secondaryActions, secondaryContext = self:GetActionsFor(self.SecondaryHandlers,
                self._context.tab == "enhancements")

            if not primaryHandlerData and not secondaryHandlerData then
                self:Hide()
                self._currentTab = "none"
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
            self:SetCurrentTab(tab)

            if reason == "selection" then
                if tab == "construction" then
                    self:ApplyToTabs(self.ShowCheckBox)
                    self:ApplyToSlots(self.HideCheckBox)
                    self._constructionTab:Enable()
                    self._selectionTab:Enable()
                elseif tab == "selection" then
                    self:ApplyToTabs(self.HideCheckBox)
                    self:ApplyToSlots(self.HideCheckBox)
                    self._constructionTab:Disable()
                    self._selectionTab:Enable()
                elseif tab == "enhancements" then
                    self:ApplyToTabs(self.HideCheckBox)
                    self:ApplyToSlots(self.ShowCheckBox)
                end

                if HasEnhancementsForSelection(self._context.selection) then
                    self._enhancementsTab:Enable()
                else
                    self._enhancementsTab:Disable()
                end
            end

            self:UpdatePause()
            self:UpdateRepeat()
        end,

        ---@param self ReUI.Construction.Panel
        Refresh = function(self)
            self:Update("refresh")
        end,

        ---@param self ReUI.Construction.Panel
        ---@param selection UserUnit[]?
        OnSelectionChanged = function(self, selection)
            self:Show()

            if table.equal(self._context.selection, selection) then
                -- self._context.tab = "all"
                -- self._context.selection = selection
                -- self._context.tech = "NONE"
                -- self._context.slot = "Back"
            else
                self._context.tab = "all"
                self._context.selection = selection
                self._context.tech = "NONE"
                self._context.slot = "Back"
            end

            self:Update("selection")
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
                    :AnchorToRight(ordersControl, 55)
            else
                LayoutFor(panel)
                    :AtLeftIn(parent, 460)
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

            -- if isOldSelection then -- This for some reason causes an error with destroyed units
            --     panel:Refresh()
            --     return
            -- end

            panel:OnSelectionChanged(selection)
        end
    end)

    --- This must be removed as well as corresponding keybind
    ConstructionHook("ToggleUnitPause", function(field, module)
        return function()
            ---@type ReUI.Construction.Panel
            local panel = ReUI.UI.Global["Construction"]
            if IsDestroyed(panel) then
                return
            end

            panel._pause:ToggleCheck()
        end
    end)

    --TODO
    --[x] Fix queue display for engineers (upgrades, etc)
    --[x] Fix mobile factory queue logic (drag specifically)
    --[x] Add logic for enhancements
    --[ ] Fix border of the panel
    --[ ] Expose toggles for shitty keybinds
    --[x] Progress bar for construction
    --[x] don't display count for upgrades of factories
    --[ ] display keybinds in construction menu
    --[ ] old selection check is incorrect and must be done elsewhere
    --[x] fix progress bar with enhancements and regular construction
    --[ ] fix order of items with queue and enhancements (including cases with deleting items and when upgrades are reset)
    --[x] tech enhancements don't show available construction options
    --[x] display support factories for acus if corresponding hq presents
    --[ ] improve items logic of the grid
    --[x] bottom panel doesn't display other things in enhancements mode
    --[x] add reui error messages into game chat
    --[x] fix tech switch when queue is changed
    -- Enhancement logic is terrible... please kill me AAAAAAAAAAAAAAAAAAAAAAAA

    return {
        Panel = ConstructionPanel,
        Grid = ConstructionGrid,
    }
end
