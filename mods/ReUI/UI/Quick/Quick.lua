Version = "1.0.0"

ReUI.Require
{
    "ReUI.UI >= 1.5.0",
    "ReUI.UI.Views >= 1.2.0",
}

function Main(isReplay)
    local WindowModule = import("Modules/Window.lua")
    ---@class ReUI.UI.Quick : ReUI.Module
    return {
        ---@type Quick.Window | fun(title: string, fn: fun(q: Quick.Container), id?: string): Quick.Window
        Window = WindowModule.QuickWindow,

        Border = WindowModule.Border,
        NinePatchBorder = WindowModule.NinePatchBorder,

        ---@type Quick.Container
        Container = import("Modules/Container.lua").QuickContainer,

        ---@type Quick.Context
        Context = import("Modules/Container.lua").Context,
    }
end
