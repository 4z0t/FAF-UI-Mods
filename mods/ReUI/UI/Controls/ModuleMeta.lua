---@meta

---Provides enhanced UI controls classes with layout capabilities.
---@class ReUI.UI.Controls : ReUI.Module
ReUI.UI.Controls = {}

---@type ReUI.UI.Controls.Group | fun(parent: Control, debugname?: string): ReUI.UI.Controls.Group
ReUI.UI.Controls.Group = ...

---@type ReUI.UI.Controls.Bitmap | fun(parent: Control, filename?: Lazy<FileName>, debugname?: string): ReUI.UI.Controls.Bitmap
ReUI.UI.Controls.Bitmap = ...

---@type ReUI.UI.Controls.Text | fun(parent: Control, debugname?: string): ReUI.UI.Controls.Text
ReUI.UI.Controls.Text = ...

---@type ReUI.UI.Controls.CheckBox | fun(parent: Control, normalUnchecked: Lazy<FileName>, normalChecked: Lazy<FileName>, overUnchecked: Lazy<FileName>, overChecked: Lazy<FileName>, disabledUnchecked: Lazy<FileName>, disabledChecked: Lazy<FileName>, clickCue?: string, rolloverCue?: string, debugname?: string): ReUI.UI.Controls.CheckBox
ReUI.UI.Controls.CheckBox = ...
