# LibDropDown - A library for dropdown menus.

Supports the following standard Ace3 structures:

*    Color
*    Execute
*    Groups
*    Header
*    Input
*    Range
*    Select
*    Toggle

# Usage

```
local menuframe = LibStub("LibDropdown-1.0"):OpenAce3Menu(Ace3ConfigTable)
```
This returns a frame for the root menu. You might want to use SetPoint on this frame to attach it to an appropriate location. You may optionally release the menu with:
```
menuframe:Release()
```
However this isn't required as the addon will do this when the menu is hidden. 
