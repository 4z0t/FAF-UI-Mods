# ***How to make your own extension***

Extension starts with specifying in `mod_info.lua` that mod has anything for actions grid panel to work with. 

`AGP = "ExampleHandler"`

In mod’s folder there must be a file with the same name containing a class with the same name.

`ExampleHandler.lua`:
  
```lua
--Generic imports for interfaces
local ISelectionHandler = import("/mods/AGP/modules/ISelectionHandler.lua").ISelectionHandler

local IItemComponent = import("/mods/AGP/modules/IItemComponent.lua").IItemComponent

---Handler class must implement ISelectionHandler interface to function. 
---It also must have a dedicated component class implementing IItemComponent.
---@class ExampleHandler : ISelectionHandler
ExampleHandler = Class(ISelectionHandler)
{
    ---Name of the extension displayed in extensions selector 
    Name = "Example extension",
    ---Description of the extension displayed in extensions selector
    Description = "Extension for testing purposes",
    ---Decides whether extension is enabled by default of not
    Enabled = false,
    ---Called when player’s selection is changed.
    ---Here is a logic for providing grid with actions of this extension in particular.
    ---These actions then are processed by component below.
    ---@param self ExampleHandler
    ---@param selection UserUnit[]
    ---@return any[]?
    OnSelectionChanged = function(self, selection)
    end,
    ---Component class that receives action provided by handler.
    ---Since each item in grid has multiple components at once
    ---it is important to ensure that active one is
    ---not interrupted by disabled ones. Here is interface for it.
    ---@class ExampleComponent : IItemComponent
    ComponentClass = Class(IItemComponent)
    {
        ---Called when component is bond to an item. Initialize your controls and logic here.
        ---@param self ExampleComponent
        ---@param item Item
        Create = function(self, item)
        end,
        ---Called when grid item receives an event
        ---@param self ExampleComponent
        ---@param item Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
        end,
        ---Called when item is activated with this component.
        ---Here you show and enable components controls and logic
        ---@param self ExampleComponent
        ---@param item Item
        Enable = function(self, item)
        end,
        ---Called when component receives action it is bond to
        ---@param self ExampleComponent
        ---@param action string
        SetAction = function(self, action)
        end,
        ---Called when item is changing an event handler.
        ---Here you hide and disable controls of the component 
        ---@param self ExampleComponent
        ---@param item Item
        Disable = function(self, item)
        end,
        ---Called when component is being destroyed.
        ---Clear all fields you had and destroy controls.
        ---@param self ExampleComponent
        Destroy = function(self)
        end,
    },
}

```