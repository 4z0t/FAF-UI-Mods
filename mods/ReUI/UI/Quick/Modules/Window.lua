local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Group = import('/lua/maui/group.lua').Group
local Button = import("/lua/maui/button.lua").Button

local LayoutFor = ReUI.UI.FloorLayoutFor
local WindowFrame = ReUI.UI.Views.WindowFrame
local OptionRef = ReUI.Options.OptionRef

local QuickContainer = import("Container.lua").QuickContainer

local GRIP_SIZE = 14
local TITLE_BAR_HEIGHT = 24

local closeButton = {
    up   = UIUtil.SkinnableFile('/game/menu-btns/close_btn_up.dds'),
    down = UIUtil.SkinnableFile('/game/menu-btns/close_btn_down.dds'),
    over = UIUtil.SkinnableFile('/game/menu-btns/close_btn_over.dds'),
    dis  = UIUtil.SkinnableFile('/game/menu-btns/close_btn_dis.dds'),
}

---@class Quick.Border : ReUI.UI.Views.WindowFrame
local Border = ReUI.Core.Class(WindowFrame)
{
    Textures = {
        tl = UIUtil.SkinnableFile("/game/mini-map-brd/mini-map_brd_ul.dds"),
        tr = UIUtil.SkinnableFile("/game/mini-map-brd/mini-map_brd_ur.dds"),
        tm = UIUtil.SkinnableFile("/game/mini-map-brd/mini-map_brd_horz_um.dds"),
        ml = UIUtil.SkinnableFile("/game/mini-map-brd/mini-map_brd_vert_l.dds"),
        m  = UIUtil.SkinnableFile("/game/mini-map-brd/mini-map_brd_m.dds"),
        mr = UIUtil.SkinnableFile("/game/mini-map-brd/mini-map_brd_vert_r.dds"),
        bl = UIUtil.SkinnableFile("/game/mini-map-brd/mini-map_brd_ll.dds"),
        bm = UIUtil.SkinnableFile("/game/mini-map-brd/mini-map_brd_lm.dds"),
        br = UIUtil.SkinnableFile("/game/mini-map-brd/mini-map_brd_lr.dds"),
    },
}

---@param name string
---@return string
local function FormatName(name)
    return (name:gsub("[^A-Za-z0-9]+", "_"))
end

---@class Quick.Window : Group
---@field _frame Quick.Border
---@field _titleBar Group
---@field _title Text
---@field _closeBtn Button
---@field _content Group
---@field _resizeGrip Bitmap
---@field _padding number
---@field _minWidth number
---@field _minHeight number
---@field _position ReUI.Options.OptionRef
---@field _fn fun(q: Quick.Container)
QuickWindow = Class(Group)
{
    ---@param self Quick.Window
    ---@param title string
    ---@param fn fun(q: Quick.Container)
    __init = function(self, title, fn)
        local f = GetFrame(0) --[[@as Frame]]
        Group.__init(self, f)

        self._padding = 8
        self._minWidth = 0
        self._minHeight = 0
        self._fn = fn

        self._position = OptionRef { "Quick.Windows", FormatName(title) }

        self._frame      = Border(self)
        self._titleBar   = Group(self)
        self._title      = UIUtil.CreateText(self._titleBar, title, 14, UIUtil.titleFont)
        self._closeBtn   = Button(self._titleBar,
            closeButton.up,
            closeButton.down,
            closeButton.over,
            closeButton.dis)
        self._resizeGrip = Bitmap(self)

        self:SetupLayout()
        self:Rebuild()
        self:SetupInteractions()
    end,

    ---@param self Quick.Window
    Rebuild = function(self)
        if IsDestroyed(self._content) then
            self._content = Group(self)
        else
            self._content:ClearChildren()
        end

        local w, h = QuickContainer(self._content):Build(self._fn)
        self._minWidth = w + self._padding * 2
        self._minHeight = h + self._padding + TITLE_BAR_HEIGHT

        LayoutFor(self._content)
            :Below(self._titleBar)
            :AtLeftIn(self, self._padding)
            :AtRightIn(self, self._padding)
            :AtBottomIn(self, self._padding)

        LayoutFor(self)
            :Width(self._minWidth)
            :Height(self._minHeight)
    end,


    ---@param self Quick.Window
    SetupLayout = function(self)
        LayoutFor(self._frame)
            :OffsetIn(self, -5, -1, -5, -5)
            :Under(self)
            :DisableHitTest(true)

        LayoutFor(self._titleBar)
            :AtLeftTopIn(self)
            :AtRightIn(self)
            :Height(TITLE_BAR_HEIGHT)
            :Over(self)

        LayoutFor(self._title)
            :AtLeftIn(self._titleBar, 8)
            :AtVerticalCenterIn(self._titleBar, 2)
            :DisableHitTest()

        LayoutFor(self._closeBtn)
            :AtRightIn(self._titleBar, 4)
            :AtVerticalCenterIn(self._titleBar)

        LayoutFor(self._resizeGrip)
            :AtRightBottomIn(self)
            :Width(GRIP_SIZE)
            :Height(GRIP_SIZE)
            :Color("30ffffff")
            :Over(self, 100)

        local pos = self._position:Get { 400, 100 }

        local frame = self:GetRootFrame()
        LayoutFor(self)
            :Left(pos[1])
            :Top(pos[2])
            :Width(400)
            :Height(300)
            :Over(frame, frame:GetTopmostDepth() + 1)

    end,

    ---@param self Quick.Window
    SetupInteractions = function(self)
        self._titleBar.HandleEvent = function(bar, event)
            if event.Type == "ButtonPress" then
                local drag = Dragger()
                local offX = event.MouseX - self.Left()
                local offY = event.MouseY - self.Top()
                drag.OnMove = function(d, x, y)
                    LayoutFor(self):Left(x - offX):Top(y - offY)
                end
                drag.OnRelease = function(d, x, y)
                    self._position:Set { x - offX, y - offY }
                    d:Destroy()
                end
                PostDragger(self:GetRootFrame(), event.KeyCode, drag)
                return true
            end
            return false
        end

        self._closeBtn.OnClick = function(control, modifiers)
            self:Destroy()
        end

        self._resizeGrip.HandleEvent = function(grip, event)
            if event.Type == "MouseEnter" then
                LayoutFor(grip):Color("60ffffff")
            elseif event.Type == "MouseExit" then
                LayoutFor(grip):Color("30ffffff")
            elseif event.Type == "ButtonPress" then
                local startW = self.Width()
                local startH = self.Height()
                local mx, my = event.MouseX, event.MouseY
                local drag = Dragger()
                drag.OnMove = function(d, x, y)
                    local newW = LayoutFor:UnscaleNumber(startW + (x - mx))
                    local newH = LayoutFor:UnscaleNumber(startH + (y - my))
                    if newW >= self._minWidth then
                        LayoutFor(self):Width(newW)
                    end
                    if newH >= self._minHeight then
                        LayoutFor(self):Height(newH)
                    end
                end
                drag.OnRelease = function(d, x, y)
                    LayoutFor(grip):Color("30ffffff")
                    d:Destroy()
                end
                PostDragger(self:GetRootFrame(), event.KeyCode, drag)
                return true
            end
            return false
        end
    end,
}
