local _Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Bitmap = import("UBitmap.lua").Bitmap

---@class UMT.Checkbox : MauiCheckbox, ILayoutable
Checkbox = UMT.Class(_Checkbox, UMT.Interfaces.ILayoutable)
{
    OnInit = Bitmap.OnInit,
    ResetLayout = Bitmap.ResetLayout,
}
