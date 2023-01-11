local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local EscapeHandler = import('/lua/ui/dialogs/eschandler.lua')


---@class EscapeCover : Bitmap
EscapeCover = Class(Bitmap)
{

    __init = function(self, parent)
        Bitmap.__init(self, parent)


        local frame = parent:GetRootFrame()
        LayoutHelpers.FillParent(self, frame)
        self.Depth:Set(frame:GetTopmostDepth() + 10)

        self:SetSolidColor('78000000')

        self._poped = false

        EscapeHandler.PushEscapeHandler(function()
            self:OnEscapePressed()
        end)
    end,


    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            self:OnShadowClicked()
        end
    end,


    Close = function(self)
        EscapeHandler.PopEscapeHandler()
        self._poped = true
        self:OnClose()
    end,

    OnEscapePressed = function(self)
        self:Close()
    end,


    OnShadowClicked = function(self)
        self:Close()
    end,

    OnDestroy = function(self)
        if self._poped then return end
        EscapeHandler.PopEscapeHandler()
    end,

    OnClose = function(self)

    end,
}
