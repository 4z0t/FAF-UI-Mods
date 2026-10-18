---@alias OptionsContainerF fun(q:OptionsContainer)

---@deprecated
---@return OptionsContainerF
function Splitter()
    ---@param q OptionsContainer
    return function(q)
        q:Splitter()
    end
end

---@deprecated
function Column(index)
    return false
end

---@deprecated
---@return OptionsContainerF
function Title(name, fontSize, fontFamily, fontColor, indent)
    ---@param q OptionsContainer
    return function(q)
        q:Indent(indent or 0)
        q:Title(name, fontSize, fontFamily, fontColor)
        q:Unindent(indent or 0)
    end
end

---@deprecated
---@return OptionsContainerF
function Color(name, optionVar, indent)
    ---@param q OptionsContainer
    return function(q)
        q:Text("TODO COLOR")
    end
    --[[ {
        type = "color",
        name = name,
        optionVar = optionVar,
        indent = indent or 0
    }]]
end

---@deprecated
---@return OptionsContainerF
function Filter(name, optionVar, indent)
    ---@param q OptionsContainer
    return function(q)
        q:Indent(indent or 0)
        q:OptionCheckbox(name, optionVar)
        q:Unindent(indent or 0)
    end
end

---@deprecated
---@return OptionsContainerF
function Slider(name, min, max, inc, optionVar, indent)
    ---@param q OptionsContainer
    return function(q)
        q:Indent(indent or 0)
        q:OptionSlider(name, optionVar, min, max, inc)
        q:Unindent(indent or 0)
    end
end

---@deprecated
---@param name string
---@param optionVar ReUI.Options.ReactiveOption
---@param charLimit any
---@param indent any
---@return OptionsContainerF
function TextEdit(name, optionVar, charLimit, indent)
    ---@param q OptionsContainer
    return function(q)
        q:Indent(indent or 0)
        q:Edit(name, function(text)
            optionVar.Value = text
        end, charLimit or 100, optionVar.Value)
        q:Unindent(indent or 0)
    end
end

---@deprecated
---@return OptionsContainerF
function ColorSlider(name, optionVar, indent, mode)
    ---@param q OptionsContainer
    return function(q)
        q:Indent(indent or 0)
        q:OptionColorSliders(name, optionVar, mode)
        q:Unindent(indent or 0)
    end
end

---@deprecated
---@return OptionsContainerF
function Strings(name, items, optionVar, indent)
    ---@param q OptionsContainer
    return function(q)
        q:Indent(indent or 0)
        q:OptionCombo(name, optionVar,
            ReUI.LINQ.Enumerate(items)
            :Select(function(value)
                return {
                    text = value,
                    value = value,
                }
            end)
            :ToArray()
        )
        q:Unindent(indent or 0)
    end

end

---@deprecated
---@return OptionsContainerF
function Fonts(name, optionVar, indent)
    return Strings(name,
        {
            "Arial",
            "Arial Black",
            "Arial Narrow",
            "Zeroes Three",
            "Butterbelly",
            "Arial Rounded MT Bold",
            "VDub",
            "Wintermute"
        }, optionVar, indent)
end
