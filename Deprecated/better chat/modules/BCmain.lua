local Dragger = import('/lua/maui/dragger.lua').Dragger
local Prefs = import('/lua/user/prefs.lua')
local Window = import('/lua/maui/window.lua').Window
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Edit = import('/lua/maui/edit.lua').Edit
local Text = import('/lua/maui/text.lua').Text
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local BCWindow = import("BCwindow.lua").BCWindow

DEBUG = false
local bcwin = nil
local isReplay = import('/lua/ui/game/gamemain.lua').GetReplayState()
function call()
    if isReplay then
        return
    end
    if DEBUG then
        if bcwin then
            bcwin:Destroy()
            LOG('new window')
        end
        bcwin = BCWindow(GetFrame(0))
    elseif IsDestroyed(bcwin) then
        bcwin = BCWindow(GetFrame(0))
    elseif bcwin:IsHidden() and not bcwin:GetShadowMode() then
        bcwin:Show()
        bcwin:AcquireKeyboard()
    else
        bcwin:AcquireKeyboard()
    end
end

function OnClick()
    if IsDestroyed(bcwin) then
        return
    else
        bcwin:AbandonKeyboard()
    end
end

