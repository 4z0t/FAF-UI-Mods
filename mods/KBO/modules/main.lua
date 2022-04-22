local Presenter = import('presenter.lua')
local Model = import('model.lua')
local View = import("/mods/KBO/modules/views/view.lua")

function init(isReplay)
    Model.init()
    Presenter.init()
    View.init()
end
