ReUI.Require
{
    "ReUI.Core >= 1.3.0",
    "ReUI.UI >= 1.4.0",
    "ReUI.WorldView >= 1.0.0",
    "ReUI.Options >= 1.0.0"
}


local GetWorldViews = import("/lua/ui/game/worldview.lua").GetWorldViews
local function RefreshReclaim()
    ---@param view ReUI.WorldView.WorldView
    for _, view in GetWorldViews() do
        local reclaimComponent = view:GetComponent("Reclaim") --[[@as WVReclaimComponent]]
        if reclaimComponent then
            reclaimComponent:Refresh()
        end
    end
end

local Reclaim = import('/lua/ui/game/reclaim.lua')

Reclaim.OnCommandGraphShow = function(bool)
end

---@type table<EntityId, UIReclaimDataPoint>
local insidePlayableAreaReclaim = {}
---@type table<EntityId, UIReclaimDataPoint>
local outsidePlayableAreaReclaim = {}

local mapWidth = 0
local mapHeight = 0
---@type number[]?
local playableArea

---@param minX number
---@param minY number
---@param maxX number
---@param maxY number
local function ContainsWholeMap(minX, minY, maxX, maxY)
    if playableArea then
        return minX < playableArea[1] and
            maxX > playableArea[3] and
            minY < playableArea[2] and
            maxY > playableArea[4]
    else
        return minX < 0 and
            maxX > mapWidth and
            minY < 0 and
            maxY > mapHeight
    end
end

local function InPlayableArea(pos)
    if playableArea then
        return pos[1] > playableArea[1]
            and pos[1] < playableArea[3]
            and pos[3] > playableArea[2]
            and pos[3] < playableArea[4]
    end
    return true
end

Reclaim.SetPlayableArea = function(rect)
    playableArea = rect

    local inside = {}
    local outside = {}
    for _, reclaimList in { insidePlayableAreaReclaim, outsidePlayableAreaReclaim } do
        for id, r in reclaimList do
            if InPlayableArea(r.position) then
                inside[id] = r
            else
                outside[id] = r
            end
        end
    end
    insidePlayableAreaReclaim = inside
    outsidePlayableAreaReclaim = outside

    RefreshReclaim()
end

AddOnSyncHashedCallback(function(reclaimPoints)
    if table.empty(reclaimPoints) then
        return
    end

    for id, reclaimPoint in reclaimPoints do
        if not reclaimPoint then
            insidePlayableAreaReclaim[id]  = nil
            outsidePlayableAreaReclaim[id] = nil
        elseif InPlayableArea(reclaimPoint.position) then
            insidePlayableAreaReclaim[id] = reclaimPoint
            outsidePlayableAreaReclaim[id] = nil
        else
            insidePlayableAreaReclaim[id] = nil
            outsidePlayableAreaReclaim[id] = reclaimPoint
        end
    end
    RefreshReclaim()
end, "Reclaim", "ReUI.Reclaim")

