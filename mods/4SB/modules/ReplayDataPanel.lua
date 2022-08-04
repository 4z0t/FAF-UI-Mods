local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local ExpandableSelectionGroup = import("Views/ExpandableSelectionGroup.lua").ExpandableSelectionGroup
local ExpandableGroup = import("Views/ExpandableGroup.lua").ExpandableGroup
local LayoutFor = LayoutHelpers.ReusedLayoutFor
local AnimatedBorderedCheckBox = import("Views/BorderedCheckBox.lua").AnimatedBorderedCheckBox


local textFont = "Zeroes Three"
local textSize = 12


local panelWidth = 300
local panelHeight = 20
local checkboxWidth = 18
local checkboxHeight = 18

local bgColor = "ff000000"

local Chechbox = Class(AnimatedBorderedCheckBox)
{
    -- OnHide = function(self, hidden)
    --     if not hidden then
    --         local dropdown = self:GetParent()
    --         if not dropdown._isExpanded and self ~= dropdown._active then
    --             self:Hide()
    --         end
    --     end
    -- end
}

local CheckboxDropDown = Class(ExpandableSelectionGroup)
{
    __init = function(self, parent, width, height)
        ExpandableSelectionGroup.__init(self, parent, width, height)
        self._bg = Bitmap(self)
        LayoutFor(self._bg)
            :Color(bgColor)
            :Alpha(0.4)
            :Fill(self._expand)
            :Top(self.Bottom)
    end,

    AddControls = function(self, controls)
        ExpandableGroup.AddControls(self, controls)


        local function CheckBoxOnClick(control, modifiers)
            local dropdown = control:GetParent()
            local datePanel = dropdown:GetParent()
            if modifiers.Left then
                if dropdown._isExpanded then
                    dropdown:SetActiveControl(control._id)
                    datePanel:UpdateDataSetup(dropdown._id, control._id + 1)
                    dropdown:Contract()
                else
                    dropdown:Expand()
                end
            elseif modifiers.Right and control == dropdown._active then
                control:ToggleCheck()
                if control._checkState == "checked" then
                    datePanel._sb:Expand(dropdown._id)
                else
                    datePanel._sb:Contract(dropdown._id)
                end
            end
        end


        self._active._id = 0
        self._active.OnClick = CheckBoxOnClick
        self._active:SetAlpha(1)

        for i, control in self._controls do
            control._id = i
            control.OnClick = CheckBoxOnClick
            control:SetAlpha(0)
        end
    end,
}

local checkboxes = import("DataPanelConfig.lua").checkboxes



DataPanel = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self._sb = parent
        self._bg = Bitmap(self)
        self._setup = {}
        self._dropdowns = {}
        for i, category in checkboxes do
            local dropdown = CheckboxDropDown(self, panelHeight, panelHeight)
            dropdown._id = i
            table.insert(self._dropdowns, dropdown)
            table.insert(self._setup, 1)
        end
    end,

    __post_init = function(self)
        self:_Layout()
        self:_SetupCheckBoxes()
        self._sb:SetDataSetup(self._setup)
    end,

    _Layout = function(self)

        LayoutFor(self._bg)
            :Fill(self)
            :Color(bgColor)
            :Alpha(0.4)
            :DisableHitTest()



        LayoutFor(self)
            :Width(panelWidth)
            :Height(panelHeight)

        for i, dropdown in self._dropdowns do
            if i == table.getn(self._dropdowns) then

                LayoutFor(dropdown)
                    :AtVerticalCenterIn(self)
                    :AtRightIn(self, 20)

            else
                LayoutFor(dropdown)
                    :AtVerticalCenterIn(self)
                    :LeftOf(self._dropdowns[i + 1], 20)
            end
        end
    end,

    _SetupCheckBoxes = function(self)

        for i, dropdown in self._dropdowns do
            local cbs = {}
            for j, checkboxData in checkboxes[i] do
                local checkbox = Chechbox(
                    dropdown,
                    checkboxData.nu,
                    checkboxData.nc,
                    checkboxData.ou,
                    checkboxData.oc,
                    checkboxData.du,
                    checkboxData.dc,
                    nil,
                    nil,
                    1
                )
                LayoutFor(checkbox)
                    :Width(checkboxWidth)
                    :Height(checkboxHeight)
                checkbox:SetText(checkboxData.text)
                checkbox:SetFont("Zeroes Three", 12)
                checkbox:SetCheck(true)
                cbs[j] = checkbox
            end
            dropdown:AddControls(cbs)


        end
    end,

    UpdateDataSetup = function(self, category, id)
        self._setup[category] = id
        self._sb:SetDataSetup(self._setup)
    end




}
