local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LazyVar = import('/lua/lazyvar.lua').Create

local Options = import("Options.lua")

local LayoutFor = UMT.Layouter.ReusedLayoutFor
local alphaAnimator = UMT.Animation.Animator(GetFrame(0))
local animationFactory = UMT.Animation.Factory.Base
local alphaAnimationFactory = UMT.Animation.Factory.Alpha

local PingAnimation = import("Views/PingAnimation.lua").PingAnimation

local Utils = import("Utils.lua")
local FormatNumber = Utils.FormatNumber
local TextWidth = Utils.TextWidth
local ShareManager = import("ShareManager.lua")

local checkboxes = import("DataPanelConfig.lua").checkboxes

local appearAnimation = alphaAnimationFactory
    :ToAppear()
    :For(0.3)
    :EndWith(1)
    :Create(alphaAnimator)

local fadeAnimation = alphaAnimationFactory
    :ToFade()
    :For(0.3)
    :EndWith(0)
    :Create(alphaAnimator)




local bgColor = Options.player.color.bg:Raw()

local armyViewTextPointSize = 12

local armyViewTextFont = "Zeroes Three"
local focusArmyTextFont = 'Arial Bold'

nameWidth = LazyVar()


armyViewWidth = LazyVar()
armyViewWidth:Set(function() return nameWidth() + LayoutHelpers.ScaleNumber(80) end)
allyViewWidth = LazyVar()
allyViewWidth:Set(function() return nameWidth() + LayoutHelpers.ScaleNumber(160) end)



local armyViewHeight = 20

local animationSpeed = 250

local outOfGameColor = "ffa0a0a0"

local slideForward = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        if control.Right() <= control.parent.Right() then
            return true
        end
        control.Right:Set(control.Right() - delta * animationSpeed)
    end)
    :OnFinish(function(control)
        control.Right:Set(control.parent.Right)
    end)
    :Create()

local slideBackWards = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        if control.parent.Right() < control._energyBtn.Left() then
            return true
        end
        control.Right:Set(control.Right() + delta * animationSpeed)
    end)
    :OnFinish(function(control)
        local offset = math.floor(control.Right() - control._massBtn.Left())
        control.Right:Set(function() return control.parent.Right() + offset end)
    end)
    :Create()

---@class ArmyView : Group
ArmyView = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent

        self.id = -1
        self.isOutOfGame = false

        self._bg = Bitmap(self)


        self._color = Bitmap(self)
        self._faction = Bitmap(self)
        self._rating = Text(self)
        self._name = Text(self)
    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)

        LayoutFor(self._bg)
            :Fill(self)
            :Color(bgColor)
            :DisableHitTest()

        LayoutFor(self._color)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :Right(self.Left)
            :Width(3)
            :DisableHitTest()

        LayoutFor(self._faction)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, 4)
            :Over(self, 5)
            :DisableHitTest()

        LayoutFor(self._rating)
            :AtVerticalCenterIn(self)
            :AnchorToLeft(self, -60)
            :DisableHitTest()
            :DropShadow(true)


        LayoutFor(self._name)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, 70)
            :DisableHitTest()
            :DropShadow(true)


        LayoutFor(self)
            :Width(armyViewWidth)
            :Height(armyViewHeight)

    end,

    SetStaticData = function(self, armyId, name, rating, faction, armyColor, teamColor)
        self.id = armyId

        self._color:SetSolidColor(teamColor)

        self._rating:SetColor(armyColor)
        self._rating:SetText(rating)
        self._rating:SetFont(Options.player.font.rating:Raw(), armyViewTextPointSize)

        self._name:SetText(name)
        self._name:SetClipToWidth(true)
        self._name.Width:Set(nameWidth)

        local font = GetFocusArmy() == armyId and Options.player.font.focus or Options.player.font.name
        nameWidth:Set(math.max(nameWidth(), TextWidth(name, font(), armyViewTextPointSize)))
        self._name:SetFont(font:Raw(), armyViewTextPointSize)

        self._faction:SetTexture(UIUtil.UIFile(Utils.GetSmallFactionIcon(faction)), 0)
    end,

    SetArmyColor = function(self, color)
        self._rating:SetColor(color)
    end,

    GetArmyColor = function(self)
        return self._rating._color()
    end,

    Update = function(self, data)
        if not self.isOutOfGame and data.Defeated then
            self.isOutOfGame = true
            self._name:SetColor(outOfGameColor)
        end
    end,

    ---comment
    ---@param self ArmyView
    ---@param pingData PingData
    DisplayPing = function(self, pingData)
        local ping = PingAnimation(self, pingData.ArrowColor, pingData.Location)
        LayoutFor(ping)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :Right(self.Left)
        ping:Animate()
    end
}


