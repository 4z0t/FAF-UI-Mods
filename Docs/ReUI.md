# ReUI

ReUI is a powerful framework for creating UI mods for Supreme Commander: Forged Alliance Forever. And this guide will show you the ropes of using it!

## Setup

ReUI hardly relies on intellisence, thus it is best to setup it properly before using it.
For development in FAF community we use [VSCode](https://code.visualstudio.com/)
and [Extension specific for FAF game development](https://github.com/FAForever/fa-lua-vscode-extension/releases).

Once you downloaded installed VSCode and extension you need to point out paths for extension to work:

### **.vscode/settings.json**

```json
{
    "Lua.runtime.version": "Lua 5.1",
    "Lua.runtime.path": [
        "?.lua",
        "?/init.lua",
        "/?"
    ],
    "Lua.completion.showWord": "Disable",
    "Lua.runtime.special": {
        "import": "require",
        "doscript": "require",
    },
    "Lua.runtime.nonstandardSymbol": [
        "continue",
    ],
    "Lua.completion.requireSeparator": "/",
    "Lua.runtime.exportEnvDefault": true,
    "Lua.runtime.plugin": "${3rd}/fa/plugin.lua",
    "Lua.diagnostics.globals": [
        "moho",
        "ScenarioInfo"
    ],
    "Lua.workspace.library": [
        // Here you list paths to FA repo and folder with ReUI modules
        // For example:
        // FA repo
        "C:\\Users\\username\\Documents\\GitHub\\FA", 
        // ReUI modules
        "C:\\Users\\username\\Documents\\GitHub\\FAF-UI-Mods\\mods",
    ],
    "Lua.workspace.checkThirdParty": false,
}
```

More information about setting up your dev environment you can read in [official development guide](https://github.com/FAForever/fa/blob/develop/.github/DEVELOPMENT.md).

Once you setup your dev environment you can start creating your first mod.

## Modding

In official mod development guide in order to make a mod you have to create so called *hook*. It is a way to insert your own code into the base game code. But it has a huge downside, which can easily break your mod. You can't know in what order mods will be loaded, so, as hook. Of course, you can specify the order of mods to be loaded, but whenever you change mod version -> you have to change it in all other mods too, that depend on your mod. This circle of hell completely eliminates the idea of splitting mods into multiple, because you'll just suffer from updating each mod every time, including other modders that will try to use your mod.

Since we are going to create UI mods only, it is not that critical for mod order, but still important. Let's start with simple.

### **MyMod/mod_info.lua**

```lua
name = "my mod"
uid = "my-mod-v1.0.0"
version = 1
copyright = ""
description = [[]]
author = "you"
icon = "/mods/MyMod/icon.png"
url = ""
selectable = true
enabled = true
exclusive = false
ui_only = true

-- Here you specify your mod name and version,
-- it must match mod's folder name.
ReUI = 'MyMod=1.0.0'
```

### **MyMod/Main.lua**

```lua

---@param isReplay boolean
function Main(isReplay)
end

```

Basically this is enough for mod to work. But it is empty and does nothing.
Let's go through `Main.lua` in details and how to use it.

```lua

-- Code outside of `Main` is executed when game starts.
-- Here you usually don't want to do anything except requiring modules.
-- But sometimes like in ReUI.Reclaim you can do manual hooking
-- or some observer subscribing.
ReUI.Require
{
    -- List of required modules.
    -- if any of them do not match
    -- required version mod won't load at all.

    -- This is a core module. It allows
    -- making hooks into base game files,
    -- making callbacks for pre/post UI loading
    -- and creating classes and weak tables.
    "ReUI.Core >= 1.3.0",
}

---@param isReplay boolean
function Main(isReplay)
    -- Main is being run right before UI is created.
    -- Here you do everything for your mod to work.
    -- At this point all dependencies are loaded and
    -- You can access them through ReUI:

    ReUI.Core.OnPreCreateUI(function(isReplay)
        -- This is called right before UI is created
        -- Why do we need it when having the main function?
        -- There is a difference!

        -- You see Main function returns a value,
        -- Which is used as a module.
        -- Other mods can require your module and
        -- extend it.
        -- Secondly at this point all hooks are
        -- applied, which means all your mod's
        -- logic is properly loaded.

        -- And after that here you will be able to access your module
        -- completely ready:

        local MyMod = ReUI.MyMod

    end)

    ReUI.Core.OnPostCreateUI(function(isReplay)
        -- This is called right after UI is created.
        -- Same applies to this function.

        local MyMod = ReUI.MyMod
    end)


    -- In the end of Main you can
    -- expose your module's functionality for
    -- other mods to use. By default if none is
    -- returned ReUI will place empty module with
    -- Name and Version fields. Otherwise these fields
    -- are added to the returned module.
    -- In our case it will be
    -- {
    --     Name = "MyMod",
    --     Version = { major = 1, minor = 0, revision = 0 },
    -- }
    return {

    }
end

```
