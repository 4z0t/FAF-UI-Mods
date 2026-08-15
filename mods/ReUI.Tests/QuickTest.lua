local instance

function Run()
    local i = 1

    ---@type Quick.Window
    local w

    w = ReUI.UI.Quick.Window("Test",
        function(q)
            q:Group(200, 100, function(g)
                g:Title("Title", 20)
                g:Button("Crash", function()
                    GetUnitCommandData("nil")
                end)
                g:Checkbox("Checkbox")
                g:SameLine()
                g:Text("AAAA")
                g:Slider("Slider", 0, 100, 1, function(value)
                end)
            end)
            q:SameLine()
            q:Group(-20, 200, function(g)
                g:Text("Text")
                g:SameLine()
                g:Text("Other text")
                g:Button("Clear", function(modifiers)
                    i = 1
                    w:Rebuild()
                end)
                g:Checkbox("Checkbox")
                g:Edit("Input", function(text)
                end)
                g:Text("Text")
                g:Slider("Slider", 0, 100, 1, function(value)
                end)
            end)
            q:Group(200, 0, function(g)
                g:Indent(20)
                g:Text("Text")
                g:SameLine()
                g:Text("Other text " .. i)
                g:Button("Rebuild", function(modifiers)
                    i = i + 1
                    w:Rebuild()
                end)
                g:Tooltip("Click to rebuild me", "Hello world")
                for j = 1, i do
                    g:Checkbox("Checkbox")
                end
                g:Combo("Combo", {
                    "one",
                    "two",
                    "three"
                }, function(index, text)
                end)
            end)
            q:SameLine(2)
            q:Image("/mods/ReUI/icon.png", 200)
            q:SameLine(2)
            q:Image("/mods/ReUI/icon.png", 20)
            q:ScrollableList(0, 200, 20, 50, function(r, index)
                r:Indent(index  * 10)
                r:Text("Line " .. index)
                r:Slider("Slider", 0, 100, 1, function(value)
                end)
            end)

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
