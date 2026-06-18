ReUI.Require
{
    "ReUI.Core >= 1.5.0",
    "ReUI.Core.Events >= 1.0.0",
    "ReUI.LINQ >= 1.0.0",
    "ReUI.UI.Views >= 1.0.0"
}

function Main(isReplay)
    local _rawget = rawget
    local _rawset = rawset
    local _type = type

    local Prefs = import("/lua/user/prefs.lua")


    ---@alias ReUI.Options.OptionValue<T> (fun():T)|ReUI.Options.ReactiveOption


    local isLoadedMains = false
    ---Main functions of Mods' Options files
    ---@type table<string, fun()>
    local optionsMainFuncs = {}

    ---#region Options Loading

    local OptionRef        = import("Modules/OptionRef.lua").OptionRef
    local ReactiveOption   = import("Modules/ReactiveOption.lua").ReactiveOption
    local DeprecatedOption = import("Modules/ReactiveOption.lua").DeprecatedOption

    local function FormatName(name)
        return (name:gsub("[^A-Za-z0-9]+", "_"))
    end

    ---@param ref ReUI.Options.OptionRef
    ---@param modName string
    ---@param optionName string
    ---@param default any
    ---@return any
    local function HandleOldPath(ref, modName, optionName, default)
        local value = ref:Get()
        if value ~= nil then
            return value
        end

        modName = FormatName(modName)
        optionName = FormatName(optionName)

        local modOptionsTable = Prefs.GetFromCurrentProfile(modName)
        value = modOptionsTable and modOptionsTable[optionName]

        if value == nil then
            value = default
        end

        ref:Set(value)
        return value
    end

    ---@class OptionPrototype
    ---@field _value any
    ---@field _class fun(ref:ReUI.Options.OptionRef, defaultValue:any, valueType?:any):(ReUI.Options.ReactiveOption)
    ---@field _type any?
    local OptionPrototype = ReUI.Core.Class()
    {
        __option = true,

        ---@param self OptionPrototype
        __init = function(self, value, class, type)
            self._value = value
            self._class = class
            self._type = type
        end,

        ---@param self OptionPrototype
        ---@return ReUI.Options.ReactiveOption
        Create = function(self, modName, optionName)
            local default = self._value

            if default == nil then
                error(("Attempt to set option %s:%s to nil by default, don't do that!"):format(modName, optionName))
            end

            ---@type ReUI.Options.OptionRef
            local ref = OptionRef { "UIModsOptions", modName, optionName }

            default = HandleOldPath(ref, modName, optionName, default)

            return self._class(ref, default, self._type)
        end,
    }

    ---Creates OptionVar from value when used within `ReUI.Options.Mods`.
    ---Example:
    ---```lua
    ---ReUI.Options.Mods["MyMod"] = {
    ---    boolOpt = Opt(true),
    ---    numberOpt = Opt(10),
    ---    stringOpt = Opt("ffff00ff"),
    ---    nestedTable = {
    ---         otherOpt = Opt(10),
    ---         ...
    ---   }
    ---}
    ---```
    ---@generic T
    ---@param value T
    ---@return DeprecatedOption
    local function MakeDeprecatedOpt(value)
        return OptionPrototype(value, DeprecatedOption)
    end

    ---Creates ReactiveOption from value when used within `ReUI.Options.Mods`.
    ---Example:
    ---```lua
    ---ReUI.Options.Mods["MyMod"] = {
    ---    boolOpt = OptionValue(true),
    ---    numberOpt = OptionValue(10),
    ---    stringOpt = OptionValue("ffff00ff"),
    ---    nestedTable = {
    ---         otherOpt = OptionValue(10),
    ---         ...
    ---   }
    ---}
    ---```
    ---@generic T
    ---@param defaultValue T
    ---@return ReUI.Options.OptionValue<T>
    local function OptionValue(defaultValue)
        return OptionPrototype(defaultValue, ReactiveOption)
    end

    local function LoadOptions(values, modName, prefix)
        local options = {}

        for optName, defaultValue in values do
            local opt = prefix and (prefix .. "." .. optName) or optName

            if _type(defaultValue) ~= "table" then
                error(("ReUI.Options: '%s':'%s' has no option specifier"):format(modName, opt))
            end

            if defaultValue.__option then
                ---@cast defaultValue OptionPrototype
                LOG(("ReUI.Options: loading option '%s':'%s'"):format(modName, opt))
                options[optName] = defaultValue:Create(modName, opt)
            else
                options[optName] = LoadOptions(defaultValue, modName, opt)
            end
        end

        return options
    end

    ---@param modName string
    local function LoadOptionsFile(modsOptions, modName)
        LOG(("ReUI.Options: Loading options of mod '%s'"):format(modName))

        ---@type FileName
        local path
        local module = ReUI.Get(modName)
        if module then
            path = module.Path .. "Options.lua"
        else
            path = string.format("/mods/%s/Options.lua", modName) --[[@as FileName]]
        end

        ---@type fun()
        local mainF = import(path).Main
        optionsMainFuncs[modName] = mainF

        local options = _rawget(modsOptions, modName)
        if not options then
            WARN(("ReUI.Options: Error trying to load options of mod '%s'"):format(modName))
            return false
        end
        return true
    end

    local ModsOptionsMetaTable = {
        __newindex = function(self, key, value)
            local options = LoadOptions(value, key)
            _rawset(self, key, options)
        end,

        __index = function(self, key)
            if LoadOptionsFile(self, key) then
                return _rawget(self, key)
            end
            error(("ReUI.Options: No options for mod '%s'"):format(key))
        end
    }
    ---#endregion

    local OptionsSelector = import("Modules/Selector.lua")

    ReUI.Core.OnPreCreateUI(function()
        import("/lua/ui/game/tabs.lua").AddToMenu
        {
            action = "ReUI.Options",
            label = "ReUI Options",
            tooltip = "ReUI Options",
            func = function()
                if not isLoadedMains then
                    for modName, mainF in pairs(optionsMainFuncs) do
                        local success, err = pcall(mainF, isReplay)
                        if not success then
                            LOG(("ReUI.Options: Error loading options of mod '%s'"):format(modName))
                            LOG(err)
                        end
                    end
                    isLoadedMains = true
                end
                OptionsSelector.Main()
            end
        }
    end)

    ---@class ReUI.Options : ReUI.Module
    return {
        ---@deprecated
        Builder = {
            AddOptions  = OptionsSelector.AddOptions,
            Splitter    = OptionsSelector.Splitter,
            Column      = OptionsSelector.Column,
            Title       = OptionsSelector.Title,
            Color       = OptionsSelector.Color,
            Filter      = OptionsSelector.Filter,
            Slider      = OptionsSelector.Slider,
            TextEdit    = OptionsSelector.TextEdit,
            ColorSlider = OptionsSelector.ColorSlider,
            Strings     = OptionsSelector.Strings,
            Fonts       = OptionsSelector.Fonts,
        },

        ---Table with options provided by mods.
        ---
        ---Whenever this table is indexed it will try to find options file within mod's folder.
        ---```lua
        ---local myOptions = ReUI.Options.Mods["MyMod"]
        ---```
        ---Will look for `/mods/MyMod/Options.lua` file where you assign options
        ---for your mod.
        ---
        ---This file also must have `Main` function where you setup options for being displayed in
        ---options window. It will be called once user accesses options window.
        ---@type table<string, table>
        Mods = setmetatable({}, ModsOptionsMetaTable),

        ---@deprecated
        Opt = MakeDeprecatedOpt,

        OptionValue = OptionValue,

        ReactiveOption = ReactiveOption,
        OptionRef      = OptionRef,
    }
end
