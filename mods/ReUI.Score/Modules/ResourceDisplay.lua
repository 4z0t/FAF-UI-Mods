local IsKeyDown = IsKeyDown
local Utils = import("Utils.lua")
local FormatNumber = Utils.FormatNumber

---@class IResourceDisplay
IResourceDisplay = Class()
{
    Width = 0,

    ---@param self IResourceDisplay
    ---@param scoreboard ReUI.Score.ScoreBoard
    Update = function(self, scoreboard)
        return false
    end,

    ---@param self IResourceDisplay
    ---@param resources ResourcesStats
    ---@return string mass
    ---@return string energy
    GetResourceStrings = function(self, resources)
        return "", ""
    end,

    ---@param self IResourceDisplay
    ---@param allyView AllyView
    Apply = function(self, allyView)
    end,
}

---@class DefaultResourceDisplay : IResourceDisplay
---@field _mode "income" | "storage" | "maxstorage"
DefaultResourceDisplay = Class(IResourceDisplay)
{
    Width = 160,

    ---@param self DefaultResourceDisplay
    __init = function(self)
        self._mode = "income"
    end,

    ---@param self DefaultResourceDisplay
    ---@param scoreboard ReUI.Score.ScoreBoard
    Update = function(self, scoreboard)
        local mode = self._mode
        local isCtrl = IsKeyDown("control")

        if not isCtrl and scoreboard.isHovered and mode ~= "storage" then
            self._mode = "storage"
            return true
        elseif isCtrl and mode ~= "maxstorage" then
            self._mode = "maxstorage"
            return true
        elseif not isCtrl and not scoreboard.isHovered and mode ~= "income" then
            self._mode = "income"
            return true
        end

        return false
    end,

    ---@param self DefaultResourceDisplay
    ---@param resources ResourcesStats
    ---@return string mass
    ---@return string energy
    GetResourceStrings = function(self, resources)
        local mode = self._mode
        if mode == "income" then
            return FormatNumber(resources.massin.rate * 10), FormatNumber(resources.energyin.rate * 10)
        elseif mode == "storage" then
            return FormatNumber(resources.storage.storedMass), FormatNumber(resources.storage.storedEnergy)
        elseif mode == "maxstorage" then
            return FormatNumber(resources.storage.maxMass), FormatNumber(resources.storage.maxEnergy)
        end
        return "", ""
    end,

    ---@param self DefaultResourceDisplay
    ---@param allyView AllyView
    Apply = function(self, allyView)
        local layouter = allyView.Layouter
        layouter(allyView._massBtn)
            :Width(35)
        layouter(allyView._energyBtn)
            :Width(35)
        layouter(allyView._mass)
            :AtRightIn(allyView, 50)
    end,
}


---@class FullResourceDisplay : IResourceDisplay
FullResourceDisplay = Class(IResourceDisplay)
{
    Width = 260,

    ---@param self FullResourceDisplay
    ---@param resources ResourcesStats
    ---@return string mass
    ---@return string energy
    GetResourceStrings = function(self, resources)
        return ("%s / %s +%s"):format(
            FormatNumber(resources.storage.storedMass),
            FormatNumber(resources.storage.maxMass),
            FormatNumber(resources.massin.rate * 10)
        ), ("%s / %s +%s"):format(
            FormatNumber(resources.storage.storedEnergy),
            FormatNumber(resources.storage.maxEnergy),
            FormatNumber(resources.energyin.rate * 10)
        )
    end,

    ---@param self FullResourceDisplay
    ---@param allyView AllyView
    Apply = function(self, allyView)
        local layouter = allyView.Layouter
        layouter(allyView._massBtn)
            :Width(85)
        layouter(allyView._energyBtn)
            :Width(85)
        layouter(allyView._mass)
            :AtRightIn(allyView, 110)
    end,
}

---@class PairResourceDisplay : IResourceDisplay
---@field _mode "income" | "storage"
PairResourceDisplay = Class(IResourceDisplay)
{
    Width = 220,

    ---@param self DefaultResourceDisplay
    __init = function(self)
        self._mode = "income"
    end,

    ---@param self PairResourceDisplay
    ---@param scoreboard ReUI.Score.ScoreBoard
    Update = function(self, scoreboard)
        local mode = self._mode
        local isCtrl = IsKeyDown("control")

        if isCtrl and mode ~= "storage" then
            self._mode = "storage"
            return true
        elseif not isCtrl and mode ~= "income" then
            self._mode = "income"
            return true
        end

        return false
    end,

    ---@param self PairResourceDisplay
    ---@param resources ResourcesStats
    ---@return string mass
    ---@return string energy
    GetResourceStrings = function(self, resources)
        local mode = self._mode
        if mode == "income" then
            return ("+%s | %s"):format(
                FormatNumber(resources.massin.rate * 10),
                FormatNumber(resources.storage.storedMass)
            ), ("+%s | %s"):format(
                FormatNumber(resources.energyin.rate * 10),
                FormatNumber(resources.storage.storedEnergy)
            )
        elseif mode == "storage" then
            return ("%s / %s"):format(
                FormatNumber(resources.storage.storedMass),
                FormatNumber(resources.storage.maxMass)
            ), ("%s / %s"):format(
                FormatNumber(resources.storage.storedEnergy),
                FormatNumber(resources.storage.maxEnergy)
            )
        end
        return "", ""
    end,

    ---@param self PairResourceDisplay
    ---@param allyView AllyView
    Apply = function(self, allyView)
        local layouter = allyView.Layouter
        layouter(allyView._massBtn)
            :Width(65)
        layouter(allyView._energyBtn)
            :Width(65)
        layouter(allyView._mass)
            :AtRightIn(allyView, 90)
    end,
}
