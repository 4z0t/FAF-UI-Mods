local MathFloor = math.floor

local LazyVar = import("/lua/lazyvar.lua")



local function CreateReclaimLabel(view, recl)
    local label = WorldLabel(view, Vector(0, 0, 0))

    label.mass = Bitmap(label)
    label.oldMass = 0 -- fix compare bug
    label.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
    label.mass.Height:Set(10)
    label.mass.Width:Set(10)
    LayoutHelpers.AtCenterIn(label.mass, label)


    label.text = UIUtil.CreateText(label, "", 10, UIUtil.bodyFont)
    label.text:SetColor('ffc7ff8f')
    label.text:SetDropShadow(true)
    LayoutHelpers.Above(label.text, label.mass, 2)
    LayoutHelpers.AtHorizontalCenterIn(label.text, label)


    label:DisableHitTest(true)
    label.OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end


    label.PosX = LazyVar.Create()
    label.PosY = LazyVar.Create()
    label.Left:Set(function()
        return view.Left() + label.PosX() - label.Width() / 2
    end)
    label.Top:Set(function()
        return view.Top() + label.PosY() - label.Height() / 2 + 1
    end)
    label.Update = function(self)
        local proj = self.parent.view:Project(self.position)
        self.PosX:Set(proj.x)
        self.PosY:Set(proj.y)
        if self.istexthidden then
            self.text:Hide()
        end
    end

    label.SetText = function(self, value)

        local function ComputeLabelProperties(mass)
            if mass < 10 then
                return nil, nil
            end
            -- change color according to mass value
            if mass < 100 then
                return 'ffc7ff8f', 10
            end

            if mass < 300 then
                return 'ffd7ff05', 12
            end

            if mass < 600 then
                return 'ffffeb23', 17
            end

            if mass < 1000 then
                return 'ffff9d23', 20
            end

            if mass < 2000 then
                return 'ffff7212', 22
            end

            -- > 2000
            return 'fffb0303', 25
        end

        local color, size = ComputeLabelProperties(value)
        if color then
            self.text:SetFont(UIUtil.bodyFont, size) -- r.mass > 2000
            self.text:SetColor(color)
            self.text:Show()
            self.istexthidden = false
        else
            self.text:Hide()
            self.istexthidden = true
        end
    end

    label.DisplayReclaim = function(self, r)
        if self:IsHidden() then
            self:Show()
        end
        self:SetPosition(r.position)
        if r.mass ~= self.oldMass then
            -- local avgMass = math.floor(r.mass / r.count)
            local maxMass = r.max or (r.mass + 0.5)
            local massStr = tostring(math.floor(0.5 + r.mass))
            local measure = maxMass
            self:SetText(measure)
            self.text:SetText(massStr)
            self.oldMass = r.mass
        end
    end

    label:Update()

    return label
end

local ReclaimTotal
local LabelRes = LayoutHelpers.ScaleNumber(30)

local function SumReclaim(r1, r2)
    local massSum = r1.mass + r2.mass

    local r = {
        mass = massSum,
        count = r1.count + (r2.count or 1),
        position = Vector((r1.mass * r1.position[1] + r2.mass * r2.position[1]) / massSum, r1.position[2],
            (r1.mass * r1.position[3] + r2.mass * r2.position[3]) / massSum),
        max = math.max(r1.max or r1.mass, r2.mass)
    }
    return r
end

local function CompareMass(a, b)
    return a.mass > b.mass
end

function UpdateLabels()
    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera
    local heightRes = MathFloor(view.Height() / LabelRes)
    local reclaimMatrix = {}
    local secondPassMatrix
    local onScreenReclaimIndex = 1
    local onScreenReclaims = {}
    local onScreenMassTotal = 0

    for _, r in Reclaim do
        if r.mass >= MinAmount then
            onScreenReclaims[onScreenReclaimIndex] = r
            onScreenReclaimIndex = onScreenReclaimIndex + 1
        end
    end

    table.sort(onScreenReclaims, CompareMass)
    
    for _, r in onScreenReclaims do
        local proj = view:Project(r.position)
        if (not (proj.x < 0 or proj.y < 0 or proj.y > view.Height() or proj.x > view.Width())) then
            onScreenMassTotal = onScreenMassTotal + r.mass
            local rx = MathFloor(proj.x / LabelRes)
            local ry = MathFloor(proj.y / LabelRes)
            if reclaimMatrix[ry] then
                if reclaimMatrix[ry][rx] then
                    reclaimMatrix[ry][rx] = SumReclaim(reclaimMatrix[ry][rx], r)
                else
                    reclaimMatrix[ry][rx] = {
                        mass = r.mass,
                        position = r.position,
                        count = 1
                    }
                end
            else
                reclaimMatrix[ry] = {}
                reclaimMatrix[ry][rx] = {
                    mass = r.mass,
                    position = r.position,
                    count = 1
                }
            end
        end
    end

    -- second pass
    -- secondPassMatrix = reclaimMatrix
    -- reclaimMatrix = {}
    -- for _, line in secondPassMatrix do
    --     for _, r in line do
    --         local proj = view:Project(r.position)
    --         local rx = math.floor((proj.x - LabelRes / 2) / LabelRes)
    --         local ry = math.floor((proj.y - LabelRes / 2) / LabelRes)
    --         if reclaimMatrix[ry] then
    --             if reclaimMatrix[ry][rx] then
    --                 reclaimMatrix[ry][rx] = sumReclaim(reclaimMatrix[ry][rx], r)
    --             else
    --                 reclaimMatrix[ry][rx] = r
    --             end
    --         else
    --             reclaimMatrix[ry] = {}
    --             reclaimMatrix[ry][rx] = r
    --         end
    --     end
    -- end

    local labelIndex = 1
    for _, line in reclaimMatrix do
        for _, recl in line do
            if labelIndex > MaxLabels then
                break
            end
            local label = LabelPool[labelIndex]
            if label and IsDestroyed(label) then
                label = nil
            end
            if not label then
                label = CreateReclaimLabel(view.ReclaimGroup, recl)
                LabelPool[labelIndex] = label
            end

            label:DisplayReclaim(recl)
            labelIndex = labelIndex + 1
        end
    end
    -- Hide labels we didn't use
    for index = labelIndex, MaxLabels do
        local label = LabelPool[index]
        if label then
            if IsDestroyed(label) then
                LabelPool[index] = nil
            elseif not label:IsHidden() then
                label:Hide()
            end
        end
    end
end

-- the reason of conflicts is line 13: have to check for reclaim mode state
-- Wanna have no conflict? add this line to other mods and remove from conflics UIDs
function OnCommandGraphShow(bool)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    if view.ShowingReclaim and not CommandGraphActive then return end -- if on by toggle key

    CommandGraphActive = bool
    if CommandGraphActive then
        ForkThread(function()
            local keydown
            while CommandGraphActive do
                keydown = IsKeyDown('Control')
                if keydown ~= view.ShowingReclaim and not view.EnabledWithReclaimMode then -- state has changed
                    ShowReclaim(keydown)
                end
                WaitSeconds(.1)
            end

            ShowReclaim(false)
        end)
    else
        CommandGraphActive = false -- above coroutine runs until now
    end
end
