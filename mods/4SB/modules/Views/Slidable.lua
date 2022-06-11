local Group = import('/lua/maui/group.lua').Group


---@class Slidable
Slidable = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent
        self._direction = 1
        self:SetNeedsFrameUpdate(false)
        self:EnableHitTest(true)
    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            self:SetNeedsFrameUpdate(true)
            self:OnMouseExit()
            return true
        elseif event.Type == 'MouseEnter' then
            self:SetNeedsFrameUpdate(true)
            self:OnMouseEnter()
            return true
        end
        return false
    end,

    OnFrame = function(self, delta)
        if self:StopAnimation() then
            self:SetNeedsFrameUpdate(false)
        else
            self:OnAnimation(delta)
        end
    end,


    ---@param self Slidable
    --- returns true if reached one of the positions, false if not
    -- overloadable
    StopAnimation = function(self)
        
        return false
    end,

    -- overloadable
    OnAnimation = function(self, delta)

    end,

    -- overloadable
    OnMouseExit = function(self)
        self._direction = -1
    end,

    -- overloadable
    OnMouseEnter = function(self)
        self._direction = 1
    end


}
