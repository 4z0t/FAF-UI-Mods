ReUI.Require
{
    "ReUI.Core >= 1.5.0",
    "ReUI.LINQ >= 1.0.0",
    "ReUI.UI.Views >= 1.0.0"
}

function Main(isReplay)
    local _rawget = rawget
    local _rawset = rawset
    local _getmetatable = getmetatable
    local _setmetatable = setmetatable
    local _type = type

    local isLoadedMains = false
    ---Main functions of Mods' Options files
    ---@type table<string, fun()>
    local optionsMainFuncs = {}

    ---#region Options Loading

    local OptionVar = import("Modules/OptionVar.lua").Create

    local OptValueMetaTable = {}
    local function IsOpt(value)
        return OptValueMetaTable == _getmetatable(value)
    end

    ---@generic T
    ---@param value T
    ---@return OptionVar
    local function MakeOpt(value)
        return _setmetatable({ value = value }, OptValueMetaTable)
    end

    local function LoadOptions(values, modName, prefix)
        local options = {}

        for optName, defaultValue in values do
            local opt = prefix and (prefix .. "." .. optName) or optName
            if _type(defaultValue) == "table" then
                if IsOpt(defaultValue) then
                    LOG(("ReUI.Options: loading option '%s':'%s'"):format(modName, opt))
                    options[optName] = OptionVar(modName, opt, defaultValue.value)
                else
                    options[optName] = LoadOptions(defaultValue, modName, opt)
                end
            else
                LOG(("ReUI.Options: loading option '%s':'%s'"):format(modName, opt))
                options[optName] = OptionVar(modName, opt, defaultValue)
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

    return {
        Builder = {
            AddOptions = OptionsSelector.AddOptions,
            Splitter = OptionsSelector.Splitter,
            Column = OptionsSelector.Column,
            Title = OptionsSelector.Title,
            Color = OptionsSelector.Color,
            Filter = OptionsSelector.Filter,
            Slider = OptionsSelector.Slider,
            TextEdit = OptionsSelector.TextEdit,
            ColorSlider = OptionsSelector.ColorSlider,
            Strings = OptionsSelector.Strings,
            Fonts = OptionsSelector.Fonts,
        },
        Mods = _setmetatable({}, ModsOptionsMetaTable),
        Opt = MakeOpt,
    }
end
