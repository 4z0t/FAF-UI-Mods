function main(isReplay)
    if exists("/mods/UMT/mod_info.lua") and import("/mods/UMT/mod_info.lua").version >= 4 then
        import("engineers.lua").init(isReplay)
    else
        ForkThread(function()
            WaitSeconds(4)
            print("Idle Engineers Light requires UI mod tools version 4 and higher!!!")
        end)
        return
    end
end
