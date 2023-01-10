
function Main(isReplay)
    if exists("/mods/UMT/mod_info.lua") and import("/mods/UMT/mod_info.lua").version >= 6 then
        import("options.lua").Main(isReplay)
        import("engineers.lua").Init(isReplay)
    else
        ForkThread(function()
            WaitSeconds(4)
            print("Idle Engineers Light requires UI mod tools version 6 and higher!!!")
        end)
        return
    end
end