function Main(isReplay)
    local IsKeyDown = IsKeyDown

    local MathMax = math.max
    local MathMin = math.min
    local UnProject = UnProject
    local TableSort = table.sort

    local GetCommandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode
    local LazyVar = import('/lua/lazyvar.lua').Create
    local UIUtil = import('/lua/ui/uiutil.lua')
    local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
    local Group = import('/lua/maui/group.lua').Group

    local LayoutFor = ReUI.UI.FloorLayoutFor


    ---@param totalMass number
    ---@param maxMass number
    ---@return string?
    ---@return integer?
    local function ComputeLabelPropertiesBatched(totalMass, maxMass)
        if totalMass <= 10 then return nil, nil end
        if maxMass < 100 then return 'ffc7ff8f', 10 end
        if maxMass < 300 then return 'ffd7ff05', 12 end
        if maxMass < 600 then return 'ffffeb23', 17 end
        if maxMass < 1000 then return 'ffff9d23', 20 end
        if maxMass < 2000 then return 'ffff7212', 22 end
        return 'fffb0303', 25
    end

    ---@class ReclaimLabel : Group
    ---@field massValue LazyVar
    ---@field mass Bitmap
    ---@field text Text
    local ReclaimLabel = Class(Group)
    {
        ---@param self ReclaimLabel
        __init = function(self, parent)
            Group.__init(self, parent)
            self.massValue = LazyVar(0)

            self.mass = Bitmap(self)
            self.text = UIUtil.CreateText(self, "", 10, UIUtil.bodyFont, true)

            LayoutFor(self.mass)
                :Width(10)
                :Height(10)
                :AtCenterIn(self)
                :Texture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))

            LayoutFor(self.text)
                :Above(self, 2)
                :AtHorizontalCenterIn(self)

            LayoutFor(self)
                :Left(0)
                :Top(0)
                :Width(10)
                :Height(10)
                :Over(self:GetParent(), self.massValue)
                :DisableHitTest(true)
        end,

        ---@param self ReclaimLabel
        AdjustToValue = function(self, total, max)
            local color, size = ComputeLabelPropertiesBatched(total, max or total)
            if color then
                self.text:SetFont(UIUtil.bodyFont, size) -- r.mass > 2000
                self.text:SetColor(color)
                self.text:Show()
            else
                self.text:Hide()
            end
        end,

        ---@param self ReclaimLabel
        ---@param pos Vector2
        PositionOnScreen = function(self, pos)
            self.Left:SetValue(pos[1] - 0.5 * self.Width())
            self.Top:SetValue(pos[2] - 0.5 * self.Height() + 1)
        end,

        ---@param self ReclaimLabel
        DisplayReclaim = function(self, r)
            if self:IsHidden() then
                self:Show()
            end

            if r.mass ~= self.massValue() then
                local mass = tostring(math.floor(0.5 + r.mass))
                self.text:SetText(mass)
                self.massValue:Set(r.mass)
            end
            self:AdjustToValue(r.mass, r.max)
        end,
    }


    local options = ReUI.Options.Mods["ReUI.Reclaim"]

    ---@type number
    local heightRatio
    options.heightRatio:Bind(function(var)
        heightRatio = var() / 1000
    end)

    ---@type number
    local zoomThreshold
    options.zoomThreshold:Bind(function(var)
        zoomThreshold = var()
    end)

    ---@type number
    local maxLabels
    options.maxLabels:Bind(function(var)
        maxLabels = var()
    end)

    ---@type boolean
    local useBatching
    options.useBatching:Bind(function(var)
        useBatching = var()
    end)

    ---@type number
    local updateRate
    options.updateRate:Bind(function(var)
        updateRate = var() / 1000
    end)

    ---@param a UIReclaimDataPoint
    ---@param b UIReclaimDataPoint
    ---@return boolean
    local function CompareMass(a, b)
        return a.mass > b.mass
    end

    --- Combines the reclaim by summing them up together, averages position based on mass value
    ---@param r1 UIReclaimDataCombined
    ---@param r2 UIReclaimDataPoint|UIReclaimDataCombined
    ---@return UIReclaimDataCombined
    local function SumReclaim(r1, r2)
        local massSum = r1.mass + r2.mass
        r1.count = r1.count + (r2.count or 1)
        r1.position[1] = (r1.mass * r1.position[1] + r2.mass * r2.position[1]) / massSum
        r1.position[3] = (r1.mass * r1.position[3] + r2.mass * r2.position[3]) / massSum
        r1.max = MathMax(r1.max or r1.mass, r2.mass)
        r1.mass = massSum
        return r1
    end

    mapWidth = SessionGetScenarioInfo().size[1]
    mapHeight = SessionGetScenarioInfo().size[2]

    ---@param component WVReclaimComponent
    ---@param reclaim UIReclaimDataPoint[]
    ---@return number
    local function _CopyReclaim(component, reclaim)
        local reclaimDataPool = component._reclaimData
        local index = 0
        for _, r in reclaim do
            index = index + 1
            local rp = reclaimDataPool[index]
            if rp then
                rp.mass = r.mass
                rp.max = rp.mass
                rp.position[1] = r.position[1]
                rp.position[2] = r.position[2]
                rp.position[3] = r.position[3]
                rp.count = 1
            else
                reclaimDataPool[index] = {
                    position = { r.position[1], r.position[2], r.position[3] },
                    mass = r.mass,
                    count = 1
                }
            end
        end
        component._usedReclaimData = index
        component._totalReclaimData = MathMax(index, component._totalReclaimData)
        for i = index + 1, component._totalReclaimData do
            reclaimDataPool[i].mass = 0
        end
        return index
    end

    ---@param component WVReclaimComponent
    ---@param reclaim UIReclaimDataPoint[]
    ---@return number?         # Returns the number of labels, nil if the zoom threshold is
    local function _CombineReclaim(component, reclaim)
        local zoom = component.worldView:GetCamera():SaveSettings().Zoom

        if zoom < zoomThreshold then
            return
        end
        local reclaimDataPool = component._reclaimData
        local totalReclaimData = component._totalReclaimData

        local minDist = zoom * heightRatio
        local minDistSq = minDist * minDist
        local index = 0

        for _, r in reclaim do
            local added = false
            local x1 = r.position[1]
            local y1 = r.position[3]

            for i = 1, index do
                local cr = reclaimDataPool[i]
                local x2 = cr.position[1]
                local y2 = cr.position[3]
                local dx = x1 - x2
                local dy = y1 - y2
                if dx * dx + dy * dy < minDistSq then
                    added = true
                    SumReclaim(cr, r)
                    break
                end
            end

            if not added then
                index = index + 1
                if index > totalReclaimData then
                    reclaimDataPool[index] = {
                        mass = r.mass,
                        position = { 0, 0, 0 },
                        count = 1
                    }
                    totalReclaimData = totalReclaimData + 1
                end
                local rd = reclaimDataPool[index]
                rd.mass = r.mass
                rd.max = r.mass
                rd.count = 1
                local v = rd.position
                v[1] = x1
                v[2] = r.position[2]
                v[3] = y1
            end
        end

        for i = index + 1, totalReclaimData do
            reclaimDataPool[i].mass = 0
        end

        component._totalReclaimData = MathMax(index, totalReclaimData)
        component._usedReclaimData = index

        return index
    end

    ---@class WVReclaimComponent : ReUI.WorldView.Component
    ---@field _updateTimer number
    ---@field _enabledWithReclaimMode boolean
    ---@field _previewState boolean
    ---@field _showingReclaim boolean
    ---@field _forceRefresh boolean
    ---@field _prevZoom number
    ---@field _prevPosition Vector
    ---@field _reclaimData UIReclaimDataCombined[]
    ---@field _usedReclaimData number
    ---@field _totalReclaimData number
    ---@field _labels ReclaimLabel[]
    ---@field _reclaimGroup ReUI.UI.Controls.Group
    local WVReclaimComponent = ReUI.Core.Class(ReUI.WorldView.Component)
    {
        ---@param self WVReclaimComponent
        OnInit = function(self)
            self._updateTimer = 0

            self._enabledWithReclaimMode = false
            self._showingReclaim = false
            self._previewState = false
            self._prevPosition = {}
            self._prevZoom = 0
            self._forceRefresh = false

            self._reclaimData = {}
            self._totalReclaimData = 0
            self._usedReclaimData = 0

            self._labels = {}
            self._reclaimGroup = Group(self.worldView)
            LayoutFor(self._reclaimGroup)
                :DisableHitTest()
                :Fill(self.worldView)
        end,

        ---@param self WVReclaimComponent
        ---@return boolean
        CheckNeedRefresh = function(self)
            local camera = self.worldView:GetCamera()
            local prevPos = self._prevPosition
            local zoom = camera:GetZoom()
            local position = camera:GetFocusPosition()

            if self._forceRefresh
                or prevPos[1] ~= position[1]
                or prevPos[2] ~= position[2]
                or prevPos[3] ~= position[3]
                or self._prevZoom ~= zoom
            then
                self._forceRefresh = false
                self._prevPosition = position
                self._prevZoom = zoom
                return true
            end
            return false
        end,

        ---@param self WVReclaimComponent
        Refresh = function(self)
            self._forceRefresh = true
        end,

        ---@param self WVReclaimComponent
        CheckPreviewStateChanged = function(self)
            local curState = IsKeyDown("Control") and IsKeyDown("Shift")
            if self._previewState ~= curState then
                self._previewState = curState
                return true
            end
            return false
        end,

        ---@param self WVReclaimComponent
        UpdateReclaimData = function(self)
            if self._updateTimer < updateRate then
                return
            end
            self._updateTimer = 0

            local view = self.worldView

            local tl = UnProject(view, { view.Left(), view.Top() })
            local tr = UnProject(view, { view.Right(), view.Top() })
            local br = UnProject(view, { view.Right(), view.Bottom() })
            local bl = UnProject(view, { view.Left(), view.Bottom() })

            local x1, y1 = tl[1], tl[3]
            local x2, y2 = tr[1], tr[3]
            local x3, y3 = br[1], br[3]
            local x4, y4 = bl[1], bl[3]

            local minX = MathMin(x1, x2, x3, x4)
            local maxX = MathMax(x1, x2, x3, x4)
            local minY = MathMin(y1, y2, y3, y4)
            local maxY = MathMax(y1, y2, y3, y4)

            local onScreenReclaimIndex = 1
            ---@type UIReclaimDataPoint[]
            local onScreenReclaims = {}

            if ContainsWholeMap(minX, minY, maxX, maxY) then
                for _, r in insidePlayableAreaReclaim do
                    onScreenReclaims[onScreenReclaimIndex] = r
                    onScreenReclaimIndex = onScreenReclaimIndex + 1
                end
            else
                local y21 = y2 - y1
                local y32 = y3 - y2
                local y43 = y4 - y3
                local y14 = y1 - y4
                local x21 = x2 - x1
                local x32 = x3 - x2
                local x43 = x4 - x3
                local x14 = x1 - x4

                local function ContainsPoint(point)
                    local x0, y0 = point[1], point[3]
                    if x0 < minX or x0 > maxX or y0 < minY or y0 > maxY then
                        return false
                    end

                    return ((x1 - x0) * y21 - x21 * (y1 - y0)) > 0
                        and ((x2 - x0) * y32 - x32 * (y2 - y0)) > 0
                        and ((x3 - x0) * y43 - x43 * (y3 - y0)) > 0
                        and ((x4 - x0) * y14 - x14 * (y4 - y0)) > 0
                end

                for _, r in insidePlayableAreaReclaim do
                    if ContainsPoint(r.position) then
                        onScreenReclaims[onScreenReclaimIndex] = r
                        onScreenReclaimIndex = onScreenReclaimIndex + 1
                    end
                end
            end

            local size = useBatching
                and _CombineReclaim(self, onScreenReclaims)
                or _CopyReclaim(self, onScreenReclaims)

            TableSort(self._reclaimData, CompareMass)

            local labelIndex = 1
            local reclaimGroup = self._reclaimGroup
            local labels = self._labels
            for i = 1, size do
                if labelIndex > maxLabels then
                    break
                end
                local label = labels[labelIndex]
                if label and IsDestroyed(label) then
                    label = nil
                end
                if not label then
                    label = ReclaimLabel(reclaimGroup)
                    labels[labelIndex] = label
                end
                labelIndex = labelIndex + 1
            end
            -- Hide labels we didn't use
            for index = labelIndex, maxLabels do
                local label = labels[index]
                if label then
                    if IsDestroyed(label) then
                        labels[index] = nil
                    elseif not label:IsHidden() then
                        label:Hide()
                    end
                end
            end
        end,

        ---@param self WVReclaimComponent
        ProjectReclaim = function(self)
            local reclaimDataPool = self._reclaimData
            local labels = self._labels
            local toDraw = MathMin(self._usedReclaimData, maxLabels)

            local positions = {}
            for i = 1, toDraw do
                local reclaim = reclaimDataPool[i]
                positions[i] = reclaim.position
            end

            local view = self.worldView
            local projected = view:ProjectMultiple(positions)

            for i = 1, toDraw do
                local reclaim = reclaimDataPool[i]
                local label = labels[i]
                local pos = projected[i]
                if pos[1] == 0 or pos[2] == 0 then -- Just in case ProjectMultiple hallucinates
                    pos = view:Project(reclaim.position)
                end
                label:PositionOnScreen(pos)
                label:DisplayReclaim(reclaim)
            end

        end,

        ---@param self WVReclaimComponent
        ---@param delta number
        OnFrame = function(self, delta)
            if self:CheckPreviewStateChanged() then
                self._showingReclaim = self._previewState
                self._forceRefresh = true
                self._updateTimer = updateRate
            end

            if self._showingReclaim or self._enabledWithReclaimMode then
                if self:CheckNeedRefresh() then
                    self._updateTimer = self._updateTimer + delta
                    self:UpdateReclaimData()
                    self:ProjectReclaim()
                end
            else
                self._reclaimGroup:Hide()
            end
        end,

        ---@param self WVReclaimComponent
        OnUpdateCursor = function(self)
            local cm = GetCommandMode()[2]
            local order = cm and cm.name
            if order == "RULEUCC_Reclaim" then
                self._enabledWithReclaimMode = true
            elseif order ~= "RULEUCC_Move" and self._enabledWithReclaimMode then
                self._enabledWithReclaimMode = false
            end
        end,

        ---@param self WVReclaimComponent
        OnDestroy = function(self)
            self._reclaimGroup:Destroy()
            self._reclaimGroup = nil
        end
    }

    ReUI.WorldView.PrimaryComponents.Reclaim = WVReclaimComponent
end
