--#region Header
--#region Upvalues
---@diagnostic disable-next-line:deprecated
local TableGetN = table.getn

--#endregion

--#region Base Lua imports
local UIUtil = import('/lua/ui/uiutil.lua')
local LazyVar = import('/lua/lazyvar.lua').Create
local Tooltip = import("/lua/ui/game/tooltip.lua")

--#endregion

--#region ReUI modules / classes
local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap
local Text = ReUI.UI.Controls.Text
local Animation = ReUI.UI.Animation
--#endregion

--#region Local Modules
local PingAnimation = import("Views/PingAnimation.lua").PingAnimation
local Utils = import("Utils.lua")
local FormatNumber = Utils.FormatNumber
local TextWidth = Utils.TextWidth
local ShareManager = import("ShareManager.lua")

--#endregion

--#region Local Variables
local options = ReUI.Options.Mods["ReUI.Score"]

local checkboxes = import("DataPanelConfig.lua").checkboxes

local alphaAnimationFactory = Animation.Factory.Alpha
local alphaAnimator = Animation.Animator(GetFrame(0))
local animationFactory = Animation.Factory.Base

local armyViewDataFont = options.player.font.data:Raw()

local highlightColor = "66686565"

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


local bgColor = options.player.color.bg:Raw()

local armyViewTextPointSize = 12

local armyViewNameFont = options.player.font.name:Raw()
local focusArmyNameFont = options.player.font.focus:Raw()

nameWidth = LazyVar()
armyViewWidth = LazyVar()
allyViewWidth = LazyVar()

local armyViewHeight = 20
local outOfGameColor = "ffa0a0a0"

local colorAnimation = ReUI.UI.Animation.Factory.Color
    :For(0.3)
    :Create()

local lastDataTextOffset = 20
local dataTextOffSet = 40

local dataAnimationSpeed = 150

local contractDataAnimation = animationFactory
    :OnStart(function(control, state, nextControl, offset)
        fadeAnimation:Apply(control)
        control._contracted = true
        return { nextControl = nextControl, offset = offset }
    end)
    :OnFrame(function(control, delta, state)
        if control.Right() >= state.nextControl.Right() - control.Layouter:ScaleNumber(state.offset) then
            return true
        end
        control.Right:Set(control.Right() + delta * control.Layouter:ScaleNumber(dataAnimationSpeed))
    end)
    :OnFinish(function(control, state)
        control.Layouter(control)
            :AtRightIn(state.nextControl, state.offset)
    end)
    :Create()

local expandDataAnimation = animationFactory
    :OnStart(function(control, state, nextControl, offset)
        appearAnimation:Apply(control)
        control._contracted = false
        return { nextControl = nextControl, offset = offset }
    end)
    :OnFrame(function(control, delta, state)
        if control.Right() <= state.nextControl.Right() - control.Layouter:ScaleNumber(state.offset) then
            return true
        end
        control.Right:Set(control.Right() - delta * control.Layouter:ScaleNumber(dataAnimationSpeed))
    end)
    :OnFinish(function(control, state)
        control.Layouter(control)
            :AtRightIn(state.nextControl, state.offset)
    end)
    :Create()

local LINQ = ReUI.LINQ
local ToSet = LINQ.PairsEnumerator:AsSet():ToTable()

--#endregion
--#endregion

---@alias FactionIconMode
--- | "plain"
--- | "color"

