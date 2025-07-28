local TableGetn = table.getn

local Dragger = import("/lua/maui/dragger.lua").Dragger

local Bitmap = ReUI.UI.Controls.Bitmap

local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

local ProgressBarExtension = import("ProgressBarExtension.lua").ProgressBarExtension

local Enumerate = ReUI.LINQ.Enumerate

---@class QueueData
---@field [1] number # id in queue
---@field [2] UIBuildQueueItem # number of units


---@class QueueListContext
---@field lock boolean
---@field dragging boolean
---@field modified boolean
---@field startIndex number
---@field index number
---@field count number
---@field unit UserUnit?
---@field queue UIBuildQueueItem[]?
---@field oldQueue UIBuildQueueItem[]?
---@field dragger Dragger
local QueueListContext = ReUI.Core.Class()
{
    ---@param self QueueListContext
    __init = function(self)
        self.dragging = false
        self.index = 0
        self.startIndex = 0
        self.count = 0
        self.modified = false
        self.dragger = Dragger()
        self.dragger.OnRelease = function(dragger, x, y)
            self.dragging = false
            if self.modified then
                self:UpdateQueue()
            else
                IncreaseBuildCountInQueue(self.startIndex, self.count)
            end
            PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
        end
        self.dragger.OnCancel = function(dragger)
            self.dragging = false
        end
    end,

    ---@param self QueueListContext
    Reset = function(self)
        self.index = 0
        self.dragging = false
        self.unit = nil
        self.queue = nil
        self.oldQueue = nil
        self.modified = false
        self.lock = false
    end,

    ---@param self QueueListContext
    Clear = function(self)
        self.unit = nil
        ClearCurrentFactoryForQueueDisplay()
    end,

    ---@param self QueueListContext
    StartDrag = function(self, index)
        self.dragging = true
        self.index = index
        self.startIndex = index

        self.oldQueue = table.copy(self.queue)
    end,

    ---@param self QueueListContext
    ---@param indexTo number
    DragTo = function(self, indexTo)
        if self.queue == nil or self.oldQueue == nil or self.lock then
            return
        end
        self.modified = true

        local indexFrom = self.index
        local queue = self.queue
        ---@cast queue -nil


        local moveditem = queue[indexFrom]
        if indexFrom < indexTo then
            for i = indexFrom, (indexTo - 1) do
                queue[i] = queue[i + 1]
            end
        elseif indexFrom > indexTo then
            for i = indexFrom, (indexTo + 1), -1 do
                queue[i] = queue[i - 1]
            end
        end
        queue[indexTo] = moveditem

        self.index = indexTo
    end,

    ---@param self QueueListContext
    UpdateQueue = function(self)
        local oldQueue = self.oldQueue
        local from = math.min(self.index, self.startIndex)
        local newQueue = self.queue
        local unit = self.unit

        ---@cast unit -nil
        ---@cast newQueue -nil
        ---@cast oldQueue -nil

        self:Reset()

        for i = TableGetn(oldQueue), from, -1 do
            DecreaseBuildCountInQueue(i, oldQueue[i].count)
        end

        ---@type UserUnit[]?
        local externalFactory
        if EntityCategoryContains(categories.EXTERNALFACTORY, unit) then
            local creator = unit:GetCreator()
            if creator then
                externalFactory = { creator }
            end
        end

        for i = from, TableGetn(newQueue) do
            local id = newQueue[i].id
            local blueprint = __blueprints[id]
            if blueprint.General.UpgradesFrom and blueprint.General.UpgradesFrom ~= 'none' then
                IssueBlueprintCommand("UNITCOMMAND_Upgrade", id, 1, false)
            elseif externalFactory then
                IssueBlueprintCommandToUnits(externalFactory, "UNITCOMMAND_BuildFactory", id, newQueue[i].count)
            else
                IssueBlueprintCommand("UNITCOMMAND_BuildFactory", id, newQueue[i].count)
            end
        end
        self.lock = true
        ForkThread(self.DragLock, self)
    end,

    DragLock = function(self)
        WaitSeconds(0.5)
        self.lock = false
    end,
}

