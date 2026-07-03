Version = "1.0.0"

function Main(isReplay)
    return {
        ---@diagnostic disable-next-line: different-requires
        ComponentContainer = import("Modules/ComponentContainer.lua").ComponentContainer,
        ALazyComponentContainer = import("Modules/ALazyComponentContainer.lua").ALazyComponentContainer
    }
end
