local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LazyVar = import('/lua/lazyvar.lua').Create
local Tooltip = import("/lua/ui/game/tooltip.lua")
local ColorUtils = UMT.ColorUtils

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

local armyViewNameFont = Options.player.font.name:Raw()
local focusArmyNameFont = Options.player.font.focus:Raw()

minNameWidth = LayoutHelpers.ScaleNumber(75)
nameWidth = LazyVar(minNameWidth)
armyViewWidth = LazyVar()
armyViewWidth:Set(function() return nameWidth() + LayoutHelpers.ScaleNumber(80) end)
allyViewWidth = LazyVar()
allyViewWidth:Set(function() return nameWidth() + LayoutHelpers.ScaleNumber(160) end)

local armyViewHeight = 20
local outOfGameColor = "ffa0a0a0"

---@class ArmyView : Group
---@field isOutOfGame boolean
---@field id integer
---@field _bg Bitmap
---@field _color Bitmap
---@field _faction Bitmap
---@field _div Bitmap
---@field _rating Text
---@field _name Text
---@field _armyColor LazyVar<Color>
---@field _teamColor LazyVar<Color>
---@field _division string
---@field _plainColor LazyVar<Color>
ArmyView = UMT.Class(Group)
{
    ---inits armyview
    ---@param self ArmyView
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent

        self.id = -1
        self.isOutOfGame = false


        self._armyColor = LazyVar "ffffffff"
        self._teamColor = LazyVar "ffffffff"
        self._division = "unlisted"
        self._plainColor = LazyVar "ffffffff"



        self._bg = Bitmap(self)
        self._div = Bitmap(self)
        self._color = Bitmap(self)
        self._faction = Bitmap(self)
        self._rating = Text(self)
        self._name = Text(self)
    end,

    __post_init = function(self)
        self:_Layout()
    end,

    ---Layouts ArmyView
    ---@param self ArmyView
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
            :Over(self, 5)
            :DisableHitTest()
            :Color(self.TeamColor)

        LayoutFor(self._faction)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, 4)
            :Over(self, 10)
            :DisableHitTest()

        LayoutFor(self._div)
            :Width(40)
            :Height(20)
            :AtVerticalCenterIn(self)
            :AtRightIn(self._rating, -1)
            :Over(self, 10)
            :DisableHitTest()
            :Alpha(0)

        LayoutFor(self._rating)
            :AtVerticalCenterIn(self)
            :AnchorToLeft(self, -60)
            :DisableHitTest()
            :Over(self, 10)
            :DropShadow(true)
            :Color(self.ArmyColor)


        LayoutFor(self._name)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, 70)
            :Over(self, 10)
            :DisableHitTest()
            :DropShadow(true)
            :Color(self.PlainColor)


        LayoutFor(self)
            :Width(armyViewWidth)
            :Height(armyViewHeight)
    end,

    ---Sets static data for view
    ---@param self ArmyView
    ---@param armyId integer
    ---@param name string
    ---@param rating number
    ---@param faction Faction
    ---@param armyColor Color
    ---@param teamColor Color
    SetStaticData = function(self, armyId, name, rating, faction, armyColor, teamColor, division)
        self.id = armyId
        self.ArmyColor = armyColor
        self.TeamColor = teamColor
        self._division = division

        if division and division ~= "" then

            if division ~= "unlisted" then
                LayoutFor(self._div)
                    :Texture("/textures/divisions/" .. division .. "_medium.png", 0)
            else
                LayoutFor(self._div)
                    :Width(20)
                    :Height(20)
                    :AtRightIn(self._rating, -1 + 10)
                    :Texture("/textures/divisions/unlisted.png", 0)
            end
        end
        self._rating:SetText(tostring(rating))
        self._rating:SetFont(Options.player.font.rating:Raw(), armyViewTextPointSize)

        self._name:SetText(name)
        self._name:SetClipToWidth(true)
        self._name.Width:Set(nameWidth)

        local font = GetFocusArmy() == armyId and focusArmyNameFont or armyViewNameFont
        nameWidth:Set(math.max(nameWidth(), TextWidth(name, font(), armyViewTextPointSize)))
        self._name:SetFont(font, armyViewTextPointSize)

        self._faction:SetTexture(UIUtil.UIFile(Utils.GetSmallFactionIcon(faction)), 0)
    end,

    ---@type Color
    ArmyColor = UMT.Property
    {
        get = function(self)
            return self._armyColor
        end,

        set = function(self, value)
            self._armyColor:Set(value)
        end
    },

    ---@type Color
    TeamColor = UMT.Property
    {
        get = function(self)
            return self._teamColor
        end,

        set = function(self, value)
            self._teamColor:Set(value)
        end
    },

    ---@type Color
    NameColor = UMT.Property
    {
        ---@param self ArmyView
        ---@param value Color
        set = function(self, value)
            self._name:SetColor(value)
        end
    },

    ---@type Color
    RatingColor = UMT.Property
    {
        ---@param self ArmyView
        ---@param value Color
        set = function(self, value)
            self._rating:SetColor(value)
        end
    },

    Division = UMT.Property
    {
        get = function(self)
            return self._division
        end,
    },

    PlainColor = UMT.Property
    {
        get = function(self)
            return self._plainColor
        end,

        ---@param self ArmyView
        ---@param value Color
        set = function(self, value)
            self._plainColor:Set(value)
        end
    },


    Update = function(self, data)
        if not self.isOutOfGame and data.Defeated then
            self:MarkOutOfGame()
        end
    end,

    MarkOutOfGame = function(self)
        self.isOutOfGame = true
        self.ArmyColor = outOfGameColor
        self.PlainColor = outOfGameColor
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



