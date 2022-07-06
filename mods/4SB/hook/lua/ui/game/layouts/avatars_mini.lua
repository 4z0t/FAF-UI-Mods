local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local oldSetLayout = SetLayout
function SetLayout()
    oldSetLayout()
    local controls = import('/lua/ui/game/avatars.lua').controls
    local scoreBoard = import('/lua/ui/game/score.lua').controls.scoreBoard
    if scoreBoard then
        LayoutHelpers.AtRightIn(controls.avatarGroup, controls.parent)
        LayoutHelpers.AnchorToBottom(controls.avatarGroup, scoreBoard, 10)
    end
end
