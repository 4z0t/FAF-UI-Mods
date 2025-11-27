# Advanced Key Actions

Adds keybinds that combine multiple actions into one based on current selection:

1. Transportation / Overcharge / Repeat queue
    * Only transports in selection -> transportation order
    * Only ACU/SACUs in selection -> overcharge order
    * Only factories in selection -> toggles repeat queue
2. Launch missile / attack-reclaim / attack order
    * Nukes/Silos -> launch nuke/missile order
    * Engineers -> attack reclaim order
    * Anything else -> ground attack order
3. Select nearest idle t1 engineer / reclaim / toggle shields / toggle stealth
    * No selection -> selects nearest idle t1 engineer
    * Engineers (all engineers/ACUs/SACUs) -> reclaim order
    * Units with shield -> toggle shield
    * Units with stealth -> toggle stealth
4. Move / Select nearest transport
    * No selection -> selects nearest idle transport
    * With selection -> move order
5. Select nearest air scout / build sensors
    * No selection -> selects nearest air scout
    * Air scouts -> selects all air scouts on screen
    * Anything else -> order to build radars/sonars/scouts

These can be found at ReUI.Actions section of key bindings menu.

![aka](/Media/aka.png)