AllyView = Class(ArmyView)
{
    __init = function(self, parent)
        ArmyView.__init(self, parent)

        self.isAlly = true

        self._mass = Text(self)
        self._energy = Text(self)

        self._massBtn = Bitmap(self)
        self._energyBtn = Bitmap(self)

        self._unitsBtn = Bitmap(self)

        self._mass:SetText("0")
        self._energy:SetText("0")


        self._massBtn.HandleEvent = function(control, event)
            if event.Type == "ButtonPress" then
                if event.Modifiers.Left then
                    if event.Modifiers.Ctrl then
                        ShareManager.GiveAllMassToPlayer(self.id)
                    elseif event.Modifiers.Shift then
                        ShareManager.GiveMassToPlayer(self.id)
                    else
                        ShareManager.GiveMassToPlayer(self.id, 0.25)
                    end
                elseif event.Modifiers.Right then
                    ShareManager.RequestMassFromPlayer(self.id)
                else

                end
                return true
            end
        end
        self._energyBtn.HandleEvent = function(control, event)
            if event.Type == "ButtonPress" then
                if event.Modifiers.Left then
                    if event.Modifiers.Ctrl then
                        ShareManager.GiveAllEnergyToPlayer(self.id)
                    elseif event.Modifiers.Shift then
                        ShareManager.GiveEnergyToPlayer(self.id)
                    else
                        ShareManager.GiveEnergyToPlayer(self.id, 0.25)
                    end
                elseif event.Modifiers.Right then
                    ShareManager.RequestEnergyFromPlayer(self.id)
                else
                end
                return true
            end
        end
        self._unitsBtn.HandleEvent = function(control, event)
            if event.Type == "ButtonPress" then
                if event.Modifiers.Left then
                    ShareManager.GiveUnitsToPlayer(self.id)
                elseif event.Modifiers.Right then
                    ShareManager.RequestUnitFromPlayer(self.id)
                else
                end
                return true
            end

        end
    end,

    _Layout = function(self)
        ArmyView._Layout(self)

        LayoutFor(self._unitsBtn)
            :AtHorizontalCenterIn(self._faction)
            :AtVerticalCenterIn(self)
            :Texture(UIUtil.UIFile '/textures/ui/icons_strategic/commander_generic.dds')
            :Width(14)
            :Height(14)
            :Over(self, 5)
            :EnableHitTest()
            :Alpha(0)

        LayoutFor(self._energyBtn)
            :AtHorizontalCenterIn(self._energy)
            :AtVerticalCenterIn(self)
            :Texture(UIUtil.UIFile '/game/build-ui/icon-energy_bmp.dds')
            :Width(14)
            :Height(14)
            :Over(self, 5)
            :EnableHitTest()
            :Alpha(0)


        LayoutFor(self._massBtn)
            :AtHorizontalCenterIn(self._mass)
            :AtVerticalCenterIn(self)
            :Texture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
            :Width(14)
            :Height(14)
            :Over(self, 5)
            :EnableHitTest()
            :Alpha(0)

        LayoutFor(self._energy)
            :AtRightIn(self, 10)
            :AtVerticalCenterIn(self)
            :Color('fff7c70f')
            :DisableHitTest()
        self._energy:SetFont(Options.player.font.energy:Raw(), armyViewTextPointSize)



        LayoutFor(self._mass)
            :AtRightIn(self, 50)
            :AtVerticalCenterIn(self)
            :Color('ffb7e75f')
            :DisableHitTest()
        self._mass:SetFont(Options.player.font.mass:Raw(), armyViewTextPointSize)



        LayoutFor(self)
            :Width(allyViewWidth)
    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            appearAnimation:Apply(self._mass)
            appearAnimation:Apply(self._energy)
            appearAnimation:Apply(self._faction)

            fadeAnimation:Apply(self._massBtn)
            fadeAnimation:Apply(self._energyBtn)
            fadeAnimation:Apply(self._unitsBtn)
            return true
        elseif event.Type == 'MouseEnter' and not self.isOutOfGame then
            appearAnimation:Apply(self._massBtn)
            appearAnimation:Apply(self._unitsBtn)
            appearAnimation:Apply(self._energyBtn)

            fadeAnimation:Apply(self._mass)
            fadeAnimation:Apply(self._energy)
            fadeAnimation:Apply(self._faction)
            return true
        end

        return false
    end,

    Update = function(self, data, mode)
        ArmyView.Update(self, data)


        if not self.isOutOfGame then
            local resources = data.resources
            if resources then
                if mode == "income" then
                    self._energy:SetText(FormatNumber(resources.energyin.rate * 10))
                    self._mass:SetText(FormatNumber(resources.massin.rate * 10))
                elseif mode == "storage" then
                    self._energy:SetText(FormatNumber(resources.storage.storedEnergy))
                    self._mass:SetText(FormatNumber(resources.storage.storedMass))
                elseif mode == "maxstorage" then
                    self._energy:SetText(FormatNumber(resources.storage.maxEnergy))
                    self._mass:SetText(FormatNumber(resources.storage.maxMass))
                end
            end
        else
            self._energy:SetText("")
            self._mass:SetText("")
        end
    end



}

