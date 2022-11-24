# FAF-UI-Mods

Ecosystem of UI mods for [FAF](https://www.faforever.com/).

## UI Mod Tools

A library for all other mods.
It contains tools for building various options for mods (filters, sliders, color selectors, color sliders), processing units, layouting UI controls, and views for scrolling.

## TeamInfo Share

A mod sharing data between teammates about nuke/smd silo counts, progress, etas of construction and EXP units time construction.

Mod has options for positioning of timers, counters and progress. Each timer can be disabled, but data would be sent to teammate anyway.

## Selected Units Info

A mod displaying totals of selected units, such as total mass and energy used, build power, mass and energy consumption, mass killed.

Panel is located on top of UI and can be moved horizonally with middle mouse button.

## Specific Target Priorities

A mod is used to target specific type of a unit.

To use it bind a hotkey in **Target priorities** section, hover over unit with a mouse and press the key.
All selected units will target units of its type.

## Smart Ring Display

A mod displaying unit's weapon ranges when hovering over it with a mouse and shift pressed.

Unpack textures of the mod before using it.

## Idle Engineers Light

A mod displaying units' states with various icons over them. 

* Engineers being idle
* Factories being idle, upgrading, building in loop or only engineers
* TMLs/Nukes/SMDs being loaded
* Mexes upgrading.

All these icons can be disabled/enabled separately.

## HotBuild Overhaul

A mod for creating custom hotbuild actions.
See [forum post](https://forum.faforever.com/topic/3712/hotbuild-overhaul/1?_=1669191703421) for more info.

## EzReclaim

A mod displaying reclaim labels in reclaim mode.

## ECO UI Tools

A mod providing UI for better ECO management.

### Mex panel

Shows counts of mexes in different states (idle, upgrading, paused) and progress of upgrade on a bottom of each state.

Panel has functions when clicking on a mex state:

* T1/T2 mexes
  * [Left]              select all
  * [Right]             select all on screen
  * [Ctrl + Left]       start upgrading and pause
  * [Ctrl + Right]      start upgrading and pause for those on screen
* T1/T2 upgrading mexes
  * [Left]              select all
  * [Right]             pause all
  * [Ctrl + Left]       select one with highest progress
  * [Ctrl + Right]      pause one with lowest progress
* T1/T2 upgrading paused mexes
  * [Left]              select all
  * [Right]             unpause all
  * [Ctrl + Left]       select one with highest progress
  * [Ctrl + Right]      unpause one with highest progress
* T3 mexes
  * [Left]              select all
  * [Right]             select all on screen

Panel is movable with middle mouse button.

### Overlay

You can enable overlay in options that shows mexes with numbers in squares.

### Key bindings

All actions in mex panel can be binded to a key.

### Automation

You can enable functions for automatic mex actions, such as

* upgrade and pause for t1 mexes
* upgrade and pause for capped t2 mexes
* unpause mexes under assist of set amount of BP
* unpause mexes once

## Engineer Alt Selection

A mod allowing selection of engineers when holding Alt key.

## Additional Orders Extension

A mod adding various QoL key actions.

## 4z0t's ScoreBoard

A mod replacing default scoreboard with a new one with its own features:

* Minimalistic and simple design
* Animations
* Flexible replay ScoreBoard
* Coop support

See [forum post](https://forum.faforever.com/topic/4391/new-scoreboard?_=1669035632876) for more info.
