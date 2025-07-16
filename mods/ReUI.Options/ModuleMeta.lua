---@meta

---@class ReUI.Options : ReUI.Module
ReUI.Options = {}

---Table with options provided by mods.
---
---Whenever this table is indexed it will try to find options file within mod's folder.
---```lua
---local myOptions = ReUI.Options.Mods["MyMod"]
---```
---Will look for `/mods/MyMod/Options.lua` file where you assign options
---for your mod.
---
---This file also must have `Main` function where you setup options for being displayed in
---options window. It will be called once user accesses options window.
---@type table<string, table>
ReUI.Options.Mods = {}

---Creates OptionVar from value when used within `ReUI.Options.Mods`.
---Example:
---```lua
---ReUI.Options.Mods["MyMod"] = {
---    boolOpt = Opt(true),
---    numberOpt = Opt(10),
---    stringOpt = Opt("ffff00ff"),
---    nestedTable = {
---         otherOpt = Opt(10),
---         ...
---   }
---}
---```
---@generic T
---@param value T
---@return Opt<T>
function ReUI.Options.Opt(value)
end

---@class ReUI.Options.Builder
ReUI.Options.Builder = {}

---Adds options window builder for a mod
---@param option string
---@param title string
---@param buildTable table|fun(frame:Frame):Control
function ReUI.Options.Builder.AddOptions(option, title, buildTable)
end

---Adds splitter to options window
---@return table
function ReUI.Options.Builder.Splitter()
end

---Adds title to options window
---@param name string
---@param fontSize? number
---@param fontFamily? string
---@param fontColor? LazyOrValue<Color>
---@param indent? number
function ReUI.Options.Builder.Title(name, fontSize, fontFamily, fontColor, indent)
end

function ReUI.Options.Builder.Color(name, optionVar, indent)
end

function ReUI.Options.Builder.Column(name, optionVar, indent)
end

function ReUI.Options.Builder.Filter(name, optionVar, indent)
end

function ReUI.Options.Builder.Slider(name, min, max, inc, optionVar, indent)
end

function ReUI.Options.Builder.ColorSlider(name, optionVar, indent)
end

function ReUI.Options.Builder.TextEdit(name, optionVar, charLimit, indent)
end

function ReUI.Options.Builder.Strings(name, items, optionVar, indent)
end

function ReUI.Options.Builder.Fonts(name, optionVar, indent)
end
