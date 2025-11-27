ReUI.Require
{
    "ReUI.LINQ >= 1.4.0",
    "ReUI.UI.Views.Grid >= 1.0.0",
    "ReUI.ActionsPanel >= 1.1.0",
    "ReUI.Units.Enhancements >= 1.1.0",
}

function Main(isReplay)
    local ipairs = ipairs
    local EntityCategoryContains = EntityCategoryContains
    local GetSelectedUnits = GetSelectedUnits
    local TableEmpty = table.empty

    local UIUtil = import("/lua/ui/uiutil.lua")
    local FactoryTemplates = import("/lua/ui/templates_factory.lua")
    local factoryCategory = categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT

    local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler
    local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent

    local ToSet = ReUI.LINQ.PairsEnumerator
        :AsSet()
        :ToTable()

    ---@class TemplateData
    ---@field id UnitId
    ---@field count number

    ---@class FactoryTemplateData
    ---@field templateID number
    ---@field key number
    ---@field name string
    ---@field icon string
    ---@field templateData TemplateData[]

    local function SetRepeatQueue()
        local selection = GetSelectedUnits()
        if not selection then return end

        for _, unit in selection do
            unit:ProcessInfo('SetRepeatQueue', "true")
            if EntityCategoryContains(factoryCategory, unit) then
                unit:GetCreator():ProcessInfo('SetRepeatQueue', "true")
            end
        end
    end

    ---@param data FactoryTemplateData
    local function IssueFactoryTemplate(data)
        for _, entry in ipairs(data.templateData) do
            IssueBlueprintCommand("UNITCOMMAND_BuildFactory", entry.id, entry.count)
        end
    end

    ---@param templates FactoryTemplateData[]
    ---@param buildable string[]
    local function GetAvailableTemplates(templates, buildable)
        local availableTemplates = {}
        buildable = ToSet(buildable) --[[@as table<string, true>]]
        for _, template in ipairs(templates) do
            local valid = true
            for _, entry in ipairs(template.templateData) do
                if not buildable[entry.id] then
                    valid = false
                    break
                end
            end
            if valid then
                table.insert(availableTemplates, template)
            end
        end
        return availableTemplates
    end

    ---@class FactoryTemplatesHandler : ASelectionHandler
    local FactoryTemplatesHandler = Class(ASelectionHandler)
    {
        Name = "Factory Templates",
        Description = "Extension provides factory templates",
        Enabled = true,
        ---@param self FactoryTemplatesHandler
        ---@param selection UserUnit[]
        ---@return EnhancementIconInfo[]?
        Update = function(self, selection)
            if TableEmpty(selection) then
                return
            end
            if TableEmpty(EntityCategoryFilterDown(categories.FACTORY, selection)) then
                return
            end
            ---@type FactoryTemplateData[]?
            local allFactoryTemplates = FactoryTemplates.GetTemplates()

            if not allFactoryTemplates or TableEmpty(allFactoryTemplates) then
                return
            end

            local _, _, buildableCategories = GetUnitCommandData(selection)
            local buildable = EntityCategoryGetUnitList(buildableCategories)
            local availableTemplates = GetAvailableTemplates(allFactoryTemplates, buildable)

            return availableTemplates
        end,

        ---@class FTHComponent : AItemComponent
        ---@field data FactoryTemplateData
        ---@field bg ReUI.UI.Controls.Bitmap
        ---@field name ReUI.UI.Controls.Text
        ComponentClass = Class(AItemComponent)
        {
            ---Called when component is bond to an item
            ---@param self FTHComponent
            ---@param item BaseGridItem
            Create = function(self, item)
                self.bg = ReUI.UI.Controls.Bitmap(item)
                item.Layouter(self.bg)
                    :Fill(item)
                    :DisableHitTest()
                    :Hide()

                self.name = ReUI.UI.Controls.Text(item)
                self.name:SetFont("Arial", 12)
                item.Layouter(self.name)
                    :AtBottomCenterIn(item)
                    :Color("C3E600")
                    :DropShadow(true)
                    :DisableHitTest()
                    :Hide()
            end,

            ---Called when grid item receives an event
            ---@param self FTHComponent
            ---@param item BaseGridItem
            ---@param event KeyEvent
            HandleEvent = function(self, item, event)
                if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                    if event.Modifiers.Right then
                        SetRepeatQueue()
                    end
                    IssueFactoryTemplate(self.data)
                    PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
                end
            end,

            ---Called when item is activated with this component event handling
            ---@param self FTHComponent
            ---@param item BaseGridItem
            ---@param action FactoryTemplateData
            Enable = function(self, item, action)
                self.bg:Show()
                self.name:Show()
                self.data = action
                self.bg:SetTexture(UIUtil.UIFile('/icons/units/' .. self.data.icon .. '_icon.dds'--[[@as FileName]] ,
                    true))
                self.name:SetText(self.data.name)
            end,

            ---Called when item is changing event handler
            ---@param self FTHComponent
            ---@param item BaseGridItem
            Disable = function(self, item)
                self.bg:Hide()
                self.name:Hide()
            end,

            ---Called when component is being destroyed
            ---@param self FTHComponent
            Destroy = function(self)
                self.bg:Destroy()
                self.bg = nil
                self.name:Destroy()
                self.name = nil
            end,
        },
    }

    ReUI.ActionsPanel.AddExtension("FactoryTemplates", FactoryTemplatesHandler)
end
