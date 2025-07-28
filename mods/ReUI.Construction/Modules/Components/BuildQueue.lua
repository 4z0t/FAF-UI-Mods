---@diagnostic disable-next-line:deprecated
local TableGetn = table.getn

local Dragger = import("/lua/maui/dragger.lua").Dragger

local Bitmap = ReUI.UI.Controls.Bitmap

local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

local ProgressBarExtension = import("ProgressBarExtension.lua").ProgressBarExtension

local EnhancementQueueFile = import("/lua/ui/notify/enhancementqueue.lua")
local UnitViewDetail = import("/lua/ui/game/unitviewdetail.lua")
local GetEnhancementTextures = import("/lua/ui/game/construction.lua").GetEnhancementTextures

local Enumerate = ReUI.LINQ.Enumerate

---@class EnhancementQueueItem
---@field name string
---@field id string

---@class EnhancementQueueData
---@field type "enhancement"
---@field showProgress boolean
---@field [1] number # id in queue
---@field [2] EnhancementQueueItem

---@class BuildQueueData
---@field type "unit"
---@field showProgress boolean
---@field [1] number # id in queue
---@field [2] UIBuildQueueItem

---@alias UnitQueueData BuildQueueData|EnhancementQueueData

---@class BuildQueueListContext
---@field unit UserUnit
local BuildQueueListContext = ReUI.Core.Class()
{
    ---@param self BuildQueueListContext
    Clear = function(self)
        self.unit = nil
        ClearCurrentFactoryForQueueDisplay()
    end
}

local BuildQueueToQueueData = ReUI.LINQ.IPairsEnumerator
    ---@param value UIBuildQueueItem
    :Where(function(value)
        return value.count > 0
    end)
    :Select(function(value, i)
        return { i, value, type = "unit" }
    end)
    :ToArray()

---@param unit UserUnit
---@return UnitQueueData[]?
local function ResolveQueueWithEnhancements(unit)

    local id = unit:GetEntityId()
    local enhancementQueue = EnhancementQueueFile.getEnhancementQueue()[id]

    if not enhancementQueue then
        return
    end

    local factoryQueue = SetCurrentFactoryForQueueDisplay(unit)
    local commandQueue = unit:GetCommandQueue()

    --!This algotithm (and overall enhancement queue) must be reworked because it relies on unsynced data and is unpredictable
    local scriptsInCommand = Enumerate(commandQueue)
        :Count(function(command)
            return command.type == "Script"
        end)

    if scriptsInCommand == 0 then
        EnhancementQueueFile.getEnhancementQueue()[id] = nil
        return
    end

    -- LOG("ENH")
    -- for _, enh in enhancementQueue do
    --     LOG(enh.ID)
    -- end
    -- LOG("queue")
    -- for _, command in commandQueue do
    --     LOG(command.type)
    -- end

    ---@type UnitQueueData[]
    local queue = {}
    local queueIndex = 1
    local bpId = nil
    local totalBuildCount = 0
    local unitBuildCount = 0
    local factoryIndex = 1
    local enhancementIndex = table.getn(enhancementQueue) - scriptsInCommand + 1

    ---@param command UICommandInfo
    for i, command in commandQueue do
        if command.type == "Script" then
            if unitBuildCount > 0 then
                queue[queueIndex] = {
                    type = "unit",
                    showProgress = factoryIndex == queueIndex,
                    factoryIndex,
                    {
                        id = bpId,
                        count = unitBuildCount
                    }
                }
                queueIndex = queueIndex + 1
                unitBuildCount = 0
                bpId = nil
            end
            local enhancementItem = enhancementQueue[enhancementIndex]
            enhancementIndex = enhancementIndex + 1
            if enhancementItem and not string.find(enhancementItem.ID, "Remove", 1, true) then
                queue[queueIndex] = {
                    type = "enhancement",
                    showProgress = queueIndex == 1,
                    queueIndex,
                    {
                        name = enhancementItem.ID,
                        id = enhancementItem.UnitID
                    }
                }
                queueIndex = queueIndex + 1
            end
        elseif command.type == "BuildMobile" then
            local item = factoryQueue[factoryIndex]
            local count = item.count

            totalBuildCount = totalBuildCount + 1
            unitBuildCount = unitBuildCount + 1
            bpId = item.id
            if count <= totalBuildCount then
                if bpId then
                    queue[queueIndex] = {
                        type = "unit",
                        showProgress = factoryIndex == queueIndex,
                        factoryIndex,
                        {
                            id = bpId,
                            count = unitBuildCount
                        }
                    }
                end
                queueIndex = queueIndex + 1
                totalBuildCount = 0
                unitBuildCount = 0
                bpId = nil
                factoryIndex = factoryIndex + 1
            end
        end
    end
    if bpId then
        queue[queueIndex] = {
            type = "unit",
            factoryIndex,
            {
                id = bpId,
                count = unitBuildCount
            }
        }
    end

    return queue
