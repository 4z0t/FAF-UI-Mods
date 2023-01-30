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

MAX_TEXT_SIZE = LayoutHelpers.ScaleNumber(30)
MIN_TEXT_SIZE = LayoutHelpers.ScaleNumber(20)
RESIZE_TICK = 0.01

CWEntry = Class(Text) {
    __init = function(self, parent, text, font, pointSize, color)
        Text.__init(self, parent)
        self:SetFont(font, pointSize or MIN_TEXT_SIZE)
        self:SetColor(color)
        self:SetText(text)
        self:DisableHitTest()
        self:SetDropShadow(true)
        self:SetNeedsFrameUpdate(true)
        self._timer = 0
        self._inc = false
        self._x = 0
        self._y = 0
    end,
    SetVector = function(self, x, y)
        self._x = x
        self._y = y
        --self._vec = Vector(x, y, 0)
        -- local vlen = VDist2(x, y, 0, 0)
        -- self._vec = VMult(self._vec, 1 / vlen)
    end,
    GetVector = function(self)
        return self._x, self._y
    end,

    SetInc = function(self, state)
        self._inc = state
    end,

    OnFrame = function(self, delta)
        -- self._timer = self._timer + delta
        -- if self._timer > RESIZE_TICK then
        --     local pointSize = self._font._pointsize()
        --     local family = self._font._family()
        --     if self._inc then
        --         if pointSize ~= MAX_TEXT_SIZE then
        --             self._font._pointsize:Set(pointSize + 1)
        --         end
        --     else
        --         if pointSize ~= MIN_TEXT_SIZE then
        --             self._font._pointsize:Set(pointSize - 1)
        --         end
        --     end
        --     self._timer = 0
        -- end
    end,
    SetFamily = function(self, family)
        self._font._family:Set(family)
    end

}
