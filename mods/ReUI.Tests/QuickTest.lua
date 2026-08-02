local instance

function Run()
    local LayoutFor = ReUI.UI.FloorLayoutFor

    local i = 1

    ---@type Quick.Window
    local w

    w = ReUI.UI.Quick.Window("Test",
        function(q)
            q:Group(200, 100, function(g)
                g:Title("Title", 20)
                g:Button("Button")
                g:Checkbox("Checkbox")
                g:SameLine()
                g:Text("AAAA")
                g:Slider("Slider", 0, 100, 1, function(slider, value)
                end)
            end)
            q:SameLine()
            q:Group(-20, 200, function(g)
                g:Text("Text")
                g:SameLine()
                g:Text("Other text")
                g:Button("Button")
                g:Checkbox("Checkbox")
                g:Edit("Input", function(edit, text)
                end)
                g:Text("Text")
                g:Slider("Slider", 0, 100, 1, function(slider, value)
                end)
            end)
            q:Group(200, 200, function(g)
                g:Indent(20)
                g:Text("Text")
                g:SameLine()
                g:Text("Other text " .. i)
                g:Button("Rebuild", function(button, modifiers)
                    w:Rebuild()
                    i = i + 1
                end)
                g:Checkbox("Checkbox")
                g:Combo("Combo", {
                    "one",
                    "two",
                    "three"
                }, function(c, index, text)
                end)
            end)
            q:SameLine(2)
            q:Image("/mods/ReUI/icon.png", 200)
            q:SameLine(2)
            q:Image("/mods/ReUI/icon.png", 20)
        end)

    instance = w
end

function __moduleinfo.OnReload(newModule)
    newModule.Run()
end

function __moduleinfo.OnDirty()
    if instance then
        instance:Destroy()
        instance = nil
    end
    ForkThread(function()
        WaitFrames(1)
        import(__moduleinfo.name)
    end)
end
