ReUI.Require
{
    "ReUI.Core >= 1.0.0",
}

function Main(isReplay)
    local Vector = Vector
    local IsKeyDown = IsKeyDown
    local ForkThread = ForkThread

    local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
    local UIUtil = import('/lua/ui/uiutil.lua')
    local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
    local Group = import('/lua/maui/group.lua').Group

    local function ComputeLabelPropertiesBatched(totalMass, maxMass)
        if totalMass <= 10 then
            return nil, nil
        end
        -- change color according to mass value
        if maxMass < 100 then
            return 'ffc7ff8f', 10
        end

        if maxMass < 300 then
            return 'ffd7ff05', 12
        end

        if maxMass < 600 then
            return 'ffffeb23', 17
        end

        if maxMass < 1000 then
            return 'ffff9d23', 20
        end

        if maxMass < 2000 then
            return 'ffff7212', 22
        end

        -- > 2000
        return 'fffb0303', 25
    end

    local ReclaimLabel = Class(Group)
    {
        __init = function(self, parent, position)
            Group.__init(self, parent)
            self.parent = parent
            self.position = position

            self.Top:Set(0)
            self.Left:Set(0)
            LayoutHelpers.SetDimensions(self, 10, 10)

            self.mass = Bitmap(self)
            self.text = UIUtil.CreateText(self, "", 10, UIUtil.bodyFont, true)

            self.mass.Height:Set(10)
            self.mass.Width:Set(10)
            self.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
            LayoutHelpers.AtCenterIn(self.mass, self)

            LayoutHelpers.Above(self.text, self, 2)
            LayoutHelpers.AtHorizontalCenterIn(self.text, self)

            self:DisableHitTest(true)
            self:SetNeedsFrameUpdate(true)
        end,

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

        ---@param self WorldLabel
        ProjectToScreen = function(self)
            local view = self.parent.view
            local proj = view:Project(self.position)
            self.Left:SetValue(proj.x - 0.5 * self.Width())
            self.Top:SetValue(proj.y - 0.5 * self.Height() + 1)
        end,

        DisplayReclaim = function(self, r)
            if self:IsHidden() then
                self:Show()
            end

            self.position = r.position
            self:ProjectToScreen()
            if r.mass ~= self.oldMass then
                local mass = tostring(math.floor(0.5 + r.mass))
                self.text:SetText(mass)
                self.oldMass = r.mass
                LayoutHelpers.DepthOverParent(self, self:GetParent(), r.mass)
            end
            self:AdjustToValue(r.mass, r.max)
        end,

        OnFrame = function(self, delta)
            if self.parent.isMoving then
                self:ProjectToScreen()
            end
        end,

        OnHide = function(self, hidden)
            self:SetNeedsFrameUpdate(not hidden)
        end,
    }

    --- Better reclaim labels
    ReUI.Core.Hook("/lua/ui/game/reclaim.lua", "CreateReclaimLabel", function(field, module)
        return function(view)
            return ReclaimLabel(view, Vector(0, 0, 0))
        end
    end)

    if isReplay then
        return
    end

    --- Display reclaim labels when in reclaim command mode
    ReUI.Core.Hook("/lua/ui/game/reclaim.lua", "OnCommandGraphShow", function(field, module)
        local active = false
        local ShowReclaim = module.ShowReclaim

        local function OnCommandGraphShowThread(view)
            local keydown
            while active do
                keydown = IsKeyDown('Control')
                if keydown ~= view.ShowingReclaim and not view.EnabledWithReclaimMode then -- state has changed
                    ShowReclaim(keydown)
                end
                WaitSeconds(0.1)
            end

            ShowReclaim(false)
        end

        return function(bool)
            local view = import("/lua/ui/game/worldview.lua").viewLeft
            if view.ShowingReclaim and not active then return end -- if on by toggle key

            active = bool
            if active then
                ForkThread(OnCommandGraphShowThread, view)
            else
                active = false -- above coroutine runs until now
            end
        end
    end)

    ReUI.Core.Hook("/lua/ui/controls/worldview.lua", "WorldView", function(WorldView, module)
        local GetCommandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode
        local ShowReclaim = import("/lua/ui/game/Reclaim.lua").ShowReclaim

        local _OnUpdateCursor = WorldView.OnUpdateCursor
        WorldView.EnabledWithReclaimMode = false
        WorldView.OnUpdateCursor = function(self)
            local cm = GetCommandMode()[2]
            local order = cm and cm.name
            if order == "RULEUCC_Reclaim" then
                if not self.ReclaimThread then
                    ShowReclaim(true)
                else
                    self.ShowingReclaim = true
                end
                self.EnabledWithReclaimMode = true
            elseif order ~= "RULEUCC_Move" and self.EnabledWithReclaimMode then
                if not self.ReclaimThread then
                    ShowReclaim(false)
                else
                    self.ShowingReclaim = false
                end
                self.EnabledWithReclaimMode = false
            end
            return _OnUpdateCursor(self)
        end

        return WorldView
    end)
end
