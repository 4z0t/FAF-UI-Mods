local Opt = ReUI.Options.OptionValue

ReUI.Options.Mods["ReUI.Tests"] = {
    test = Opt(true),
    value = Opt(1),
    item = Opt("one"),
    text = Opt("Haha")
}

function Main()
    ReUI.Options.Add("Test", function(frame)
        local options = ReUI.Options.Mods["ReUI.Tests"]
        local i = 1

        ---@param q OptionsContainer
        local function f(q)
            q:Group(200, 100, function(g)
                g:Title("Title", 20)
                g:Button("Crash", function()
                    GetUnitCommandData("nil")
                end)
                g:SameLine()
                g:Text("AAAA")
            end)
            q:SameLine()

            ---@param g OptionsContainer
            q:Group(-20, 200, function(g)
                g:Text("Text")
                g:SameLine()
                g:Text("Other text")
                g:Button("Clone", function(modifiers)
                    i = i + 1
                    ReUI.Options.Window("Test" .. i, f)
                end)
                g:OptionCheckbox("Checkbox", options.test)
                g:OptionTextEdit("edit", options.text)
                g:OptionCombo("combo", options.item, {
                    {
                        text = "1",
                        value = "one"
                    },
                    {
                        text = "2",
                        value = "two"
                    }
                })
                g:OptionSlider("slider", options.value, 1, 100, 1)
            end)

        end

        return ReUI.Options.Window("Test", f)
    end)
end
