local Bitmap = ReUI.UI.Controls.Bitmap

local _Button = import('/lua/maui/button.lua').Button


---@class ReUI.UI.Views.Button : ReUI.UI.Controls.Bitmap
---@field mNormal FileName
---@field mActive FileName
---@field mHighlight FileName
---@field mDisabled FileName
---@field mMouseOver boolean
---@field mClickCue string
---@field mRolloverCue string
---@field mDragger? Dragger
Button = ReUI.Core.Class(Bitmap)
{
    ---@param self ReUI.UI.Views.Button
    ---@param parent Control
    ---@param normal FileName
    ---@param active FileName
    ---@param highlight FileName
    ---@param disabled FileName
    ---@param clickCue FileName
    ---@param rolloverCue any
    ---@param frameRate any
    __init = function(self, parent, normal, active, highlight, disabled, clickCue, rolloverCue, frameRate)
        Bitmap.__init(self, parent, normal)
        self.mNormal = normal
        self.mActive = active
        self.mHighlight = highlight
        self.mDisabled = disabled
        self.mMouseOver = false
        self.mClickCue = clickCue
        self.mRolloverCue = rolloverCue
        if frameRate then
            self:SetFrameRate(frameRate)
        end
        self:SetLoopPingPongPattern()
        self:Loop(true)
    end,

    ---@type fun(self: ReUI.UI.Views.Button, normal: FileName, active: FileName, highlight: FileName, disabled: FileName)
    SetNewTextures = _Button.SetNewTextures,

    ---@type fun(self: ReUI.UI.Views.Button)
    ApplyTextures = _Button.ApplyTextures,

    ---@type fun(self: ReUI.UI.Views.Button)
    OnDisable = _Button.OnDisable,

    ---@param self ReUI.UI.Views.Button
    ---@param state "enter"|"exit"|"down"
    OnRolloverEvent = function(self, state)
    end,

    ---@type fun(self: ReUI.UI.Views.Button)
    OnEnable = _Button.OnEnable,

    HandleEvent = _Button.HandleEvent,

    ---@param self  ReUI.UI.Views.Button
    OnClick = function(self, modifiers) end
}