end

---@class BuildQueueHandler : ASelectionHandler
---@field _context BuildQueueListContext
BuildQueueHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "BuildQueue",

    ---@param self BuildQueueHandler
    OnInit = function(self)
        self._context = BuildQueueListContext()
    end,

    ---@param self BuildQueueHandler
    ---@param context ConstructionContext
    ---@return string[]?
    ---@return BuildQueueListContext?
    Update = function(self, context)
        local selection = context.selection
        local queueContext = self._context
        if table.empty(selection) then
            queueContext:Clear()
            return
        end
        ---@cast selection -nil

        if TableGetn(selection) ~= 1 then
            queueContext:Clear()
            return
        end

        local unit = selection[1]

        if not EntityCategoryContains(categories.SHOWQUEUE, unit) then
            queueContext:Clear()
            return
        end

        self._context.unit = unit

        local bp           = unit:GetBlueprint()
        local enhancements = bp.Enhancements
        if enhancements then
            local queue = ResolveQueueWithEnhancements(unit)
            if queue then
                return queue, queueContext
            end
        end

        ---@type UIBuildQueueItem[]
        local currentCommandQueue = SetCurrentFactoryForQueueDisplay(unit)

        if table.empty(currentCommandQueue) then
            -- ClearCurrentFactoryForQueueDisplay()
            return {}, queueContext
        end

        return BuildQueueToQueueData(currentCommandQueue), queueContext
    end,

    ---@param self BuildQueueHandler
    OnDestroy = function(self)
        self._context = nil
    end,

    ---@class BuildQueueItem : AItemComponent, ProgressBarExtension
    ---@field progress StatusBar
    ---@field data UnitQueueData
    ---@field context BuildQueueListContext
    ComponentClass = ReUI.Core.Class(AItemComponent, ProgressBarExtension)
    {
        ---Called when component is bond to an item
        ---@param self BuildQueueItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
        end,

        ---Called when grid item receives an event
        ---@param self BuildQueueItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            local modifiers = event.Modifiers

            local index = self.data[1]
            local count = 1
            if modifiers.Shift or modifiers.Ctrl then
                count = 5
            end

            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then

                if modifiers.Right then
                    if self.data.type == "unit" then
                        DecreaseBuildCountInQueue(index, count)
                        PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
                    elseif self.data.type == "enhancement" then
                        ---???
                    end

                end
            elseif event.Type == "MouseEnter" then
                if self.data.type == "unit" then
                    local id = self.data[2].id
                    UnitViewDetail.Show(__blueprints[id], nil, id)
                elseif self.data.type == "enhancement" then
                end
            elseif event.Type == "MouseExit" then
                UnitViewDetail.Hide()
            end
        end,

        ---@param self BuildQueueItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param delta number
        OnFrame = function(self, item, delta)
            local context = self.context
            local unit = context.unit

            self:UpdateProgressBar(unit)
        end,

        ---Called when item is activated with this component event handling
        ---@param self BuildQueueItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param action UnitQueueData
        ---@param context BuildQueueListContext
        Enable = function(self, item, action, context)
            self.context = context
            self.data = action
            local index = self.data[1]

            if index == 1 and action.showProgress then
                self:ShowProgressBar(item)
            end

            if action.type == "unit" then
                local id = action[2].id
                local count = action[2].count
                item:DisplayBPID(id)
                if count > 1 then
                    item.Text = count
                end
            elseif action.type == "enhancement" then
                local id = action[2].id
                local name = action[2].name
                local up, down, over, _, sel = GetEnhancementTextures(id, __blueprints[id].Enhancements[name].Icon)
                item.BackGround = up
            end
        end,

        ---Called when item is changing event handler
        ---@param self BuildQueueItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            self:HideProgressBar(item)
            item:ClearDisplay()
        end,

        ---Called when component is being destroyed
        ---@param self BuildQueueItem
        Destroy = function(self)
            self:DestroyProgressBar()
            self.context = nil
        end,
    },
}
