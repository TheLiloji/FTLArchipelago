"""Presets shown on the options page. Built from presets/*.yaml, test_presets checks they still match."""

PRESET_FILES = {
    "Short, about 5 h": "short_game.yaml",
    "Medium, about 10 h (recommended)": "medium_game.yaml",
    "Long, 20 h or more": "long_game.yaml",
}

OPTIONS_PRESETS = {
    "Short, about 5 h": {
        "victories_required": 2,
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
        "layout_count": 14,
        "archives": 20,
        "archives_required": 16,
        "systemsanity": "first_install",
    },
}
