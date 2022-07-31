local Group = import('/lua/maui/group.lua').Group
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutFor = import("/lua/maui/layouthelpers.lua").ReusedLayoutFor

local Entry = import("Views/Entry.lua").Entry
local ExpandableGroup = import("Views/ExpandableGroup.lua").ExpandableGroup
local ExpandableSelectionGroup = import("Views/ExpandableSelectionGroup.lua").ExpandableSelectionGroup

local Animator = import("Animations/Animator.lua")
local AnimationFactory = import("Animations/AnimationFactory.lua")
local SequentialAnimation = import("Animations/SequentialAnimation.lua").SequentialAnimation
local Utils = import("Utils.lua")

local ScoreBoard = import("ScoreBoard.lua").ScoreBoard


local BorderedCheckBox = import("Views/BorderedCheckBox.lua").BorderedCheckBox


local controls

local slideBackWards = AnimationFactory.GetAnimationFactory()
    :OnStart()
    :OnFrame(function(control, delta)
        if control.Right() - control.parent.Right() > 50 then
            return true
        end
        control.Right:Set(control.Right() + delta * 500)
    end)
    :OnFinish(function(control)
        LayoutHelpers.AtRightIn(control, control.parent, -50)
    end)
    :Create()

local colors = {
    "ff" .. "FF0000",
    "ff" .. "FF7F00",
    "ff" .. "FFFF00",
    "ff" .. "00FF00",
    "ff" .. "0000FF",
    "ff" .. "4B0082",
    "ff" .. "9400D3",
}

function Main(isReplay)
    local parent = GetFrame(0)
    controls = Group(parent)
    controls.Depth:Set(1000)
    LayoutHelpers.SetDimensions(controls, 200, 220)
    LayoutHelpers.AtLeftTopIn(controls, parent, 200, 200)
    controls.entries = {}
    for i = 1, 7 do
        controls.entries[i] = Entry(controls)

        controls.entries[i]._bg:SetSolidColor(colors[i])

        if i == 1 then

            LayoutHelpers.AtRightTopIn(controls.entries[i], controls)

        else
            LayoutHelpers.AnchorToBottom(controls.entries[i], controls.entries[i - 1], 2)
            LayoutHelpers.AtRightIn(controls.entries[i], controls)
        end
    end
    local sa = SequentialAnimation(slideBackWards, 0.1, 1)
    sa:Apply(controls.entries)

    local eg = ExpandableSelectionGroup(parent, 200, 40)
    eg._bg = Bitmap(eg)
    eg._bg:SetSolidColor("77000000")
    LayoutHelpers.FillParent(eg._bg, eg._expand)
    LayoutHelpers.AtLeftTopIn(eg, parent, 600, 200)
    eg:AddControls((function()
        local t = {}
        for i = 1, 10 do
            table.insert(t, UIUtil.CreateText(eg, "text " .. i, 16))
        end
        return t
    end)()
    -- {
    --     UIUtil.CreateText(eg, "text 1", 16),
    --     UIUtil.CreateText(eg, "text 2", 16),
    --     UIUtil.CreateText(eg, "text 3", 16)
    --}
    )
    --eg:EnableHitTest()
    -- eg.HandleEvent = function(self, event)
    --     if event.Type == 'ButtonPress' then
    --         if self._isExpanded then
    --             self:Contract()
    --         else
    --             self:Expand()
    --         end
    --     end
    -- end
    eg.Depth:Set(1000)


    Utils.GetArmiesFormattedTable()

    local function RGBA(color)
        if string.len(color) == 9 then -- #rrggbbaa -- > aarrggbb
            return string.sub(color, 8) .. string.sub(color, 2, 7)
        elseif string.len(color) == 7 then -- #rrggbb -- > rrggbb
            return 'ff' .. string.sub(color, 2)
        else
            return -- no color
        end
    end

    local normalEnergyColor = RGBA '#f7c70f'
    local overEnergyColor = RGBA "#faf202"



    local normalUncheckedColor = RGBA "#3f3f3f"
    local overUncheckedColor = RGBA "#555555"

    local cb = BorderedCheckBox(parent,
        normalUncheckedColor,
        normalEnergyColor,
        overUncheckedColor,
        overEnergyColor,nil, nil, nil, nil, 2)
    cb:SetText("Test")
    cb:SetFont(UIUtil.bodyFont, 16)
    LayoutFor(cb)
        :AtLeftTopIn(parent, 600, 400)
        :Width(50)
        :Height(20)
    cb:SetCheck(true)
    cb.Depth:Set(1100)
end
