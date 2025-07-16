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
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local Json = import("/lua/system/dkson.lua").json
local Tooltip = import('/lua/ui/game/tooltip.lua')
local CWEntry = import('/mods/ChatWheel/modules/CWEntry.lua').CWEntry
local CWAdd = import('/mods/ChatWheel/modules/CWAdd.lua').CWAdd
-- TODO tree system
--[[
    data:
    {
        {
            text=...,
            all = true|false
        },
        {...}
    }
]]

TEAM_COLOR = 'ff00ffff'
ALL_COLOR = 'ffffffff'
RADIUS = 300

CWheel = Class(Bitmap) {
    __init = function(self, parent)
        Bitmap.__init(self, parent)
        LayoutHelpers.FillParent(self, parent)
        LayoutHelpers.ResetWidth(self)
        LayoutHelpers.ResetHeight(self)
        self.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
        self:SetAlpha(0.3)
        self:SetSolidColor('ff000000')
        self.MouseX = nil
        self.MouseY = nil
        self._curEntry = nil
        self._prevEntry = nil
        self:LoadData()
        self:InitEntries()
        self:SetNeedsFrameUpdate(true)
        self:AcquireKeyboardFocus(false)
    end,

    LoadData = function(self)
        self._data = Prefs.GetFromCurrentProfile('chatwheel') or {{
            text = 'Press Enter to add new Phrase',
            all = true
        }, {
            text = 'Press Backspace to remove Phrase',
            all = true
        }, {
            text = 'Press Esc to close chat wheel or right click',
            all = true
        }, {
            text = 'Left click to send message with phrase',
            all = true
        }}
        -- (function()
        --     local t = {}
        --     local c = 1000
        --     for i = 1, 143 do
        --         table.insert(t, {
        --             text = c .. '-7',
        --             all = true
        --         })
        --         c = c - 7
        --     end
        --     return t
        -- end)()
    end,

    SaveData = function(self)
        Prefs.SetToCurrentProfile("chatwheel", self._data)
    end,

    AddData = function(self, data)
        table.insert(self._data, data)
        self:ClearEntries()
        self:InitEntries()
    end,
    RemoveData = function(self)
        table.remove(self._data, self._curEntry)
        self:ClearEntries()
        self:InitEntries()
    end,
    GetCenter = function(self)
        return self.Width() / 2 + self.Left(), self.Height() / 2 + self.Top()

    end,

    InitAddButton = function(self)

    end,

    InitEntries = function(self)
        self._entries = {}
        local degree = 0
        local dataSize = table.getn(self._data)
        local angleStep = 360 / dataSize
        for id, data in self._data do
            self._entries[id] = CWEntry(self, data.text, 'Arial', nil, data.all and ALL_COLOR or TEAM_COLOR)
            local entry = self._entries[id]
            local pos = {
                x = RADIUS * math.cos(math.rad(degree)),
                y = RADIUS * math.sin(math.rad(degree))
            }
            entry:SetVector(pos.x, pos.y)
            LayoutHelpers.AtCenterIn(entry, self, pos.y, pos.x)
            degree = degree + angleStep
        end
    end,
    ClearEntries = function(self)
        for id, entry in self._entries do
            entry:Destroy()
        end
        self._entries = {}
        self._curEntry = nil
        self._prevEntry = nil
    end,

    SendMessage = function(self, id)
        if id ~= nil then
            local msg = {
                Chat = true,
                text = self._data[id].text
            }
            if self._data[id].all then
                msg.to = 'all'
            else
                msg.to = 'allies'
            end
            SessionSendChatMessage(FindClients(), msg)
        end
    end,

    OnFrame = function(self, delta)
        if self.MouseX == nil or self.MouseY == nil then
            return
        end
        self._curEntry = self:CalcNearest()
        if self._curEntry ~= self._prevEntry then
            self._entries[self._curEntry]:SetInc(true)
            self._entries[self._curEntry]:SetFamily('Arial Black')
            if self._prevEntry then
                self._entries[self._prevEntry]:SetInc(false)
                self._entries[self._prevEntry]:SetFamily('Arial')
            end
            self._prevEntry = self._curEntry
        end
    end,

    CalcNearest = function(self)
        local centerX, centerY = self:GetCenter()
        local mouseVecX, mouseVecY = self.MouseX - centerX, self.MouseY - centerY
        local angle = -RADIUS * RADIUS
        local target = nil
        for id, entry in self._entries do
            local x, y = entry:GetVector()
            local dotP = x * mouseVecX + y * mouseVecY
            if dotP > angle then
                angle = dotP
                target = id
            end
        end
        return target
    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseMotion' then
            self.MouseX = event.MouseX
            self.MouseY = event.MouseY
        elseif event.Type == 'ButtonPress' then
            if event.Modifiers.Left then
                self:SendMessage(self._curEntry)
            end
            self:OnClose()
        elseif event.Type == 'KeyDown' then
            self:HandleKeyBoardInput(event)
        end

    end,
    HandleKeyBoardInput = function(self, event)
        if event.KeyCode == UIUtil.VK_ESCAPE then -- close chat wheel
            self:OnClose()
        elseif event.KeyCode == UIUtil.VK_ENTER then -- add phrase
            CWAdd(self, self)
        elseif event.KeyCode == UIUtil.VK_BACKSPACE then -- delete phrase
            self:RemoveData()
        end
    end,

    OnOpen = function(self)
        self:Enable()
        self:Show()
        self:AcquireKeyboardFocus(false)
    end,

    OnClose = function(self)
        self:SaveData()
        self:Hide()
        self:Disable()
        self:AbandonKeyboardFocus()
    end

}
