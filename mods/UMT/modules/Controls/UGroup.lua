local _Group = import('/lua/maui/group.lua').Group


---@class UMT.Group : Group, ILayoutable
Group = UMT.Class(_Group, UMT.Interfaces.ILayoutable)
{
    ---@param self UMT.Group
    OnInit = function(self)
        self:InitLayouter(self:GetParent())
        _Group.OnInit(self)
    end
}
