local ipairs = ipairs
local EntityCategoryContains = EntityCategoryContains
local GetSelectedUnits = GetSelectedUnits

local ISelectionHandler = import("/mods/AGP/modules/ISelectionHandler.lua").ISelectionHandler
local IItemComponent = import("/mods/AGP/modules/IItemComponent.lua").IItemComponent
local UIUtil = import("/lua/ui/uiutil.lua")
local FactoryTemplates = import("/lua/ui/templates_factory.lua")
local factoryCategory = categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT

local LuaQ = UMT.LuaQ

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
    ---@type table<string, true>
    buildable = buildable | LuaQ.toSet
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

---@class FactoryTemplatesHandler : ISelectionHandler
FactoryTemplatesHandler = Class(ISelectionHandler)
{
    Name = "Factory Templates",
    Description = "Extension provides factory templates",
    Enabled = true,
    ---@param self FactoryTemplatesHandler
    ---@param selection UserUnit[]
    ---@return EnhancementIconInfo[]?
    OnSelectionChanged = function(self, selection)
        if table.empty(selection) then
            return
        end
        if table.empty(EntityCategoryFilterDown(categories.FACTORY, selection)) then
            return
        end
        ---@type FactoryTemplateData[]?
        local allFactoryTemplates = FactoryTemplates.GetTemplates()

        if not allFactoryTemplates or table.empty(allFactoryTemplates) then
            return
        end

        local _, _, buildableCategories = GetUnitCommandData(selection)
        local buildable = EntityCategoryGetUnitList(buildableCategories)
        local availableTemplates = GetAvailableTemplates(allFactoryTemplates, buildable)

        return availableTemplates
    end,

    ---@class FTHComponent : IItemComponent
    ---@field data FactoryTemplateData
    ---@field bg UMT.Bitmap
    ---@field name UMT.Text
    ComponentClass = Class(IItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self FTHComponent
        ---@param item Item
        Create = function(self, item)
            self.bg = UMT.Controls.Bitmap(item)
            item.Layouter(self.bg)
                :Fill(item)
                :DisableHitTest()
                :Hide()

            self.name = UMT.Controls.Text(item)
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
        ---@param item Item
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
        ---@param item Item
        Enable = function(self, item)
            self.bg:Show()
            self.name:Show()
        end,

        ---@param self FTHComponent
        ---@param action FactoryTemplateData
        SetAction = function(self, action)
            self.data = action
            self.bg:SetTexture(UIUtil.UIFile('/icons/units/' .. self.data.icon .. '_icon.dds', true))
            self.name:SetText(self.data.name)
        end,

        ---Called when item is changing event handler
        ---@param self FTHComponent
        ---@param item Item
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
