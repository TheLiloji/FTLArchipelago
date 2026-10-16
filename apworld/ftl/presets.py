"""Presets shown on the options page. Built from presets/*.yaml, test_presets checks they still match."""

PRESET_FILES = {
    "First game, about 3 h": "first_game.yaml",
    "Short, about 5 h": "short_game.yaml",
    "Medium, about 10 h (recommended)": "medium_game.yaml",
    "Long, 20 h or more": "long_game.yaml",
}

OPTIONS_PRESETS = {
    "First game, about 3 h": {
        "victories_required": 1,
        "victory_difficulty": "any",
        "layout_count": 3,
        "ship_layouts": "type_a_only",
        "archives": 3,
        "archives_required": 2,
        "sectorsanity_last_sector": 6,
        "general_achievements": "basic",
        "full_system_upgrades": True,
        "free_upgrades": True,
        "system_install": "run_start",
        "run_start_scrap": 15,
        "shop_weapons": 15,
        "shop_drones": 6,
        "shop_augments": 10,
    },
    "Short, about 5 h": {
        "victories_required": 2,
        "victory_difficulty": "normal",
        "layout_count": 4,
        "archives": 5,
        "archives_required": 4,
        "full_system_upgrades": True,
        "shop_weapons": 25,
        "shop_drones": 10,
        "shop_augments": 15,
    },
    "Medium, about 10 h (recommended)": {
        "victories_required": 5,
        "victory_difficulty": "normal",
        "layout_count": 7,
        "archives": 12,
        "archives_required": 10,
    },
    "Long, 20 h or more": {
        "victories_required": 10,
        "victory_difficulty": "normal",
        "layout_count": 14,
        "archives": 20,
        "archives_required": 16,
        "systemsanity": "first_install",
    },
}
