Version = "0.1.0"

ReUI.Require
{
    "ReUI.UI >= 1.5.0",
    "ReUI.UI.Views >= 1.0.0",
    "ReUI.Options >= 1.2.0",
}

function Main(isReplay)
    ---@class ReUI.UI.Quick : ReUI.Module
    return {
        ---@type Quick.Window | fun(title: string, fn: fun(q: Quick.Container)): Quick.Window
        Window = import("Modules/Window.lua").QuickWindow,

        ---@type Quick.Container
        Container = import("Modules/Container.lua").QuickContainer,

        ---@type Quick.Context
        Context = import("Modules/Container.lua").Context,
    }
end
