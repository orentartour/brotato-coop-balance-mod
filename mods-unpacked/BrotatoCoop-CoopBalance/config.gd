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

# --- Feature 3: scroll long item descriptions without a mouse wheel --------
# For remote play (screen share) where the wheel is not forwarded. Only the
# description of the item the player has selected scrolls.

# Player whose descriptions get these controls (0 = P1, -1 = every player).
const TOOLTIP_SCROLL_PLAYER = 0

# Mouse: its vertical position on the screen picks the position in the text
# (top = start, bottom = end), applied when the mouse moves. Works with the
# hidden co-op cursor.
const TOOLTIP_MOUSE_SCROLL = true
# Screen fraction ignored at the top and bottom (0.15 = the text is fully
# scrolled once the mouse is 15 % away from the screen edge).
const TOOLTIP_MOUSE_SCROLL_MARGIN = 0.15

# Keys (fallback): hold to scroll, pixels per second.
const TOOLTIP_KEY_SCROLL = true
const TOOLTIP_SCROLL_UP_KEY = KEY_PAGEUP
const TOOLTIP_SCROLL_DOWN_KEY = KEY_PAGEDOWN
const TOOLTIP_KEY_SCROLL_SPEED = 600.0