local lastDataTextOffset = 20
local dataTextOffSet = 40

local dataAnimationSpeed = LayoutHelpers.ScaleNumber(150)

local contractDataAnimation = animationFactory
    :OnStart(function(control, state, nextControl)
        fadeAnimation:Apply(control)
        control._contracted = true
        return { nextControl = nextControl }
    end)
    :OnFrame(function(control, delta, state)
        if control.Right() >= state.nextControl.Right() then
            return true
        end
        control.Right:Set(control.Right() + delta * dataAnimationSpeed)
    end)
    :OnFinish(function(control, state)
        control.Right:Set(state.nextControl.Right)
    end)
    :Create()

local expandDataAnimation = animationFactory
    :OnStart(function(control, state, nextControl, offset)
        appearAnimation:Apply(control)
        control._contracted = false
        return { nextControl = nextControl, offset = offset }
    end)
    :OnFrame(function(control, delta, state)
        if control.Right() <= state.nextControl.Right() - LayoutHelpers.ScaleNumber(state.offset) then
            return true
        end
        control.Right:Set(control.Right() - delta * dataAnimationSpeed)
    end)
    :OnFinish(function(control, state)
        LayoutHelpers.AtRightIn(control, state.nextControl, state.offset)
    end)
    :Create()

local armyViewDataFont = Options.player.font.data:Raw()

local highlightColor = "66686565"

local colorAnimation = UMT.Animation.Factory.Color
    :For(0.3)
    :Create()

