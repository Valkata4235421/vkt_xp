# vkt_xp API Documentation

This document outlines the API for the vkt_xp export system, providing functions to manage XP and levels for players in specific categories.

# Preview

[![Preview](https://iili.io/FkRyMa2.png)](https://iili.io/FkRyMa2.png) [![Preview](https://iili.io/FkRysna.png)](https://iili.io/FkRysna.png)

## Client-Side Functions

### GetXP(name)

Retrieves XP data for a category for the local player.

**Parameters:**
- `name` (string): The name of the category (e.g., "farming")

**Returns:**
- `table`: A table containing `level` and `xp` for the category

**Example:**
```lua
local data = exports['vkt_xp']:GetXP("farming")
```

### GetLevel(name)

Retrieves the level for a category for the local player.

**Parameters:**
- `name` (string): The name of the category (e.g., "farming")

**Returns:**
- `number`: The level for the specified category

**Example:**
```lua
local level = exports['vkt_xp']:GetLevel("farming")
```

## Server-Side Functions

### AddPlayerXP(source, categoryName, xpToAdd)

Adds XP to a player for a specific category.

**Parameters:**
- `source` (number): The player's server ID
- `categoryName` (string): The name of the category (e.g., "farming")
- `xpToAdd` (number): The amount of XP to add

**Example:**
```lua
exports['vkt_xp']:AddPlayerXP(source, "farming", 1000)
```

### GetPlayerXPData(source, categoryName)

Retrieves XP data (XP and level) for a player in a category.

**Parameters:**
- `source` (number): The player's server ID
- `categoryName` (string): The name of the category (e.g., "farming")

**Returns:**
- `table`: A table containing `level` and `xp` for the category

**Example:**
```lua
local data = exports['vkt_xp']:GetPlayerXPData(source, "farming")
```

### InitPlayerXP(source)

Initializes a player's XP data for all categories if not already present.

**Parameters:**
- `source` (number): The player's server ID

**Example:**
```lua
exports['vkt_xp']:InitPlayerXP(source)
```

## Usage Notes

- All category names should be consistent strings (e.g., "farming", "mining", "combat")
- Server-side functions require a valid player source ID
- Client-side functions automatically use the local player's data
- XP values are cumulative and levels are calculated based on total XP
