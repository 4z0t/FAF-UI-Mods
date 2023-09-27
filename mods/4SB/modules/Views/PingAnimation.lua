local Group = UMT.Controls.Group
local Bitmap = UMT.Controls.Bitmap

local LayoutFor = UMT.Layouter.ReusedLayoutFor

local count = 30

local offset = 0

local appearAndFade = UMT.Animation.Factory.Base
    :OnStart(function(control, state)
        return { direction = 1, targetAlpha = control.id / count * (1 - offset) + offset }
    end)
    :OnFrame(function(control, delta, state)
        if control:GetAlpha() >= state.targetAlpha and state.direction == 1 then
            state.direction = -1
            return false
        elseif state.direction == -1 and control:GetAlpha() == 0 then
            return true
        end
        control:SetAlpha(math.clamp(control:GetAlpha() + delta * state.direction / 0.25, 0., 1.))
    end)
    :OnFinish(function(control, state)
        if control.id == count then
            control:GetParent():Destroy()
        end
    end)
    :Create()



local appear = UMT.Animation.Factory.Base
    :OnStart(function(control, state)
        return { targetAlpha = control.id / count * (1 - offset) + offset }
    end)
    :OnFrame(function(control, delta, state)
        if control:GetAlpha() >= state.targetAlpha then
            return true
        end
        control:SetAlpha(math.clamp(control:GetAlpha() + delta / 0.1, 0., 1.))
    end)
    :OnFinish(function(control, state)
        if control.id == count then
            control:GetParent():Fade()
        end
    end)
    :Create()

local fade = UMT.Animation.Factory.Alpha
    :For(0.5)
    :ToFade()
    :EndWith(0)
    :OnFinish(function(control, state)
        if control.id == count then
            control:GetParent():Destroy()
        end
    end)
    :Create()

local layerAnimation = UMT.Animation.Sequential(appearAndFade, 0.05, 0.1)
local layersAppear = UMT.Animation.Sequential(appear, 1 / 60, 0.1)
local layersFade = UMT.Animation.Sequential(fade, 1 / 60)


local pingColors = {
    red    = 'FFFF0000',
    yellow = 'FFFFFF00',
    blue   = 'FF3DBDCC',
}


PingAnimation = UMT.Class(Group)
{
    __init = function(self, parent, color, location)
        Group.__init(self, parent)
        self._color = color
        self._location = location
        self:_InitLayers(count)
    end,

    __post_init = function(self, parent)
        self:Layout()

    end,

    _Layout = function(self, layouter)
        self:_LayoutLayers(layouter)
    end,


    _InitLayers = function(self, count)
        self._layers = {}
        for i = 1, count do
            self._layers[i] = Bitmap(self)

        end

    end,

    _LayoutLayers = function(self, layouter)
        local prev
        for i, layer in self._layers do
            if prev then
                layouter(layer)
                    :Right(prev.Left)
            else
                layouter(layer)
                    :Right(self.Right)
            end
            layouter(layer)
                :Top(self.Top)
                :Bottom(self.Bottom)
                :Width(1)
                :Color(pingColors[self._color])
                :Alpha(0)
                :DisableHitTest()
            layer.id = i
            prev = layer
        end
        layouter(self)
            :Left(prev.Left)
            :EnableHitTest()

    end,

    ---@param self any
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            local currentCamSettings = GetCamera('WorldCamera'):SaveSettings()
            currentCamSettings.Focus = self._location
            GetCamera('WorldCamera'):RestoreSettings(currentCamSettings)
            return true
        end
        return false
    end,

    Animate = function(self)
        layersAppear:Apply(self._layers)
    end,
    Fade = function(self)
        layersFade:Apply(self._layers)
    end
}
