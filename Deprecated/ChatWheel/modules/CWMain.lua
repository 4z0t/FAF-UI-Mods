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
local CWheel = import("/mods/ChatWheel/modules/CWheel.lua").CWheel

DEBUG = false
local chatWheel = nil
local is_replay

function init(isReplay)
    is_replay = isReplay
    if not isReplay then
        chatWheel = CWheel(import('/lua/ui/game/worldview.lua').viewLeft)
        chatWheel:OnClose()
    end
end

function call()
    if is_replay then
        return
    end
    if chatWheel and not IsDestroyed(chatWheel) then
        chatWheel:OnOpen()
    else
        chatWheel = CWheel(import('/lua/ui/game/worldview.lua').viewLeft)
        chatWheel:OnClose()
    end
end