ReplayArmyView = Class(ArmyView)
{
    __init = function(self, parent)
        ArmyView.__init(self, parent)

        self._data = {}
        for i = 1, table.getn(checkboxes) do
            self._data[i] = Text(self)
        end
    end,

    _Layout = function(self)
        ArmyView._Layout(self)

        local first
        local dataSize = table.getn(self._data)
        for i = 1, dataSize do
            if i == 1 then
                LayoutFor(self._data[i])
                    :AtRightIn(self._data[i + 1], dataTextOffSet)
                    :AtVerticalCenterIn(self)
                    :DisableHitTest()
                first = self._data[i]
            elseif i == dataSize then
                LayoutFor(self._data[i])
                    :AtRightIn(self, lastDataTextOffset)
                    :AtVerticalCenterIn(self)
                    :DisableHitTest()
            else
                LayoutFor(self._data[i])
                    :AtRightIn(self._data[i + 1], dataTextOffSet)
                    :AtVerticalCenterIn(self)
                    :DisableHitTest()
            end
            self._data[i]:SetFont(armyViewDataFont, armyViewTextPointSize)
            self._data[i]:SetText("0")
            self._data[i]._contracted = false
        end

        LayoutFor(self)
            :Width(function()
                return nameWidth() + LayoutHelpers.ScaleNumber(70 + dataTextOffSet)
                    + self.Right() - first.Right()
            end)

    end,


    Update = function(self, data, setup)
        if data.resources == nil then
            for i, dataText in self._data do
                dataText:SetText("")
            end
            return
        end
        ArmyView.Update(self, data)
        for i, dataText in self._data do
            local checkboxData = checkboxes[i][ setup[i] ]
            local color = checkboxData.nc
            local value, formatFunc = checkboxData.GetData(data)
            formatFunc = formatFunc or FormatNumber
            local text = formatFunc(value)
            dataText:SetText(text)
            dataText:SetColor(color)
        end
    end,

    HandleEvent = function(self, event)

        if event.Type == 'ButtonPress' and
            event.Modifiers.Left and
            not event.Modifiers.Shift and
            not event.Modifiers.Ctrl then
            ConExecute('SetFocusArmy ' .. tostring(self.id - 1))
            return true
        elseif event.Type == 'MouseExit' then
            LayoutFor(self._bg)
                :Color(bgColor)
            --colorAnimation:Apply(self._bg, bgColor())
            return true
        elseif event.Type == 'MouseEnter' then
            LayoutFor(self._bg)
                :Color(highlightColor)
            --colorAnimation:Apply(self._bg, UMT.ColorUtils.ColorMult(bgColor(), 1.4))
            return true
        end

        return false


    end,

    ContractData = function(self, id)
        assert(table.getn(self._data) >= id, "pain")

        if table.getn(self._data) == id then
            local nextControl = self
            local control = self._data[id]

            contractDataAnimation:Apply(control, nextControl)
        else
            local nextControl = self._data[id + 1]
            local control = self._data[id]

            contractDataAnimation:Apply(control, nextControl)
        end

    end,

    ExpandData = function(self, id)
        assert(table.getn(self._data) >= id, "pain")

        if table.getn(self._data) == id then
            local nextControl = self
            local control = self._data[id]

            expandDataAnimation:Apply(control, nextControl, lastDataTextOffset)
        else
            local nextControl = self._data[id + 1]
            local control = self._data[id]

            expandDataAnimation:Apply(control, nextControl, dataTextOffSet)
        end

    end,
}

local LuaQ = UMT.LuaQ

ReplayTeamView = Class(ReplayArmyView)
{
    SetStaticData = function(self, teamId, name, rating, teamColor, armies)
        ReplayArmyView.SetStaticData(self, teamId, name, rating, 0, "ffffffff", teamColor)
        self._armies = armies | LuaQ.toSet
        if self._faction then
            self._faction:Destroy()
            self._faction = nil
        end
    end,


    Update = function(self, playersData, setup)


        for i, dataText in self._data do
            local checkboxData = checkboxes[i][ setup[i] ]
            local color = checkboxData.nc

            local formatFunc
            local value = playersData | LuaQ.sum.keyvalue(function(i, data)
                if not self._armies[i] or data.resources == nil then return 0 end
                local res
                res, formatFunc = checkboxData.GetData(data)
                return res
            end)
            formatFunc = formatFunc or FormatNumber
            local text = formatFunc(value)
            dataText:SetText(text)
            dataText:SetColor(color)
        end

        if not self.isOutOfGame then
            local defeated = self._armies | LuaQ.all(function(i) return playersData[i].Defeated end)
            if defeated then
                self.isOutOfGame = true
                self._name:SetColor(outOfGameColor)
            end
        end

    end,

}
