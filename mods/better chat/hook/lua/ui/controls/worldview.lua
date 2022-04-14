local oldWorldView = WorldView
local OnClick = import("/mods/better chat/modules/BCmain.lua").OnClick

WorldView = Class(oldWorldView, Control) {
    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            OnClick()
        end
        return oldWorldView.HandleEvent(self, event)
    end,
}
