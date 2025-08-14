ReUI.Require
{
    "ReUI.Core >= 1.1.0",
    "ReUI.UI.Controls >= 1.0.0",
    "ReUI.UI.Views >= 1.0.0",
    "ReUI.ECS >= 1.0.0"
}

function Main(isReplay)
    ---@diagnostic disable-next-line:different-requires
    local BaseGridItem = import("Modules/BaseGridItem.lua").BaseGridItem
    local BaseGridPanel = import("Modules/BaseGridPanel.lua").BaseGridPanel
    ---@diagnostic disable-next-line:different-requires
    local AItemComponent = import("Modules/AItemComponent.lua").AItemComponent
    local ASelectionHandler = import("Modules/ASelectionHandler.lua").ASelectionHandler

    return {
        Abstract = {
            AItemComponent = AItemComponent,
            ASelectionHandler = ASelectionHandler,
        },
        BaseGridItem = BaseGridItem,
        BaseGridPanel = BaseGridPanel,
    }
end
