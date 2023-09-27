local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local BorderedText = import("BorderedText.lua").BorderedText
local LazyVar = import('/lua/lazyvar.lua').Create
local Text = import("/lua/maui/text.lua").Text
local Dragger = import("/lua/maui/dragger.lua").Dragger



BorderedButton = Class(BorderedText)
{
    __init = function(self, parent, normal, active, highlight, disabled, clickCue, rolloverCue, borderWidth)
        BorderedText.__init(self, parent, normal, borderWidth)

        self._normal = normal
        self._active = active
        self._highlight = highlight
        self._disabled = disabled

        self._clickCue = clickCue
        self._rolloverCue = rolloverCue
    end,

    SetNewColors = function(self, normal, active, highlight, disabled)
        self._normal = normal
        self._active = active
        self._highlight = highlight
        self._disabled = disabled
    end,

    ApplyColors = function(self)
        if self._isDisabled and self._disabled then
            self:SetColor(self._disabled)
        elseif self._normal then
            self:SetColor(self._normal)
        end
    end,

    OnDisable = function(self)
        self:ApplyColors()
    end,

    OnEnable = function(self)
        self:ApplyColors()
    end,

    HandleEvent = function(self, event)
        if self._isDisabled then return true end
        

        if event.Type == 'MouseEnter' then
            if self._dragger then
                self:SetColor(self._active)
                self:OnRolloverEvent('enter')
            else
                self:SetColor(self._highlight)
                self:OnRolloverEvent('enter')
                if self._rolloverCue then
                    PlaySound(Sound { Cue = self._rolloverCue, Bank = "Interface" })
                end
            end
            self._mouseOver = true
            return true
        elseif event.Type == 'MouseExit' then
            self:SetColor(self._normal)
            self:OnRolloverEvent('exit')
            self._mouseOver = false
            return true
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            local dragger = Dragger()
            dragger.OnRelease = function(dragger, x, y)
                dragger:Destroy()
                self._dragger = nil
                if self._mouseOver then
                    self:SetTexture(self._highlight)
                    self:OnRolloverEvent('exit')
                    self:OnClick(event.Modifiers)
                end
            end
            dragger.OnCancel = function(dragger)
                if self._mouseOver then
                    self:SetColor(self._highlight)
                end
                dragger:Destroy()
                self._dragger = nil
            end
            self._dragger = dragger
            if self._clickCue then
                PlaySound(Sound { Cue = self._clickCue, Bank = "Interface", })
            end
            self:SetColor(self._active)
            self:OnRolloverEvent('down')
            PostDragger(self:GetRootFrame(), event.KeyCode, dragger)
            return true
        end

        return false
    end,

    OnRolloverEvent = function(self, state) end,

    OnClick = function(self, modifiers) end
}
