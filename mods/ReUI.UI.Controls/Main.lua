ReUI.Require
{
    "ReUI.UI >= 1.0.0"
}

function Main(isReplay)

    local _Bitmap = import('/lua/maui/bitmap.lua').Bitmap
    local _Group = import('/lua/maui/group.lua').Group
    local _Text = import('/lua/maui/text.lua').Text
    local _Checkbox = import('/lua/maui/checkbox.lua').Checkbox

    ---@class ReUI.UI.Controls.Control : Control, ReUI.UI.Layoutable

    ---@class ReUI.UI.Controls.Bitmap : Bitmap, ReUI.UI.Controls.Control
    local Bitmap = ReUI.Core.Class(_Bitmap, ReUI.UI.Layoutable)
    {
        ---@param self ReUI.UI.Controls.Bitmap
        OnInit = function(self)
            self:InitLayouter(self:GetParent())
            _Bitmap.OnInit(self)
        end,

        ---@param self ReUI.UI.Controls.Bitmap
        ResetLayout = function(self)
            self.Layouter(self)
                :ResetPosition()
                :Width(self.Layouter:ScaleVar(self.BitmapWidth))
                :Height(self.Layouter:ScaleVar(self.BitmapHeight))
        end,
    }

    ---@class ReUI.UI.Controls.Group : Group, ReUI.UI.Controls.Control
    local Group = ReUI.Core.Class(_Group, ReUI.UI.Layoutable)
    {
        ---@param self ReUI.UI.Controls.Group
        OnInit = function(self)
            self:InitLayouter(self:GetParent())
            _Group.OnInit(self)
        end,
    }

    local Text;
    ---@class ReUI.UI.Controls.Text : Text, ReUI.UI.Controls.Control
    Text = ReUI.Core.Class(_Text, ReUI.UI.Layoutable)
    {
        ---@param parent Control
        ---@param family LazyOrValue<string>
        ---@param pointsize LazyOrValue<number>
        ---@return ReUI.UI.Controls.Text
        Create = function(parent, family, pointsize)
            ---@type ReUI.UI.Controls.Text
            local t = Text(parent)
            t:SetFont(family, pointsize)
            return t
        end,

        ---@param self ReUI.UI.Controls.Text
        OnInit = function(self)
            self:InitLayouter(self:GetParent())
            _Text.OnInit(self)
        end,

        ---@param self ReUI.UI.Controls.Text
        ---@param family LazyVar<string>|string
        ---@param pointsize LazyVar<number>|number
        SetFont = function(self, family, pointsize)
            if self._font then
                self._lockFontChanges = true
                self._font._pointsize:Set(self.Layouter:ScaleVar(pointsize))
                self._font._family:Set(family)
                self._lockFontChanges = false
                self:_internalSetFont()
            end
        end,
    }

    ---@class ReUI.UI.Controls.CheckBox : MauiCheckbox, ReUI.UI.Controls.Control
    local CheckBox = ReUI.Core.Class(_Checkbox, ReUI.UI.Layoutable)
    {
        OnInit = Bitmap.OnInit,
        ResetLayout = Bitmap.ResetLayout,
    }

    return {
        Group = Group,
        Bitmap = Bitmap,
        Text = Text,
        CheckBox = CheckBox
    }
end