---@class AllyView : ArmyView
---@field isAlly boolean
---@field _mass Text
---@field _energy Text
---@field _massBtn Bitmap
---@field _energyBtn Bitmap
---@field _unitsBtn Bitmap
AllyView = UMT.Class(ArmyView)
{
    ---comment
    ---@param self AllyView
    ---@param parent Control
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
            :Over(self, 15)
            :EnableHitTest()
            :Alpha(0)

        Tooltip.AddControlTooltipManual(self._unitsBtn,
            "",
            [[By left click gives selected units to this ally.
        By right click requests engineer from this ally.
        ]]   ,
            0.5
        )

        LayoutFor(self._energyBtn)
            :Right(self._energy.Right)
            :AtVerticalCenterIn(self)
            :Width(35)
            :Height(self.Height)
            :Over(self, 15)
            :EnableHitTest()
            :Alpha(0)

        Tooltip.AddControlTooltipManual(self._energyBtn,
            "",
            [[By left click gives 25% energy to this ally.
        By Shift + left click gives 50% energy to this ally.
        By Ctrl + left click gives all energy to this ally.
        By right click requests energy from this ally.
        ]]   ,
            0.5
        )

        LayoutFor(self._massBtn)
            :Right(self._mass.Right)
            :AtVerticalCenterIn(self)
            :Width(35)
            :Height(self.Height)
            :Over(self, 15)
            :EnableHitTest()
            :Alpha(0)

        Tooltip.AddControlTooltipManual(self._massBtn,
            "",
            [[By left click gives 25% mass to this ally.
        By Shift + left click gives 50% mass to this ally.
        By Ctrl + left click gives all mass to this ally.
        By right click requests mass from this ally.
        ]]   ,
            0.5
        )

        LayoutFor(self._energy)
            :AtRightIn(self, 10)
            :AtVerticalCenterIn(self)
            :Color('fff7c70f')
            :Over(self, 10)
            :DisableHitTest()
        self._energy:SetFont(Options.player.font.energy:Raw(), armyViewTextPointSize)



        LayoutFor(self._mass)
            :AtRightIn(self, 50)
            :AtVerticalCenterIn(self)
            :Color('ffb7e75f')
            :Over(self, 10)
            :DisableHitTest()
        self._mass:SetFont(Options.player.font.mass:Raw(), armyViewTextPointSize)



        LayoutFor(self)
            :Width(allyViewWidth)
    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            appearAnimation:Apply(self._faction)
            fadeAnimation:Apply(self._unitsBtn)
        elseif event.Type == 'MouseEnter' and not self.isOutOfGame then
            appearAnimation:Apply(self._unitsBtn)
            fadeAnimation:Apply(self._faction)
        end
        return false
    end,

    Update = function(self, data, mode)
        ArmyView.Update(self, data)

        if self.isOutOfGame then return end

        local resources = data.resources
        if not resources then return end

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
    end,

    MarkOutOfGame = function(self)
        ArmyView.MarkOutOfGame(self)
        self._energy:SetText("")
        self._mass:SetText("")
        self._massBtn:DisableHitTest()
        self._energyBtn:DisableHitTest()
        self._unitsBtn:DisableHitTest()
    end,



}

local lastDataTextOffset = 20
local dataTextOffSet = 40

local dataAnimationSpeed = LayoutHelpers.ScaleNumber(150)

local contractDataAnimation = animationFactory
    :OnStart(function(control, state, nextControl, offset)
        fadeAnimation:Apply(control)
        control._contracted = true
        return { nextControl = nextControl, offset = offset }
    end)
    :OnFrame(function(control, delta, state)
        if control.Right() >= state.nextControl.Right() - LayoutHelpers.ScaleNumber(state.offset) then
            return true
        end
        control.Right:Set(control.Right() + delta * dataAnimationSpeed)
    end)
    :OnFinish(function(control, state)
        LayoutHelpers.AtRightIn(control, state.nextControl, state.offset)
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

ReplayArmyView = UMT.Class(ArmyView)
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
                first = self._data[i]
            elseif i == dataSize then
                LayoutFor(self._data[i])
                    :AtRightIn(self, lastDataTextOffset)
            else
                LayoutFor(self._data[i])
                    :AtRightIn(self._data[i + 1], dataTextOffSet)
            end
            LayoutFor(self._data[i])
                :AtVerticalCenterIn(self)
                :Over(self, 15)
                :DisableHitTest()
                :DropShadow(true)
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
        ArmyView.Update(self, data)
        if data.resources == nil then
            for i, dataText in self._data do
                dataText:SetText("")
            end
            return
        end
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

            contractDataAnimation:Apply(control, nextControl, lastDataTextOffset - dataTextOffSet)
        else
            local nextControl = self._data[id + 1]
            local control = self._data[id]

            contractDataAnimation:Apply(control, nextControl, 0)
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

ReplayTeamView = UMT.Class(ReplayArmyView)
{
    SetStaticData = function(self, teamId, name, rating, teamColor, armies)
        ReplayArmyView.SetStaticData(self, false, name, rating, 0, "ffffffff", teamColor, "")
        self.id = teamId
        self._armies = armies | LuaQ.toSet
        self._faction:SetAlpha(0)
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

        if self.isOutOfGame then return end

        local defeated = self._armies | LuaQ.all(function(i) return playersData[i].Defeated end)

        if not defeated then return end

        ArmyView.MarkOutOfGame(self)
    end,

}