---@class FactionIcon : ReUI.UI.Controls.Bitmap
---@field _mode FactionIconMode
---@field _faction Faction
---@field _color Lazy<Color>
local FactionIcon = ReUI.Core.Class(Bitmap)
{
    ---@param self FactionIcon
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)

        self._faction = -1
        self._mode = "plain"

        self._color = LazyVar "ffffffff"
        self._color.OnDirty = function(var)
            self:SetColorMask(var())
        end
    end,

    ---@param self FactionIcon
    _SetModeTexture = function(self)
        if self._mode == "plain" then
            ---@diagnostic disable-next-line:param-type-mismatch
            self:SetTexture(UIUtil.UIFile(Utils.GetFactionIcon(self._faction)), 0)
        else
            ---@diagnostic disable-next-line:param-type-mismatch
            self:SetTexture(UIUtil.UIFile(Utils.GetWhiteFactionIcon(self._faction)), 0)
        end
    end,

    ---@type Faction
    Faction = ReUI.Core.Property
    {
        get = function(self)
            return self._faction
        end,

        set = function(self, value)
            self._faction = value
            self:_SetModeTexture()
        end
    },

    ---@type Color
    MaskColor = ReUI.Core.Property
    {
        get = function(self)
            return self._color
        end,

        set = function(self, value)
            self._color:Set(value)
        end
    },

    ---@type FactionIconMode
    Mode = ReUI.Core.Property
    {
        get = function(self)
            return self._mode
        end,

        set = function(self, value)
            if self._mode == value then
                return
            end

            self._mode = value
            self:_SetModeTexture()
        end
    }
}


