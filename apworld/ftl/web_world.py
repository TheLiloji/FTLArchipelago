
from __future__ import annotations

from BaseClasses import Tutorial
from worlds.AutoWorld import WebWorld

from .options import ftl_option_groups


class FTLWeb(WebWorld):
    theme = "dirt"

    rich_text_options_doc = True

    option_groups = ftl_option_groups

    setup_en = Tutorial(
        "Multiworld Setup Guide",
        "A guide to installing FTL, Hyperspace and the Archipelago mod, and to joining a "
        "multiworld.",
        "English",
        "setup_en.md",
        "setup/en",
        ["TheLiloji"],
    )

    tutorials = [setup_en]

    game_info_languages = ["en"]
