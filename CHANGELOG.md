# Changelog

## 1.5.0
- Long shop item descriptions now scroll by themselves (pause at the top, slow
  scroll down, pause at the bottom, back up, repeat), with no input needed.
  Replaces the 1.4.0 mouse-height / Page Up / Page Down controls, which did not
  get through the remote screen share. The right stick still scrolls by hand.

## 1.4.0
- Long shop item descriptions can be scrolled without a mouse wheel or a right
  stick (remote play / screen share): the vertical position of the mouse picks
  the position in the text of the selected item (top of the screen = start,
  bottom = end), or hold Page Up / Page Down. P1 only by default
  (`TOOLTIP_SCROLL_PLAYER`).

## 1.3.0
- Public release. Mod id is now `BrotatoCoop-CoopBalance` (zip `CoopBalance.zip`).
- Includes everything below.

## Before 1.3.0 (summary)
- Materials malus compensation in co-op.
- Random character filter: co-op only for enemy-buffing characters (Jack, Chef,
  Diver; Curious, Captain and Droid are whitelisted as small buffs); solo and
  co-op for characters that already beat Nightmare on the selected map.
- In-game co-op overlay showing the compensation per player.
- Fixed a crash at wave start (the game's main scene was initialized twice).
