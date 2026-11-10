local OptionValue = ReUI.Options.OptionValue or ReUI.Options.Opt

ReUI.Options.Mods["ReUI.Hotbuild"] = {
}

function Main(isReplay)
    local View = import("Modules/views/view.lua")
    if ReUI.Options and ReUI.Options.Add then
        ReUI.Options.Add("ReUI.Hotbuild", function(frame)
            return View.OpenWindow(frame)
        end)
    end
end
