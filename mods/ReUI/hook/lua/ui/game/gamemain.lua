CreateUI = ReUI.__loader--[[@as ReUI.Loader]] :Wrap(CreateUI)


-- This must be in base game. I'd hook this, but `ignoreSelection` is local.
function IsIgnoredSelection()
    ---@diagnostic disable-next-line:undefined-global
    return ignoreSelection or import('/lua/ui/game/selection.lua').IsHidden()
end
