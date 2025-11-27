# ReUI

ReUI project is a collection of UI mods that improve game experience, performance and usability of UI in Supreme Commander: Forged Alliance. Here is current list of mods and libraries that are part of ReUI project.\
[![Discord](https://img.shields.io/badge/Discord-Join%20Us-7289DA?logo=discord&logoColor=white)](https://discord.gg/EZb6h6gbWz)

## Mods

Click on link to see full info about a mod.

### [ReUI.Score](/Docs/Overview/ReUI.Score.md)

![functionsreplay.gif](/Media/functionsreplay.gif)

### [ReUI.Economy](/Docs/Overview/ReUI.Economy.md)

![Economy](/Media/economy.png)

### [ReUI.Reclaim](/Docs/Overview/ReUI.Reclaim.md)

![reclaim](/Media/reclaim.png)

### [ReUI.Construction](/Docs/Overview/ReUI.Construction.md)

![Build options](/Media/reui_construction_build_options.jpg)
![Selection](/Media/reui_construction_selection.jpg)
![Enhancements](/Media/reui_construction_enhancements.jpg)
![Upgrade chain](/Media/reui_construction_upgrade_chains.jpg)

### [ReUI.Hotbuild](/Docs/Overview/ReUI.Hotbuild.md)

![reuihotbuild](/Media/reuihotbuild.png)

### [ReUI.Minimap](/Docs/Overview/ReUI.Minimap.md)

### [ReUI.ActionsPanel](/Docs/Overview/ReUI.ActionsPanel.md)

![ActionsPanel](/Media/enhacements.png)

![templates](/Media/templates.png)

### [Ctrl](/Docs/Overview/Ctrl.md)

### [Engineer Alt Selection](/Docs/Overview/EngineerAltSelection.md)

![eas](/Media/eas.gif)

### [Rings For All](/Docs/Overview/RingsForAll.md)

![rfa1](/Media/rfa1.png)

### [Instant Assist](/Docs/Overview/InstantAssist.md)

![IA1](/Media/IA1.gif)

### [Advanced Key Actions](/Docs/Overview/AdvancedKeyActions.md)

## Libraries

### ReUI.Core

Core library of ReUI. Provides functions for hooking into existing files of the game and executing code before and after UI is created. And functions for creating classes with properties and tables with weak keys/values.

### ReUI.Options

Module with functions to create and manage options for your mod. It provides with `OptionVar` class to create reactive options for your needs; builder to create options menus with various types of options: filters, scrollers, selectors and etc. Use cases can be found in almost every mod in `Options.lua`.

### ReUI.UI

Provides with 3 crucial classes for ReUI's controls: Layouter, Layout and Layoutable.

Layouter is responsoble for performing layout on a given control. Supports reactive scaling. Each control by default uses parent's layouter.
Layout is a class that represents layout of given control and can switched on the fly to alter control's layout. By default each control uses layout that is done inside `InitLayout` method.
Layoutable is a class that stores Layouter and Layout references and applies them when needed. You can inherit this class to use Layouter and Layout in your control.

#### ReUI.UI.Controls

Provides with primitive classes that inherit Layoutable class. These are Group, Text, Bitmap and CheckBox.

#### ReUI.UI.Views

Provides with generic controls such as button, arrow, border, bracket, scrollable control and grid.

#### ReUI.UI.Animation

#### ReUI.UI.Color

### ReUI.LINQ

An icing on cake. A [.Net LINQ inspired library](https://github.com/4z0t/LuaLINQ) adapted for FAF needs and environment. This is superior version of LINQ (LuaQ) from deprecated UI mod tools. Way faster and more flexible. Basically it is a collection of functions to manipulate collections in efficient, easy to read and extend way.

### ReUI.WorldView

Extends original WorldView with ECS. Applications can be seen in **[ReUI.Reclaim](#reuireclaim)** and **RFA**.
