local Dragger = import('/lua/maui/dragger.lua').Dragger
local Prefs = import('/lua/user/prefs.lua')
local Window = import('/lua/maui/window.lua').Window
local Edit = import('/lua/maui/edit.lua').Edit
local Text = import('/lua/maui/text.lua').Text
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Control = import('/lua/maui/control.lua').Control
local LazyVar = import('/lua/lazyvar.lua')
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local BCLineModule = import("BCline.lua")
local BCLine = BCLineModule.BCLine
local Json = import("/lua/system/dkson.lua").json
local Tooltip = import('/lua/ui/game/tooltip.lua')

-- debug.listcode
--[[
    {
        {
            key = ..., - bind key
            title = ... (if its tree)
            data = string | table - data(table - tree, string - line)
            team =... bool
        },
        ...
    }
]]

local playersCache = nil
local MINWIDTH = 200
local MINHEIGHT = 100
local focusTitleColor = 'ffffff00'
local defaultTitleColor = UIUtil.fontColor

BCWindow = Class(Window) {
    __init = function(self, parent)
        local windowTextures = {
            tl = UIUtil.SkinnableFile('/game/panel/panel_brd_ul.dds'),
            tr = UIUtil.SkinnableFile('/game/panel/panel_brd_ur.dds'),
            tm = UIUtil.SkinnableFile('/game/panel/panel_brd_horz_um.dds'),
            ml = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_l.dds'),
            m = UIUtil.SkinnableFile('/game/panel/panel_brd_m.dds'),
            mr = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_r.dds'),
            bl = UIUtil.SkinnableFile('/game/panel/panel_brd_ll.dds'),
            bm = UIUtil.SkinnableFile('/game/panel/panel_brd_lm.dds'),
            br = UIUtil.SkinnableFile('/game/panel/panel_brd_lr.dds'),
            borderColor = '00415055'
        }

        LOG("window init")

        Window.__init(self, parent, 'Main root', nil, false, true, false, false, 'BCWindow', {
            Left = parent.Width() / 2 - 250,
            Right = parent.Width() / 2 + 250,
            Top = parent.Height() / 2 - 250,
            Bottom = parent.Height() / 2 + 250
        }, windowTextures)
        self:SetMinimumResize(MINWIDTH, MINHEIGHT)
        LayoutHelpers.DepthOverParent(self, parent, 1)

        self._title:SetFont('Arial Black', 18)
        self._title:DisableHitTest()
        self._titleColor = LazyVar.Create()
        self._titleColor:Set(defaultTitleColor)
        self._title:SetColor(self._titleColor)

        self.TitleGroup._bg = Bitmap(self.TitleGroup)

        LayoutHelpers.FillParent(self.TitleGroup._bg, self.TitleGroup)
        self.TitleGroup._bg:DisableHitTest()
        self.TitleGroup._bg:SetSolidColor("ff000000")
        self.TitleGroup._bg:SetAlpha(0.5)
        local TGHandleEvent = self.TitleGroup.HandleEvent

        self.TitleGroup.HandleEvent = function(control, event)
            TGHandleEvent(control, event)
            if event.Type == 'ButtonPress' then
                self:AcquireKeyboard()
            end
        end
        LayoutHelpers.DepthUnderParent(self.TitleGroup._bg, self.TitleGroup, 10)

        -- tree data
        self._treeData = Prefs.GetFromCurrentProfile('betterchat') or {
            data = {},
            title = 'Main root'
        }
        -- the way we reached cur level
        -- contains indexes in order to get cur level
        self._route = {}
        -- self._prevLevel = nil
        self._curLevel = self._treeData
        if playersCache then
            LOG('loaded from prefs')
        else
            self:SetupPlayersLevel()
            playersCache = true
        end

        -- TODO:
        -- Tooltip.AddButtonTooltip(self._closeBtn, 'chat_close')
        LOG("drags init")
        self:CreateDrags()

        LOG("scroll init")
        -- scroll 
        self._topLine = 1
        self._numLines = 0
        self._dataSize = table.getn(self._treeData.data)
        self._scroll = UIUtil.CreateVertScrollbarFor(self, -43, nil, 10, 35) -- scroller
        LayoutHelpers.DepthOverParent(self._scroll, self, 10)

        LOG("bottom panel init")
        -- bottom panel
        self._bottomPanelGroup = self:CreateBottomPanel(self)

        LOG("lines group init")
        -- lines
        self._lineGroup = Group(self)
        LayoutHelpers.AnchorToTop(self._lineGroup, self._bottomPanelGroup, 4)
        LayoutHelpers.AtLeftIn(self._lineGroup, self.ClientGroup, 5)
        LayoutHelpers.AnchorToLeft(self._lineGroup, self._scroll, 5)
        LayoutHelpers.AtTopIn(self._lineGroup, self.ClientGroup, 5)
        LayoutHelpers.DepthOverParent(self._lineGroup, self, 10)
        self._lineGroup._lines = {}

        -- TODO:
        -- CreateButtonStd instead
        LOG("return button init")
        self._returnButton = Button(self.TitleGroup, UIUtil.UIFile('/game/construct-sm_horiz_btn/infinite_on.dds'),
            UIUtil.UIFile('/game/construct-sm_horiz_btn/infinite_on.dds'),
            UIUtil.UIFile('/game/construct-sm_horiz_btn/infinite_off.dds'),
            UIUtil.UIFile('/game/construct-sm_horiz_btn/infinite_off.dds'))

        LayoutHelpers.AnchorToLeft(self._returnButton, self._configBtn, -10)
        LayoutHelpers.AtTopIn(self._returnButton, self.TitleGroup, 5)
        LayoutHelpers.DepthOverParent(self._configBtn, self._returnButton, 1)
        self._returnButton.OnClick = function(control)

            -- LOG("RETURN")
            self:GetPrevLevel()
        end

        -- keyboard input
        self._inputAcquier = Group(self)
        LayoutHelpers.AtLeftTopIn(self._inputAcquier, self)
        LayoutHelpers.SetDimensions(self._inputAcquier, 1, 1)
        self._inputAcquier.HandleEvent = function(control, event)
            if event.Type == 'KeyDown' then
                if event.KeyCode == UIUtil.VK_ESCAPE then
                    -- close window
                    self:OnClose()
                elseif event.KeyCode == UIUtil.VK_BACKSPACE then
                    -- go to prev tree
                    self:GetPrevLevel()
                    -- elseif event.KeyCode == UIUtil.VK_UP or event.KeyCode == 317 then
                    --     -- scroll up
                    --     self:ScrollLines(nil, -1)
                    -- elseif event.KeyCode == UIUtil.VK_DOWN or event.KeyCode == 319 then
                    --     -- scroll down
                    --     self:ScrollLines(nil, 1)
                elseif event.KeyCode == UIUtil.VK_TAB then
                    self:SetShadowMode(not self:GetShadowMode())
                elseif event.KeyCode == UIUtil.VK_ENTER then
                else
                    if event.KeyCode <= 0x7F then
                        local key = string.char(event.KeyCode)
                        self:GetLine(key, event.Modifiers)
                    else
                        -- LOG("UNKNOWN KEY")
                    end
                end

            end

        end
        self._inputAcquier._left = false
        self._inputAcquier._changed = false
        self._inputAcquier.OnLoseKeyboardFocus = function(control)
            control._left = true
            control._changed = false
        end
        self._inputAcquier.OnKeyboardFocusChange = function(control)

            if control._left then
                self._titleColor:Set(defaultTitleColor)
                control._left = false
            elseif not control._changed then
                self._titleColor:Set(focusTitleColor)
                control._changed = true
                control:AcquireKeyboardFocus(false)
            end
        end

        -- hint bitmap
        self._hint = Bitmap(self.TitleGroup, UIUtil.SkinnableFile('/game/orders-panel/question-mark_bmp.dds'))
        LayoutHelpers.AnchorToLeft(self._hint, self._returnButton, -10)
        LayoutHelpers.AtTopIn(self._hint, self.TitleGroup, 10)
        LayoutHelpers.DepthOverParent(self._hint, self.TitleGroup, 10)
        Tooltip.AddControlTooltip(self._hint, 'bc_hint')
        self:SetNeedsFrameUpdate(true)
        self:RenderLines()
        self:AcquireKeyboard()
    end,

    GetPlayersLevel = function(self)
        for id, line in self._treeData.data do
            if line.players then
                return line
            end
        end

        table.insert(self._treeData.data, {
            key = '',
            title = 'Players',
            players = true,
            unremovable = true,
            data = {{
                key = 'A',
                title = 'Allies',
                unremovable = true,
                data = {}
            }, {
                key = 'E',
                title = 'Enemies',
                unremovable = true,
                data = {}
            }}
        })
        return self._treeData.data[table.getn(self._treeData.data)]
    end,

    SetupPlayersLevel = function(self)
        LOG('creating new players table')
        local focusArmy = GetFocusArmy()
        local playersLevel = self:GetPlayersLevel()
        local allyCount = 1
        local enemyCount = 1
        playersLevel.data[1].data = {}
        playersLevel.data[2].data = {}
        local armiesTable = GetArmiesTable().armiesTable
        for id, army in armiesTable do
            if not army.civilian then
                if IsAlly(id, focusArmy) then
                    table.insert(playersLevel.data[1].data, {
                        key = tostring(allyCount),
                        data = army.nickname,
                        team = true,
                        unremovable = true,
                        send = false
                    })
                    allyCount = allyCount + 1
                else
                    table.insert(playersLevel.data[2].data, {
                        key = tostring(enemyCount),
                        data = army.nickname,
                        team = true,
                        unremovable = true,
                        send = false
                    })
                    enemyCount = enemyCount + 1
                end
            end
        end
    end,

    GetLine = function(self, key, modifiers)
        for id, line in self._curLevel.data do
            if line.key == key and line.modifiers.Alt == modifiers.Alt and line.modifiers.Ctrl == modifiers.Ctrl and
                line.modifiers.Shift == modifiers.Shift then
                self:CallLine(id)
                break
            end
        end
    end,

    CallLine = function(self, id)
        local line = self._curLevel.data[id]
        if line.title then
            -- call tree
            self:SetCurLevel(id)
        elseif line.ping then
            -- make ping
            self:MakePing(id)
        else
            -- call phrase
            self:CallPhrase(id)
        end
    end,

    MakePing = function(self, id)
        local position = GetMouseWorldPos()
        local data = {
            Owner = GetFocusArmy() - 1,
            Type = 'marker',
            Location = position,
            Name = self._curLevel.data[id].data
        }
        data = table.merged(data, import("/lua/ui/game/ping.lua").PingTypes.marker)
        local armies = GetArmiesTable()
        data.Color = armies.armiesTable[armies.focusArmy].color

        SimCallback({
            Func = 'SpawnPing',
            Args = data
        })
    end,

    RemoveLine = function(self, id)
        if self._curLevel.data[id].unremovable then
            return
        end
        table.remove(self._curLevel.data, id)
        self._dataSize = table.getn(self._curLevel.data)
        self:CalcVisible()
    end,

    CallPhrase = function(self, id)
        local msg = {
            Chat = true,
            text = self._curLevel.data[id].data
        }
        if self._curLevel.data[id].team then
            msg.to = 'allies'
        else
            msg.to = 'all'
        end
        SessionSendChatMessage(FindClients(), msg)
    end,

    SetCurLevel = function(self, id)
        table.insert(self._route, id)
        self._curLevel = self._curLevel.data[id]
        self._topLine = 1
        self._dataSize = table.getn(self._curLevel.data)
        self:SetTitle(self._curLevel.title)
        self:CalcVisible()
    end,

    AcquireKeyboard = function(self)
        self._titleColor:Set(focusTitleColor)
        self._inputAcquier:AcquireKeyboardFocus(false)
    end,
    AbandonKeyboard = function(self)
        self._titleColor:Set(defaultTitleColor)
        self._inputAcquier:AbandonKeyboardFocus()
    end,

    -- returns true if key was set successsfully unless false
    SetKey = function(self, key, modifiers, id)
        -- TODO: numpad keys
        if key > 0x7F then
            return false
        end
        key = string.char(key)
        for id, line in self._curLevel.data do
            if line.key == key and line.modifiers.Alt == modifiers.Alt and line.modifiers.Ctrl == modifiers.Ctrl and
                line.modifiers.Shift == modifiers.Shift then
                return false
            end
        end
        self._curLevel.data[id].key = key
        self._curLevel.data[id].modifiers = modifiers
        return true
    end,

    SetData = function(self, id, data)
        self._curLevel.data[id] = data
    end,

    GetPrevLevel = function(self)

        table.remove(self._route)
        self._curLevel = self._treeData

        for _, key in self._route do
            self._curLevel = self._curLevel.data[key]
        end
        self:SetTitle(self._curLevel.title)
        self._topLine = 1
        self._dataSize = table.getn(self._curLevel.data)
        self:CalcVisible()

    end,

    CreateDrags = function(self)
        self.DragTL = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
        self.DragTR = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
        self.DragBL = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
        self.DragBR = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

        LayoutHelpers.AtLeftTopIn(self.DragTL, self, -24, -8)
        LayoutHelpers.AtRightTopIn(self.DragTR, self, -22, -8)
        LayoutHelpers.AtLeftBottomIn(self.DragBL, self, -24, -8)
        LayoutHelpers.AtRightBottomIn(self.DragBR, self, -22, -8)

        LayoutHelpers.DepthOverParent(self.DragTL, self, 10)
        LayoutHelpers.DepthOverParent(self.DragTR, self, 10)
        LayoutHelpers.DepthOverParent(self.DragBL, self, 10)
        LayoutHelpers.DepthOverParent(self.DragBR, self, 10)

        self.DragTL:DisableHitTest()
        self.DragTR:DisableHitTest()
        self.DragBL:DisableHitTest()
        self.DragBR:DisableHitTest()
    end,

    CreateBottomPanel = function(self, parent)
        local _bottomPanelGroup = Group(parent)

        LayoutHelpers.SetHeight(_bottomPanelGroup, 20)
        LayoutHelpers.AtLeftIn(_bottomPanelGroup, self.ClientGroup, 5)
        LayoutHelpers.AnchorToLeft(_bottomPanelGroup, self._scroll, 5)
        LayoutHelpers.AtBottomIn(_bottomPanelGroup, self.ClientGroup, 5)
        LayoutHelpers.DepthOverParent(_bottomPanelGroup, self, 10)

        LayoutHelpers.ResetTop(_bottomPanelGroup)

        -- button for adding lines of tree
        _bottomPanelGroup._addLineButton = Button(_bottomPanelGroup, UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_up.dds'),
            UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_down.dds'), UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_over.dds'),
            UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_dis.dds'))

        _bottomPanelGroup._addLineButton.OnClick = function(_addLineBtn, modifiers)
            local text = self._bottomPanelGroup._addEdit:GetText()
            if string.len(text) == 0 then
                return
            end
            table.insert(self._curLevel.data, {
                key = '',
                data = text,
                team = true
            })
            self:AcquireKeyboard()
            self._bottomPanelGroup._addEdit:ClearText()
            self._dataSize = self._dataSize + 1
            self:CalcVisible()
        end
        Tooltip.AddButtonTooltip(_bottomPanelGroup._addLineButton, 'add_line')

        LayoutHelpers.AtVerticalCenterIn(_bottomPanelGroup._addLineButton, _bottomPanelGroup)
        LayoutHelpers.AtLeftIn(_bottomPanelGroup._addLineButton, _bottomPanelGroup, 2)

        -- button for adding levels of tree
        _bottomPanelGroup._addLevelButton = Button(_bottomPanelGroup,
            UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_up.dds'), UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_down.dds'),
            UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_over.dds'), UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_dis.dds'))

        _bottomPanelGroup._addLevelButton.OnClick = function(_addLevelBtn, modifiers)
            local text = self._bottomPanelGroup._addEdit:GetText()
            if string.len(text) == 0 then
                return
            end
            table.insert(self._curLevel.data, {
                key = '',
                title = text,
                data = {}
            })
            self:AcquireKeyboard()
            self._bottomPanelGroup._addEdit:ClearText()
            self._dataSize = self._dataSize + 1
            self:CalcVisible()
        end
        Tooltip.AddButtonTooltip(_bottomPanelGroup._addLevelButton, 'add_tree')

        LayoutHelpers.AtVerticalCenterIn(_bottomPanelGroup._addLevelButton, _bottomPanelGroup)
        LayoutHelpers.AtRightIn(_bottomPanelGroup._addLevelButton, _bottomPanelGroup, 2)

        -- button for adding ping
        _bottomPanelGroup._addPingButton = Button(_bottomPanelGroup, UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_up.dds'),
            UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_down.dds'), UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_over.dds'),
            UIUtil.UIFile('/dialogs/zoom_btn/zoom_btn_dis.dds'))

        _bottomPanelGroup._addPingButton.OnClick = function(_addPingBtn, modifiers)
            local text = self._bottomPanelGroup._addEdit:GetText()
            if string.len(text) == 0 then
                return
            end
            table.insert(self._curLevel.data, {
                key = '',
                data = text,
                ping = true
            })
            self:AcquireKeyboard()
            self._bottomPanelGroup._addEdit:ClearText()
            self._dataSize = self._dataSize + 1
            self:CalcVisible()
        end
        Tooltip.AddButtonTooltip(_bottomPanelGroup._addPingButton, 'add_ping')

        LayoutHelpers.AtVerticalCenterIn(_bottomPanelGroup._addPingButton, _bottomPanelGroup)
        LayoutHelpers.LeftOf(_bottomPanelGroup._addPingButton, _bottomPanelGroup._addLevelButton, 10)

        LOG("edit init")
        _bottomPanelGroup._addEdit = Edit(_bottomPanelGroup)

        LayoutHelpers.AtTopIn(_bottomPanelGroup._addEdit, _bottomPanelGroup, 2)
        LayoutHelpers.AtBottomIn(_bottomPanelGroup._addEdit, _bottomPanelGroup, 2)

        _bottomPanelGroup._addEdit.OnEnterPressed = function(_addEdit, text)
            _bottomPanelGroup._addLineButton:OnClick()
        end

        -- LayoutHelpers.SetHeight(_bottomPanelGroup._addEdit, UIUtil.bodyFont + 2)
        LayoutHelpers.DepthOverParent(_bottomPanelGroup._addEdit, _bottomPanelGroup, 10)
        LayoutHelpers.AnchorToLeft(_bottomPanelGroup._addEdit, _bottomPanelGroup._addPingButton, 20)
        LayoutHelpers.AnchorToRight(_bottomPanelGroup._addEdit, _bottomPanelGroup._addLineButton, 20)
        LayoutHelpers.ResetWidth(_bottomPanelGroup._addEdit)
        -- LayoutHelpers.AtVerticalCenterIn(_bottomPanelGroup._addEdit, _bottomPanelGroup)
        UIUtil.SetupEditStd(_bottomPanelGroup._addEdit, "ff00ff00", 'ff000000', "ffffffff", UIUtil.highlightColor,
            UIUtil.bodyFont, 16, 200)
        _bottomPanelGroup._addEdit:SetDropShadow(true)
        _bottomPanelGroup._addEdit:ShowBackground(true)
        _bottomPanelGroup._addEdit:SetText('')
        return _bottomPanelGroup

    end,

    CreateBottomEdit = function(self, parent)
        local _addEdit = Edit(parent)

        -- _addEdit.OnEnterPressed = function(_edit, text)

        -- end
        -- TODO add some functionality

        return _addEdit
    end,

    GetScrollValues = function(self, axis)
        -- LOG( 1 ..' '.. self._dataSize..' '..self._topLine.. ' '.. math.min(self._topLine + self._numLines, self._dataSize))
        return 1, self._dataSize, self._topLine, math.min(self._topLine + self._numLines, self._dataSize)
    end,

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + delta)
    end,

    -- self._numLines determines how many lines in current render of ui
    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + math.floor(delta) * self._numLines)
    end,

    -- called when the scrollbar wants to set a new visible top line
    ScrollSetTop = function(self, axis, top)
        if top == self._topLine then
            return
        end
        self._topLine = math.max(math.min(self._dataSize - self._numLines + 1, top), 1)
        self:CalcVisible()
    end,

    ScrollToBottom = function(self)
        self:ScrollSetTop(nil, self._numLines)
    end,

    RenderLines = function(self)
        local index = 1
        if table.empty(self._lineGroup._lines) then
            self._lineGroup._lines[index] = BCLine(self._lineGroup, self, index, nil, true)
            self._dataSize = table.getn(self._curLevel.data)
        else
            local isFit = true
            for id, line in self._lineGroup._lines do
                if isFit then
                    if line.Bottom() > self._lineGroup.Bottom() then
                        isFit = false
                        line:Destroy()
                        self._numLines = id - 1
                        self._lineGroup._lines[id] = nil
                    end
                else
                    line:Destroy()
                    self._lineGroup._lines[id] = nil
                end
            end
            if isFit then
                index = self._numLines
            else
                return
            end
        end
        local parent = self._lineGroup._lines[index]
        while self._lineGroup.Bottom() - parent.Bottom() > 30 do
            index = index + 1
            self._lineGroup._lines[index] = BCLine(parent, self, index, nil, false)
            parent = self._lineGroup._lines[index]
        end
        self._numLines = index
        self:CalcVisible()
    end,
    -- determines what controls should be visible or not
    CalcVisible = function(self)
        local invIndex = 1
        local lineIndex = 1
        local dorender = false
        -- if we have more lines than we fitted in we try to add more
        if self._numLines > self._dataSize - self._topLine + 1 then
            self._topLine = math.max(self._dataSize - self._numLines, 1)
        end
        for id, lineData in self._curLevel.data do
            if invIndex == self._topLine then
                dorender = true
            end
            if dorender then
                self._lineGroup._lines[lineIndex]:RenderData(lineData, id)
                if self._numLines == lineIndex then
                    return
                end
                lineIndex = lineIndex + 1
            end
            invIndex = invIndex + 1
        end
        for ind = lineIndex, self._numLines do
            self._lineGroup._lines[ind]:RenderData()
        end
    end,

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    IsScrollable = function(self, axis)
        return not self._shadowMode
    end,

    -- scrolling
    OnMouseWheel = function(self, rotation)
        if self:IsScrollable() then
            if rotation > 0 then
                self:ScrollLines(nil, -1)
            else
                self:ScrollLines(nil, 1)
            end
        end
    end,
    -- when window is closed
    OnClose = function(self)
        self._curLevel = self._treeData
        self._route = {}
        self:SetShadowMode(false)
        self:CalcVisible()
        self:SaveData()
        self:AbandonKeyboard()
        self:Hide()
        self:SetNeedsFrameUpdate(false)
        if not IsDestroyed(self._ow) then
            self._ow:OnClose()
        end
    end,

    OnConfigClick = function(self)
        if IsDestroyed(self._ow) then
            if exists('/mods/UMT/modules/OptionsWindow.lua') then
                local OptionsWindow = import('/mods/UMT/modules/OptionsWindow.lua').OptionsWindow
                local OW = OptionsWindow(self:GetParent(), 'Better Chat options', 'bcoptions')
                OW:ExtendColorSet({'ffffffff', 'ffffff00', 'ff00ffff', 'ffff0000', 'ffff8000'})
                :AddTitle("Lines colors")
                :AddColor('Message text color', 'messageTextColor', BCLineModule.messageTextColor)
                :AddColor('Ping text color', 'pingTextColor', BCLineModule.pingTextColor)
                :AddColor('Tree text color', 'treeTextColor', BCLineModule.treeTextColor)
                :AddColor('On edit text color', 'editTextColor', BCLineModule.editTextColor)
                :AddSplitter()
                :AddTitle("Modifiers colors")
                :AddColor('Default key color', 'defaultKeyColor', BCLineModule.defaultKeyColor)
                :AddColor('Ctrl key color', 'ctrlKeyColor', BCLineModule.ctrlKeyColor)
                :AddColor('Shift key color', 'shiftKeyColor', BCLineModule.shiftKeyColor)
                :AddColor('Alt key color', 'altKeyColor', BCLineModule.altKeyColor)
                self._ow = OW
            else
                print("Better Chat requires UI mod tools for more options!!!")  
            end
        end
    end,

    OnDestroy = function(self)
        self:SaveData()
        Window.OnDestroy(self)
    end,
    SaveData = function(self)
        Prefs.SetToCurrentProfile("betterchat", self._treeData)
    end,

    OnMove = function(self, x, y, firstFrame)
    end,
    OnMoveSet = function(self)
        self:AcquireKeyboard()
    end,
    -- resize window event overload

    OnResize = function(self, x, y, firstFrame)
        self:RenderLines()
    end,

    OnResizeSet = function(self)
        LayoutHelpers.ResetWidth(self)
        LayoutHelpers.ResetHeight(self)
        self:SaveWindowLocation()
        self:RenderLines()
        self:AcquireKeyboard()
    end,

    GetShadowMode = function(self)
        return self._shadowMode
    end,

    SetShadowMode = function(self, state)
        self:SaveData()
        if state then
            self._shadowMode = true
            self:Hide()
            self._lineGroup:Show()
            self._lineGroup:SetAlpha(0.5)
            self._title:Show()
            self._title:SetAlpha(0.5)
            self.TitleGroup:DisableHitTest()
            self._lineGroup:ApplyFunction(function(control)
                if control._id then
                    control:SetShadowMode(true)
                end
            end)
            self._lineGroup:DisableHitTest()
        else
            self._shadowMode = false
            self:Show()
            self._title:SetAlpha(1)
            self._lineGroup:SetAlpha(1)
            self.TitleGroup:EnableHitTest()
            self._lineGroup:ApplyFunction(function(control)
                if control._id then
                    control:SetShadowMode(false)
                end
            end)
        end
    end
}
