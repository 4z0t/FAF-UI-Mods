ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.LINQ >= 1.4.0",
    "ReUI.UI >= 1.4.0",
    "ReUI.UI.Color >= 1.0.0",
    "ReUI.UI.Animation >= 1.1.0",
    "ReUI.UI.Controls >= 1.0.0",
    "ReUI.UI.Views >= 1.2.0",
    "ReUI.UI.Views.Grid >= 1.1.0",
    "ReUI.Options >= 1.0.0",
    "ReUI.Units >= 1.0.0",
    "ReUI.Units.Enhancements >= 1.2.0",
    "ReUI.Construction >= 1.0.0",
}

function Main()
    local Templates        = import("/lua/ui/game/build_templates.lua")
    local FactoryTemplates = import("/lua/ui/templates_factory.lua")
    local CommandMode      = import("/lua/ui/game/commandmode.lua")
    local UIUtil           = import('/lua/ui/uiutil.lua')
    local Edit             = import("/lua/maui/edit.lua").Edit

    local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
    local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler


    local Enumerate = ReUI.LINQ.Enumerate
    local IPairsEnumerator = ReUI.LINQ.IPairsEnumerator
    local PairsEnumerator = ReUI.LINQ.PairsEnumerator


    local Bitmap   = ReUI.UI.Controls.Bitmap
    local Text     = ReUI.UI.Controls.Text
    local CheckBox = ReUI.UI.Controls.CheckBox
    local Group    = ReUI.UI.Controls.Group

    local ToSet = IPairsEnumerator:ToSet()
    local Contains = IPairsEnumerator:Contains()

    local FactoryTemplatePreview = import("FactoryTemplatePreview.lua").FactoryTemplatePreview
    local BuildTemplatePreview = import("BuildTemplatePreview.lua").BuildTemplatePreview

    local PREFIXES = {
        ["aeon"]     = { "ua", "xa", "da", "za" },
        ["uef"]      = { "ue", "xe", "de", "ze" },
        ["cybran"]   = { "ur", "xr", "dr", "zr" },
        ["seraphim"] = { "xs", "us", "ds", "zs" }
    }

    ---@param id string
    ---@param buildableUnits table<string, true>
    ---@return string|false
    local function ConvertToBuildable(id, buildableUnits)
        local suffix = string.sub(id, 3)
        local pref = string.sub(id, 1, 2)

        local i
        for faction, prefixes in pairs(PREFIXES) do
            i = Contains(prefixes, pref)
            if i then
                break
            end
        end
        if not i then
            return false
        end

        for faction, prefixes in pairs(PREFIXES) do
            local prefix = prefixes[i]
            local newId = prefix .. suffix
            if buildableUnits[newId] then
                return newId
            end
        end

        return false
    end

    ---@param template any
    ---@param buildableUnits any
    local function ConvertBuildTemplate(template, buildableUnits)
        template = table.deepcopy(template)
        local templateData = template.templateData
        for i = 3, table.getn(templateData) do
            local entry = templateData[i]
            local id = entry[1]
            entry[1] = ConvertToBuildable(id, buildableUnits)
        end
        template.icon = ConvertToBuildable(template.icon, buildableUnits) or ""
        return template
    end

    ---@param template any
    ---@param buildableUnits any
    ---@return boolean
    local function CanBuildTemplate(template, buildableUnits)
        local templateData = template.templateData
        for i = 3, table.getn(templateData) do
            local entry = templateData[i]
            local id = entry[1]
            if not ConvertToBuildable(id, buildableUnits) then
                return false
            end
        end
        return true
    end

    ---@param templates FactoryTemplateData[]
    ---@param buildable table<string, true>
    local function GetAvailableFactoryTemplates(templates, buildable)
        local availableTemplates = {}
        for i, template in ipairs(templates) do
            local valid = true
            for _, entry in ipairs(template.templateData) do
                if not buildable[entry.id] then
                    valid = false
                    break
                end
            end
            if valid then
                table.insert(availableTemplates, {
                    index = i,
                    template = template
                })
            end
        end
        return availableTemplates
    end

    ---@param data FactoryTemplateData
    local function IssueFactoryTemplate(data)
        for _, entry in ipairs(data.templateData) do
            IssueBlueprintCommand("UNITCOMMAND_BuildFactory", entry.id, entry.count)
        end
    end

    local options = ReUI.Options.Mods["ReUI.Construction.Templates"]

    local templateNameLength
    options.templateNameLength:Bind(function(opt)
        templateNameLength = opt()
    end)

    ---@class TemplateData
    ---@field template any
    ---@field index integer

    ---@class TemplateComponentBase : AItemComponent
    ---@field data TemplateData
    ---@field name ReUI.UI.Controls.Text
    local TemplateComponentBase = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self TemplateComponentBase
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
            self.name = ReUI.UI.Controls.Text(item)
            self.name:SetFont("Arial", 11)
            item.Layouter(self.name)
                :AnchorToBottom(item, -3)
                :AtHorizontalCenterIn(item)
                :Color(UIUtil.factionTextColor)
                :DropShadow(true)
                :Over(item, 10)
                :DisableHitTest()
                :Hide()
        end,

        ---Called when item is activated with this component event handling
        ---@param self TemplateComponentBase
        ---@param item ReUI.Construction.Grid.Item
        ---@param action TemplateData
        ---@param context ConstructionContext
        Enable = function(self, item, action, context)
            self.data = action
            local template = action.template
            local id = template.icon
            item:DisplayBPID(id)
            self.name:SetText(string.sub(template.name, 1, templateNameLength))
            self.name:Show()
        end,

        ---Called when item is changing event handler
        ---@param self TemplateComponentBase
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            self.name:Hide()
            item:ClearDisplay()
        end,

        ---Called when component is being destroyed
        ---@param self TemplateComponentBase
        Destroy = function(self)
            self.name:Destroy()
            self.name = nil
        end,
    }

    local function ClearBuildPreview()
        local preview = ReUI.UI.Global["BuildTemplatePreview"]
        if not IsDestroyed(preview) then
            preview:Destroy()
        end
        ReUI.UI.Global["BuildTemplatePreview"] = nil
    end

    local function ClearFactoryPreview()
        local preview = ReUI.UI.Global["FactoryTemplatePreview"]
        if not IsDestroyed(preview) then
            preview:Destroy()
        end
        ReUI.UI.Global["FactoryTemplatePreview"] = nil
    end

    ---@class BaseTemplateEditMenu : ReUI.UI.Controls.Group
    ---@field item ReUI.Construction.Grid.Item
    ---@field data TemplateData
    ---@field _title ReUI.UI.Controls.Text
    ---@field _edit Edit
    ---@field _deleteBtn  Button
    ---@field _closeBtn  Button
    local BaseTemplateEditMenu = ReUI.Core.Class(Group)
    {

        ---@param self BaseTemplateEditMenu
        __init = function(self, parent)
            Group.__init(self, parent)

            self.item = parent

            self._title = Text(self)

            self._edit = Edit(self)
            self._edit.OnEnterPressed = function(edit, text)
                self:OnNameChanged(text)
                return true
            end

            self._deleteBtn = UIUtil.CreateButtonStd(self, '/widgets02/small', '<LOC _Delete>', 16)
            self._deleteBtn.OnClick = function(btn, modifiers)
                self:OnDelete()
            end

            self._closeBtn = UIUtil.CreateButtonStd(self, '/widgets02/small', '<LOC _Close>', 16)
            self._closeBtn.OnClick = function(btn, modifiers)
                self:Close()
            end
        end,

        ---@param self BaseTemplateEditMenu
        ---@param layouter ReUI.UI.Layouter
        InitLayout = function(self, layouter)
            layouter(self)
                :AtCenterIn(self:GetRootFrame())
                :Width(200)
                :Height(150)
                :Depth(self:GetRootFrame():GetTopmostDepth() + 1)

            layouter(self._title)
                :AtTopIn(self, 10)
                :AtHorizontalCenterIn(self)
                :Color(UIUtil.factionTextColor)
            self._title:SetFont("Arial", 20)
            self._title:SetText("Edit menu")


            layouter(self._edit)
                :Height(function() return self._edit:GetFontHeight() end)
                :AtRightIn(self, 10)
                :AtLeftIn(self, 10)
                :AtTopIn(self, 35)
            UIUtil.SetupEditStd(self._edit, "ffffffff", nil, "ffaaffaa", UIUtil.highlightColor, UIUtil.bodyFont, 16, 200)
            self._edit:SetDropShadow(true)
            self._edit:ShowBackground(true)
            self._edit:SetText("")


            layouter(self._closeBtn)
                :AtBottomIn(self, 10)
                :AtHorizontalCenterIn(self)

            layouter(self._deleteBtn)
                :AnchorToTop(self._closeBtn, 10)
                :AtHorizontalCenterIn(self)

            UIUtil.SurroundWithNinePatch(self, "/game/chat_brd/", 4, 4)
        end,

        ---@param self BaseTemplateEditMenu
        ---@param data TemplateData
        SetData = function(self, data)
            self.data = data
            self._edit:SetText(self.data.template.name)
        end,

        HandleEvent = function(self, event)
            return true
        end,

        ---@param self BaseTemplateEditMenu
        ---@param name string
        OnNameChanged = function(self, name)
        end,

        ---@param self BaseTemplateEditMenu
        OnDelete = function(self)
        end,

        ---@param self BaseTemplateEditMenu
        Close = function(self)
            self:OnClose()
        end,

        ---@param self BaseTemplateEditMenu
        OnClose = function(self)
            self:Destroy()
        end,
    }


    ---@class BuildTemplateEditMenu : BaseTemplateEditMenu
    local BuildTemplateEditMenu = ReUI.Core.Class(BaseTemplateEditMenu)
    {
        ---@param self BuildTemplateEditMenu
        ---@param name string
        OnNameChanged = function(self, name)
            Templates.RenameTemplate(self.data.index, name)
            self.item:UpdatePanel()
        end,

        ---@param self BuildTemplateEditMenu
        OnDelete = function(self)
            Templates.RemoveTemplate(self.data.index)
            self.item:UpdatePanel()
            self:Close()
        end,
    }


    ---@class FactoryTemplateEditMenu : BaseTemplateEditMenu
    local FactoryTemplateEditMenu = ReUI.Core.Class(BaseTemplateEditMenu)
    {
        ---@param self FactoryTemplateEditMenu
        ---@param name string
        OnNameChanged = function(self, name)
            FactoryTemplates.RenameTemplate(self.data.index, name)
            self.item:UpdatePanel()
        end,

        ---@param self FactoryTemplateEditMenu
        OnDelete = function(self)
            FactoryTemplates.RemoveTemplate(self.data.index)
            self.item:UpdatePanel()
            self:Close()
        end,
    }


    ---@return BaseTemplateEditMenu
    local function CreateEditMenu(class, item)
        local menu = ReUI.UI.Global["ReUI.Construction.Templates.EditMenu"]
        if not IsDestroyed(menu) then
            menu:Destroy()
        end
        menu = class(item)
        ReUI.UI.Global["ReUI.Construction.Templates.EditMenu"] = menu
        return menu
    end

    local function CloseEditMenu()
        local menu = ReUI.UI.Global["ReUI.Construction.Templates.EditMenu"]
        if not IsDestroyed(menu) then
            menu:Destroy()
        end
        ReUI.UI.Global["ReUI.Construction.Templates.EditMenu"] = nil
    end

    ---@class BuildTemplatesHandler : ASelectionHandler
    local BuildTemplatesHandler = ReUI.Core.Class(ASelectionHandler)
    {
        Name = "BuildTemplatesHandler",

        ---@param self BuildTemplatesHandler
        ---@param panel ReUI.Construction.Panel
        OnInit = function(self, panel)
        end,

        ---@param self BuildTemplatesHandler
        ---@param context ConstructionContext
        ---@return string[]?
        Update = function(self, context)
            if context.tech ~= "BUILD_TEMPLATES" then
                CloseEditMenu()
                ClearBuildPreview()
                return
            end

            local selection = context.selection
            if table.empty(selection) then
                return
            end
            ---@cast selection -nil

            local isAllEngineers = table.empty(EntityCategoryFilterOut(categories.ENGINEER, selection))
            if not isAllEngineers then
                return
            end

            local _, _, builableCategories = GetUnitCommandData(selection)
            local buildableUnits = EntityCategoryGetUnitList(builableCategories)
            if table.empty(buildableUnits) then
                return
            end

            local templates = Templates.GetTemplates()
            if table.empty(templates) then
                return {}
            end

            local buildableSet = ToSet(buildableUnits)

            local items = {}
            for i, template in templates do
                if CanBuildTemplate(template, buildableSet) then
                    table.insert(items, {
                        index = i,
                        template = ConvertBuildTemplate(template, buildableSet)
                    })
                end
            end

            return items
        end,

        ---@param self BuildTemplatesHandler
        OnDestroy = function(self)
        end,

        ---@class BuildTemplateItem : TemplateComponentBase
        ---@field name ReUI.UI.Controls.Text
        ComponentClass = ReUI.Core.Class(TemplateComponentBase)
        {
            ---Called when grid item receives an event
            ---@param self BuildTemplateItem
            ---@param item ReUI.Construction.Grid.Item
            ---@param event KeyEvent
            HandleEvent = function(self, item, event)
                if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                    if event.Modifiers.Left then
                        ClearBuildTemplates()
                        local cmd = self.data.template.templateData[3][1]
                        CommandMode.StartCommandMode("build", { name = cmd })
                        SetActiveBuildTemplate(self.data.template.templateData)
                    elseif event.Modifiers.Right then
                        CreateEditMenu(BuildTemplateEditMenu, item)
                            :SetData(self.data)
                    end
                elseif event.Type == "MouseEnter" and options.previewBuildTemplates() then
                    self:CreatePreview(item)
                elseif event.Type == "MouseExit" then
                    self:ClearPreview()
                end
            end,

            ---@param self BuildTemplateItem
            ClearPreview = function(self)
                ClearBuildPreview()
            end,

            ---@param self BuildTemplateItem
            ---@param item ReUI.Construction.Grid.Item
            CreatePreview = function(self, item)
                self:ClearPreview()
                local preview = BuildTemplatePreview(item, self.data.template)
                ReUI.UI.Global["BuildTemplatePreview"] = preview
                preview:Layouter()
                    :AnchorToTop(item, 10)
                    :AtHorizontalCenterIn(item)
            end,
        },
    }

    ---@class FactoryTemplatesHandler : ASelectionHandler
    ---@field panel ReUI.Construction.Panel
    local FactoryTemplatesHandler = ReUI.Core.Class(ASelectionHandler)
    {
        Name = "FactoryTemplatesHandler",

        ---@param self FactoryTemplatesHandler
        ---@param panel ReUI.Construction.Panel
        OnInit = function(self, panel)
        end,

        ---@param self FactoryTemplatesHandler
        ---@param context ConstructionContext
        ---@return string[]?
        Update = function(self, context)
            if context.tech ~= "BUILD_TEMPLATES" then
                CloseEditMenu()
                ClearFactoryPreview()
                return
            end

            local selection = context.selection
            if table.empty(selection) then
                return
            end
            ---@cast selection -nil

            local isAllFactories = table.empty(EntityCategoryFilterOut(categories.FACTORY, selection))
            if not isAllFactories then
                return
            end

            local _, _, builableCategories = GetUnitCommandData(selection)
            local buildableUnits = EntityCategoryGetUnitList(builableCategories)
            if table.empty(buildableUnits) then
                return
            end

            local templates = FactoryTemplates.GetTemplates()
            if table.empty(templates) then
                return {}
            end

            local buildableSet = ToSet(buildableUnits)

            local availableTemplates = GetAvailableFactoryTemplates(templates, buildableSet)

            return availableTemplates
        end,

        ---@param self FactoryTemplatesHandler
        OnDestroy = function(self)
        end,

        ---@class FactoryTemplateItem : TemplateComponentBase
        ComponentClass = ReUI.Core.Class(TemplateComponentBase)
        {
            ---Called when grid item receives an event
            ---@param self FactoryTemplateItem
            ---@param item ReUI.Construction.Grid.Item
            ---@param event KeyEvent
            HandleEvent = function(self, item, event)
                if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                    if event.Modifiers.Left then
                        IssueFactoryTemplate(self.data.template)
                        PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
                    elseif event.Modifiers.Right then
                        CreateEditMenu(FactoryTemplateEditMenu, item)
                            :SetData(self.data)
                    end
                elseif event.Type == "MouseEnter" and options.previewFactoryTemplates() then
                    self:CreatePreview(item)
                elseif event.Type == "MouseExit" then
                    self:ClearPreview()
                end
            end,

            ---@param self FactoryTemplateItem
            ClearPreview = function(self)
                ClearFactoryPreview()
            end,

            ---@param self FactoryTemplateItem
            ---@param item ReUI.Construction.Grid.Item
            CreatePreview = function(self, item)
                self:ClearPreview()
                ---@type FactoryTemplatePreview
                local preview = FactoryTemplatePreview(item)
                preview:DisplayTemplate(self.data.template)
                ReUI.UI.Global["FactoryTemplatePreview"] = preview
                preview:Layouter()
                    :Above(item, 30)
            end,
        },
    }

    ---@class BuildTemplateBehavior
    local BuildTemplateBehavior = ReUI.Core.Class()
    {
        ---@param self BuildTemplateBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        OnAttach = function(self, checkBox)
            checkBox:SetNewTextures(
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_up.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_selected.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds')
            )

            checkBox:SetOverlayTextures(
                UIUtil.UIFile('/game/construct-sm_btn/template_off.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/template_on.dds')
            )
            checkBox:SetCheck(false, true)
        end,

        OnDetach = function(self, checkBox)
        end,

        ---@param self BuildTemplateBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        ---@param isChecked boolean
        OnChecked = function(self, checkBox, isChecked)
            Templates.CreateBuildTemplate()
            print "Build template created"
            checkBox:SetCheck(false, true)
        end,

        ---@param self BuildTemplateBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        OnUpdate = function(self, checkBox)
            local context = checkBox.Context
            local selection = context.selection

            if table.empty(selection) then
                checkBox:Disable()
                return
            end

            local isAllStructures = table.empty(EntityCategoryFilterOut(categories.STRUCTURE, selection))
            if not isAllStructures then
                checkBox:Disable()
                return
            end

            checkBox:Enable()
        end,
    }

    ---@class FactoryTemplateBehavior
    ---@field unit UserUnit?
    local FactoryTemplateBehavior = ReUI.Core.Class()
    {
        ---@param self FactoryTemplateBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        OnAttach = function(self, checkBox)
            checkBox:SetNewTextures(
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_up.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_selected.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds')
            )

            checkBox:SetOverlayTextures(
                UIUtil.UIFile('/game/construct-sm_btn/template_off.dds'),
                UIUtil.UIFile('/game/construct-sm_btn/template_on.dds')
            )
            checkBox:SetCheck(false, true)
        end,

        OnDetach = function(self, checkBox)
        end,

        ---@param self FactoryTemplateBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        ---@param isChecked boolean
        OnChecked = function(self, checkBox, isChecked)
            local unit = self.unit
            if not unit then
                return
            end

            ---@type UIBuildQueueItem[]
            local currentCommandQueue
            if EntityCategoryContains(categories.EXTERNALFACTORY, unit) then
                currentCommandQueue = SetCurrentFactoryForQueueDisplay(unit:GetCreator()--[[@as UserUnit]] )
            else
                currentCommandQueue = SetCurrentFactoryForQueueDisplay(unit)
            end

            FactoryTemplates.CreateBuildTemplate(currentCommandQueue)

            print "Factory template created"
            checkBox:SetCheck(false, true)
        end,

        ---@param self FactoryTemplateBehavior
        ---@param checkBox ReUI.Construction.ActionCheckBox
        OnUpdate = function(self, checkBox)
            checkBox:Disable()
            self.unit = nil

            local selection = checkBox.Context.selection
            if table.empty(selection) then
                return
            end
            ---@cast selection -nil
            if table.getn(selection) ~= 1 then
                return
            end

            local unit = selection[1]

            if not EntityCategoryContains(categories.FACTORY + categories.EXTERNALFACTORY, unit) then
                return
            end

            self.unit = unit
            checkBox:Enable()
        end,
    }

    ReUI.Construction.Panel.Actions["build_template"]   = BuildTemplateBehavior
    ReUI.Construction.Panel.Actions["factory_template"] = FactoryTemplateBehavior

    for _, handler in ReUI.Construction.Panel.PrimaryHandlers do
        if handler.tab == "selection" then
            handler.actions[1] = "build_template"
        end
    end

    table.insert(ReUI.Construction.Panel.TechTabs,
        {
            name = "BUILD_TEMPLATES",
            file = "/game/construct-tech_btn/template_btn_",
        })

    table.insert(ReUI.Construction.Panel.PrimaryHandlers,
        1,
        {
            name = "BuildTemplates",
            tab = "construction",
            displayMode = "grid",
            actions = { "repeatBuild", "pause" },
            handler = BuildTemplatesHandler,
        })

    table.insert(ReUI.Construction.Panel.PrimaryHandlers,
        1,
        {
            name = "FactoryTemplates",
            tab = "construction",
            displayMode = "grid",
            actions = { "factory_template", "pause" },
            handler = FactoryTemplatesHandler,
        })
end
