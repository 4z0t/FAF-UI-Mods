local OptionValue = ReUI.Options.OptionValue

ReUI.Options.Mods["ReUI.Hotbuild"] = {
}

function Main(isReplay)
    local View = import("Modules/views/view.lua")
    ReUI.Options.Add("ReUI.Hotbuild", function(frame)
        return View.OpenWindow(frame)
    end)
end
