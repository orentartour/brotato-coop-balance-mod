extends Reference

# CoopBalance configuration. Edit, then rebuild the zip with build.ps1.

# --- Feature 1: co-op material malus compensation -------------------------

# Master switch for the material compensation (main.gd + gold.gd extensions).
const ENABLE_GOLD_COMPENSATION = true

# false (default): each player gets
#     mean(positive effects) + max(mean(negative effects), own negative effect)
#   -> nobody suffers more than the worse of their own malus and vanilla;
#      the malus carrier keeps the vanilla result, the partner gets 100 %.
# true: each player gets mean(positive effects) + own negative effect
#   -> everybody fully suffers their own malus (the carrier loses more than
#      in vanilla: gold and XP are removed after pickup).
const STRICT_OWN_MALUS = false

# Logs every compensated pickup (very verbose, for testing only).
const DEBUG_LOG = false

# Co-op overlay at the top of the screen (right of the wave timer): extra
# materials each player gets on top of vanilla, for enemy and tree drops.
const SHOW_DEBUG_HUD = true

# --- Feature 2: filter for the "Random" character button ------------------

const ENABLE_RANDOM_FILTER = true

# The Random button also skips characters that already beat this danger level
# (or higher) on the selected map. 6 = Nightmare, 5 = Danger 5, 0 = off.
# With the map set to "Random", a character is skipped only if it beat it on
# every map.
const RANDOM_EXCLUDE_BEATEN_DIFFICULTY = 6

# Co-op only: characters with at least one effect whose stat key is in this
# list are never picked by the Random button (still selectable manually).
const RANDOM_EXCLUDED_EFFECT_KEYS = [
	"enemy_health",
	"enemy_damage",
	# "enemy_speed",        # explorer, old
	# "number_of_enemies",  # jack, explorer, loud, old
]

# Characters kept in the co-op Random pool despite an enemy buff (small one).
const RANDOM_EFFECT_FILTER_WHITELIST = [
	"character_droid",    # +5 % enemy damage per level up
	"character_captain",  # +2 % enemy health and damage per wave
	"character_curious",  # +25 % enemy health
]

# --- Feature 3: auto-scroll long item descriptions ------------------------
# For remote play (screen share) where neither the mouse wheel nor the cursor
# reaches the game. A description longer than its card scrolls by itself:
# pause at the top, slow scroll down, pause at the bottom, back up, repeat.
# The right stick still scrolls by hand (auto-scroll pauses meanwhile).

const TOOLTIP_AUTO_SCROLL = true
const TOOLTIP_AUTO_SCROLL_SPEED = 35.0          # pixels per second, going down
const TOOLTIP_AUTO_SCROLL_RETURN_SPEED = 300.0  # pixels per second, going back up
const TOOLTIP_AUTO_SCROLL_TOP_PAUSE = 2.5       # seconds
const TOOLTIP_AUTO_SCROLL_BOTTOM_PAUSE = 2.5    # seconds
const TOOLTIP_AUTO_SCROLL_MANUAL_PAUSE = 4.0    # seconds after a right stick move