---@class ArmyView : ReUI.UI.Controls.Group
---@field isOutOfGame boolean
---@field id integer
---@field faction Faction
---@field _division string
---@field _bg ReUI.UI.Controls.Bitmap
---@field _color ReUI.UI.Controls.Bitmap
---@field _faction FactionIcon
---@field _div ReUI.UI.Controls.Bitmap
---@field _rating ReUI.UI.Controls.Text
---@field _name ReUI.UI.Controls.Text
---@field _armyColor Lazy<Color>
---@field _teamColor Lazy<Color>
---@field _teamColorBG Lazy<Color>
---@field _plainColor Lazy<Color>
ArmyView = ReUI.Core.Class(Group)
{
    ---inits armyview
    ---@param self ArmyView
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self.parent = parent

        self.id = -1
        self.faction = -1

        self.isOutOfGame = false

        self._armyColor = LazyVar "ffffffff"
        self._teamColor = LazyVar "ffffffff"
        self._teamColorBG = LazyVar "ffffffff"
        self._division = "unlisted"
        self._plainColor = LazyVar "ffffffff"

        self._bg = Bitmap(self)
        self._div = Bitmap(self)
        self._color = Bitmap(self)
        self._faction = FactionIcon(self)
        self._rating = Text(self)
        self._name = Text(self)
    end,

    ---@param self ArmyView
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self._bg)
            :Fill(self)
            :Color(bgColor)
            :DisableHitTest()

        layouter(self._color)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :Right(self.Left)
            :Width(3)
            :Over(self, 5)
            :DisableHitTest()
            :Color(self._teamColorBG)

        layouter(self._faction)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, 4)
            :Width(16)
            :Height(16)
            :Over(self, 10)
            :DisableHitTest()

        layouter(self._div)
            :Width(40)
            :Height(20)
            :AtVerticalCenterIn(self)
            :AtRightIn(self._rating, -1)
            :Over(self, 10)
            :DisableHitTest()
            :Alpha(0)

        layouter(self._rating)
            :AtVerticalCenterIn(self)
            :AnchorToLeft(self, -60)
            :DisableHitTest()
            :Over(self, 10)
            :DropShadow(true)
            :Color(self.ArmyColor)


        layouter(self._name)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, 70)
            :Over(self, 10)
            :DisableHitTest()
            :DropShadow(true)
            :Color(self.PlainColor)


        layouter(self)
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
        self._teamColorBG:Set(teamColor)
        self._division = division

        if division and division ~= "" then

            if division ~= "unlisted" then
                self.Layouter(self._div)
                    :Texture("/textures/divisions/" .. division .. "_medium.png"--[[@as FileName]] , 0)
            else
                self.Layouter(self._div)
                    :Width(20)
                    :Height(20)
                    :AtRightIn(self._rating, -1 + 10)
                    :Texture("/textures/divisions/unlisted.png", 0)
            end
        end
        self._rating:SetText(tostring(rating))
        self._rating:SetFont(options.player.font.rating:Raw(), armyViewTextPointSize)

        self._name:SetText(name)
        self._name:SetClipToWidth(true)
        self._name.Width:Set(nameWidth)

        self:ResetFont()

        self._faction.Faction = faction
    end,

    ResetFont = function(self)
        local font = GetFocusArmy() == self.id and focusArmyNameFont or armyViewNameFont
        self._name:SetFont(font, armyViewTextPointSize)
        nameWidth:Set(
            math.max(
                nameWidth(),
                TextWidth(self._name, self._name:GetText(), font(), armyViewTextPointSize)
            ))
    end,

    ---@type Color
    ArmyColor = ReUI.Core.Property
    {
        get = function(self)
            return self._armyColor
        end,

        set = function(self, value)
            self._armyColor:Set(value)
        end
    },

    ---@type Color
    TeamColor = ReUI.Core.Property
    {
        get = function(self)
            return self._teamColor
        end,

        set = function(self, value)
            self._teamColor:Set(value)
        end
    },

    ---@type Color
    NameColor = ReUI.Core.Property
    {
        ---@param self ArmyView
        ---@param value Color
        set = function(self, value)
            self._name:SetColor(value)
        end
    },

    ---@type Color
    RatingColor = ReUI.Core.Property
    {
        ---@param self ArmyView
        ---@param value Color
        set = function(self, value)
            self._rating:SetColor(value)
        end
    },

    Division = ReUI.Core.Property
    {
        get = function(self)
            return self._division
        end,
    },

    PlainColor = ReUI.Core.Property
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

    ---@param self ArmyView
    ---@param data ArmyScoreData
    Update = function(self, data)
        if not self.isOutOfGame and data.Defeated then
            self:MarkOutOfGame()
        end
    end,

    MarkOutOfGame = function(self)
        self.isOutOfGame = true
        self.ArmyColor = outOfGameColor
        self.PlainColor = outOfGameColor
        self.TeamColor = outOfGameColor
    end,

    ---@param self ArmyView
    ---@param pingData PingData
    DisplayPing = function(self, pingData)
        local ping = PingAnimation(self, pingData.ArrowColor, pingData.Location)
        self.Layouter(ping)
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
AllyView = ReUI.Core.Class(ArmyView)
{
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

    ---@param self AllyView
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        ArmyView.InitLayout(self, layouter)

        layouter(self._unitsBtn)
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

        layouter(self._energyBtn)
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

        layouter(self._massBtn)
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

        layouter(self._energy)
            :AtRightIn(self, 10)
            :AtVerticalCenterIn(self)
            :Color('fff7c70f')
            :Over(self, 10)
            :DisableHitTest()
        self._energy:SetFont(options.player.font.energy:Raw(), armyViewTextPointSize)



        layouter(self._mass)
            :AtRightIn(self, 50)
            :AtVerticalCenterIn(self)
            :Color('ffb7e75f')
            :Over(self, 10)
            :DisableHitTest()
        self._mass:SetFont(options.player.font.mass:Raw(), armyViewTextPointSize)



        layouter(self)
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

        if mode == "full" then
            self._energy:SetText(("%s / %s +%s"):format(
                FormatNumber(resources.storage.storedEnergy),
                FormatNumber(resources.storage.maxEnergy),
                FormatNumber(resources.energyin.rate * 10)
            ))
            self._mass:SetText(("%s / %s +%s"):format(
                FormatNumber(resources.storage.storedMass),
                FormatNumber(resources.storage.maxMass),
                FormatNumber(resources.massin.rate * 10)
            ))
        elseif mode == "income" then
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

---@class ReplayArmyView : ArmyView
---@field _data ReUI.UI.Controls.Text[]
ReplayArmyView = ReUI.Core.Class(ArmyView)
{
    __init = function(self, parent)
        ArmyView.__init(self, parent)

        self._data = {}
        for i = 1, TableGetN(checkboxes) do
            self._data[i] = Text(self)
        end
    end,

    ---@param self ReplayArmyView
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        ArmyView.InitLayout(self, layouter)

        local first
        local dataSize = TableGetN(self._data)
        for i = 1, dataSize do
            local dataText = self._data[i]
            local nextText = self._data[i + 1]
            if i == 1 then
                layouter(dataText)
                    :AtRightIn(nextText, dataTextOffSet)
                first = dataText
            elseif i == dataSize then
                layouter(dataText)
                    :AtRightIn(self, lastDataTextOffset)
            else
                layouter(dataText)
                    :AtRightIn(nextText, dataTextOffSet)
            end
            layouter(dataText)
                :AtVerticalCenterIn(self)
                :Over(self, 15)
                :DisableHitTest()
                :DropShadow(true)
            dataText:SetFont(armyViewDataFont, armyViewTextPointSize)
            dataText:SetText("0")
            dataText._contracted = false
        end

        layouter(self)
            :Width(layouter:Sum(
                layouter:Sum(nameWidth, 70 + dataTextOffSet),
                layouter:Diff(self.Right, first.Right)
            ))
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
            self.Layouter(self._bg)
                :Color(bgColor)
            --colorAnimation:Apply(self._bg, bgColor())
            return true
        elseif event.Type == 'MouseEnter' then
            self.Layouter(self._bg)
                :Color(highlightColor)
            --colorAnimation:Apply(self._bg, UMT.ColorUtils.ColorMult(bgColor(), 1.4))
            return true
        end

        return false


    end,

    ContractData = function(self, id)
        assert(TableGetN(self._data) >= id, "pain")

        if TableGetN(self._data) == id then
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
        assert(TableGetN(self._data) >= id, "pain")

        if TableGetN(self._data) == id then
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

---@class ReplayTeamView : ReplayArmyView
---@field _armies table<integer, true>
---@field _teamName string
---@field _aliveCount integer
ReplayTeamView = ReUI.Core.Class(ReplayArmyView)
{
    ---@param self ReplayTeamView
    ---@param teamId integer
    ---@param name string
    ---@param rating number
    ---@param teamColor Color
    ---@param armies table<integer, true>
    SetStaticData = function(self, teamId, name, rating, teamColor, armies)
        ReplayArmyView.SetStaticData(self, teamId, name, rating, 0, "ffffffff", teamColor, "")

        self._teamName = name
        self.id = teamId
        self._armies = armies
        self._faction:SetAlpha(0)

        self:SetAliveCount(table.getsize(armies)--[[@as integer]] )
    end,

    ---@param self ReplayTeamView
    ---@param playersData ArmyScoreData[]
    ---@param setup number[]
    Update = function(self, playersData, setup)
        for i, dataText in self._data do
            local checkboxData = checkboxes[i][ setup[i] ]
            local color = checkboxData.nc

            local formatFunc
            local value = LINQ.Enumerate(playersData)
                :Where(function(data, id)
                    return self._armies[id] and data.resources ~= nil
                end)
                :Select(function(data)
                    local res
                    res, formatFunc = checkboxData.GetData(data)
                    return res
                end)
                :Sum()

            formatFunc = formatFunc or FormatNumber
            local text = formatFunc(value)
            dataText:SetText(text)
            dataText:SetColor(color)
        end

        if self.isOutOfGame then return end

        local alive = LINQ.Enumerate(self._armies, next)
            :Count(function(_, i) return not playersData[i].Defeated end)

        self:SetAliveCount(alive)

        if alive > 0 then return end

        ArmyView.MarkOutOfGame(self)
    end,

    ---@param self ReplayTeamView
    ---@param n integer
    SetAliveCount = function(self, n)
        if self._aliveCount == n then
            return
        end

        self._aliveCount = n
        local total = table.getsize(self._armies)
        self._name:SetText(("%s (%d / %d)"):format(self._teamName, n, total))
    end
}