local BuildQueueToQueueData = ReUI.LINQ.IPairsEnumerator
    ---@param value UIBuildQueueItem
    :Where(function(value)
        return value.count > 0
    end)
    :Select(function(value, i)
        return { i, value }
    end)
    :ToArray()

---@class QueueListHandler : ASelectionHandler
---@field _context QueueListContext
QueueListHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "Queue",

    ---@param self QueueListHandler
    OnInit = function(self)
        self._context = QueueListContext()
    end,

    ---@param self QueueListHandler
    ---@param context ConstructionContext
    ---@return string[]?
    ---@return QueueListContext?
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

        if queueContext.unit == unit and queueContext.dragging then
            return BuildQueueToQueueData(queueContext.queue), queueContext
        end
        queueContext:Reset()

        if not EntityCategoryContains(categories.FACTORY + categories.EXTERNALFACTORY, unit) then
            queueContext:Clear()
            return
        end

        ---@type UIBuildQueueItem[]
        local currentCommandQueue
        if EntityCategoryContains(categories.EXTERNALFACTORY, unit) then
            currentCommandQueue = SetCurrentFactoryForQueueDisplay(unit:GetCreator())
        else
            currentCommandQueue = SetCurrentFactoryForQueueDisplay(unit)
        end

        if not currentCommandQueue then
            -- ClearCurrentFactoryForQueueDisplay()
            return {}
        end

        queueContext.unit = unit
        queueContext.queue = currentCommandQueue

        return BuildQueueToQueueData(currentCommandQueue), queueContext
    end,

    ---@param self QueueListHandler
    OnDestroy = function(self)
        self._context:Reset()
        self._context = nil
    end,

    ---@class QueueListItem : AItemComponent, ProgressBarExtension
    ---@field dragMarker ReUI.UI.Controls.Bitmap
    ---@field progress StatusBar
    ---@field data QueueData
    ---@field context QueueListContext
    ComponentClass = ReUI.Core.Class(AItemComponent, ProgressBarExtension)
    {
        ---Called when component is bond to an item
        ---@param self QueueListItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
            self.dragMarker = Bitmap(item, '/textures/ui/queuedragger.dds')
            item.Layouter(self.dragMarker)
                :Fill(item)
                :DisableHitTest()
                :Over(item, 10)
                :Hide()
        end,

        ---Called when grid item receives an event
        ---@param self QueueListItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            local modifiers = event.Modifiers
            local context = self.context

            local index = self.data[1]
            local count = 1
            if modifiers.Shift or modifiers.Ctrl then
                count = 5
            end

            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                if modifiers.Left then
                    context.count = count
                    context:StartDrag(index)
                    self.dragMarker:Show()
                    PostDragger(item:GetRootFrame(), event.KeyCode, context.dragger)
                elseif modifiers.Right then
                    DecreaseBuildCountInQueue(index, count)
                    PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
                end
            elseif event.Type == 'MouseEnter' then
                if context.dragging then
                    context:DragTo(index)
                    item:UpdatePanel()
                end
            end
        end,

        ---@param self QueueListItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param delta number
        OnFrame = function(self, item, delta)
            local context = self.context
            local unit = context.unit
            self:UpdateProgressBar(unit)
        end,

        ---Called when item is activated with this component event handling
        ---@param self QueueListItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param context QueueListContext
        ---@param action QueueData
        Enable = function(self, item, action, context)
            self.context = context
            self.data = action

            local index = self.data[1]
            if index == 1 then
                self:ShowProgressBar(item)
            end

            if index == self.context.index then
                self.dragMarker:Show()
            else
                self.dragMarker:Hide()
            end

            local id = self.data[2].id
            item:DisplayBPID(id)
            local count = self.data[2].count
            if count > 1 then
                item.Text = count
            end
        end,

        ---Called when item is changing event handler
        ---@param self QueueListItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            self:HideProgressBar(item)
            self.dragMarker:Hide()
            item:ClearDisplay()
        end,

        ---Called when component is being destroyed
        ---@param self QueueListItem
        Destroy = function(self)
            self:DestroyProgressBar()
            self.dragMarker:Destroy()
            self.dragMarker = nil
        end,
    },
}
