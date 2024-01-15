function main(isReplay)
    if exists('/mods/UMT/mod_info.lua') and import('/mods/UMT/mod_info.lua').version >= 4 then
        local UIUtil = import('/lua/ui/uiutil.lua')


        local OptionsUtils = UMT.Options
        local OptionVarCreate = import("/mods/UMT/modules/OptionVar.lua").Create

        local Update = import("update.lua")
        local Exp = import('exp.lua')
        local Nuke = import('nuke.lua')
        local Smd = import('smd.lua')
        local Data = import('data.lua')
        if not isReplay then
        end
        local modName = "TIS"

        local expOptions = {
            overlay = OptionVarCreate(modName, "expOverlay", true),
            eta = {
                offsetX = OptionVarCreate(modName, 'EHOffsetCountdown', 0),
                offsetY = OptionVarCreate(modName, 'EVOffsetCountdown', -13)
            },
            progress = {
                offsetX = OptionVarCreate(modName, 'EHOffsetProgress', 0),
                offsetY = OptionVarCreate(modName, 'EVOffsetProgress', 15)
            }
        }

        local siloOptions = {
            overlay = OptionVarCreate(modName, "siloOverlay", true),
            eta = {
                offsetX = OptionVarCreate(modName, 'NHOffsetCountdown', 0),
                offsetY = OptionVarCreate(modName, 'NVOffsetCountdown', -13)
            },
            progress = {
                offsetX = OptionVarCreate(modName, 'NHOffsetProgress', 0),
                offsetY = OptionVarCreate(modName, 'NVOffsetProgress', 15)
            },
            count = {
                offsetX = OptionVarCreate(modName, 'NHOffsetCount', 0),
                offsetY = OptionVarCreate(modName, 'NVOffsetCount', 0)
            }
        }

        Data.init(isReplay)
        Exp.init(isReplay, expOptions)
        Nuke.init(isReplay, siloOptions)
        Update.init(isReplay)

        OptionsUtils.AddOptions('TIS', 'TeamInfo Share',
            { OptionsUtils.Filter('Show exp ovelays', expOptions.overlay),
                OptionsUtils.Filter('Show nukes and smds ovelays', siloOptions.overlay),
                OptionsUtils.Title('Nukes and smds', 18, nil, UIUtil.factionTextColor),
                OptionsUtils.Title('Countdown', 12),
                OptionsUtils.Slider('Vertical offset', -20, 20, 1, siloOptions.eta.offsetY),
                OptionsUtils.Slider('Horizonal offset', -20, 20, 1, siloOptions.eta.offsetX),
                OptionsUtils.Title('Progress', 12),
                OptionsUtils.Slider('Vertical offset', -20, 20, 1, siloOptions.progress.offsetY),
                OptionsUtils.Slider('Horizonal offset', -20, 20, 1, siloOptions.progress.offsetX),
                OptionsUtils.Title('Silo count', 12),
                OptionsUtils.Slider('Vertical offset', -20, 20, 1, siloOptions.count.offsetY),
                OptionsUtils.Slider('Horizonal offset', -20, 20, 1, siloOptions.count.offsetX),
                OptionsUtils.Title('EXPs', 18, nil, UIUtil.factionTextColor), OptionsUtils.Title('Countdown', 12),
                OptionsUtils.Slider('Vertical offset', -20, 20, 1, expOptions.eta.offsetY),
                OptionsUtils.Slider('Horizonal offset', -20, 20, 1, expOptions.eta.offsetX),
                OptionsUtils.Title('Progress', 12),
                OptionsUtils.Slider('Vertical offset', -20, 20, 1, expOptions.progress.offsetY),
                OptionsUtils.Slider('Horizonal offset', -20, 20, 1, expOptions.progress.offsetX) })

    else
        ForkThread(function()
            WaitSeconds(4)
            print("TeamInfo Share requires UI mod tools version 4 and higher!!!")
        end)
        return
    end
end
