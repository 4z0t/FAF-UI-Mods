ReUI is a powerful framework for creating UI mods for Supreme Commander: Forged Alliance Forever. And this guide will show you the ropes of using it!

## Setup

ReUI hardly relies on intellisence, thus it is best to setup it properly before using it.
For development in FAF community we use [VSCode](https://code.visualstudio.com/)
and [Extension specific for FAF game development](https://github.com/FAForever/fa-lua-vscode-extension/releases).

Once you downloaded installed VSCode and extension you need to point out paths for extension to work:

**settings.json**
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
        "C:\\Users\\username\\Documents\\GitHub\\FA", // FA repo
        "C:\\Users\\username\\Documents\\GitHub\\FAF-UI-Mods\\mods", // ReUI modules
    ],
    "Lua.workspace.checkThirdParty": false,
}
```

More information about setting up your dev environment you can read in [official development guide](https://github.com/FAForever/fa/blob/develop/.github/DEVELOPMENT.md).

Once you setup your dev environment you can start creating your first mod.

## Modding

In official mod development guide in order to make a mod you have to create so called *hook*. It is a way to insert your own code into the base game code. But it has a huge downside, which can easily break your mod. You can't know in what order mods will be loaded, so, as hook. Of course, you can specify the order of mods to be loaded, but whenever you change mod version -> you have to change it in all other mods too, that depend on your mod. This circle of hell completely eliminates the idea of slitting mods into multiple, because you'll just suffer from updating each mod every time, including other modders that will try to use your mod.

Since we are going to create UI mods only, it is not that critical for mod order, but still important. Let's start with simple.

**MyMod/mod_info.lua**

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

ReUI = 'MyMod=1.0.0'
```

**MyMod/Main.lua**

```lua


function Main(isReplay)
    
end

```