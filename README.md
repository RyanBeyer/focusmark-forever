# FocusMark Forever

A focus-marker bar for **WoW Forever**: a small movable bar of raid icons. Click an icon and the addon writes your focus macro, so one keybind sets your focus and marks it.

This is a fork of **[FocusMarker](https://www.curseforge.com/wow/addons/focusmarker)** by **Dentee-Frostmourne**, released under the MIT License. All credit for the original addon goes to them. This fork is not affiliated with or endorsed by the original author, and it is not published on CurseForge.

> **Status: experimental.** The original FocusMarker is a Retail addon and its CurseForge listing has no WoW Forever version. This fork exists to try it on Forever. It has been read through for compatibility but has not been fully tested in game.

Based on FocusMarker **2.0.18**. Newer retail releases (up to 2.0.23 at the time of writing) are not merged in.

## Install

Copy the `FocusMarkForever` folder to:

```
World of Warcraft\_forever_\Interface\AddOns\
```

Then restart the game. A new addon is only picked up on a full launch, not on `/reload`.

## Set up the macro

Create a macro named exactly **FocusMark** (any icon, any body, General tab is fine) and put it on an action bar. Clicking an icon on the bar rewrites it to:

```
#showtooltip
/focus [@mouseover,exists,nodead][]
/stopmacro [@focus,noexists]
/tm [@focus] ~<icon number>
```

It focuses your mouseover, or your target if there is no mouseover, then marks the focus. The macro can't be edited during combat, so pick your icon before you pull.

## Commands

`/fm` or `/fmf` opens settings. The addon's other slash options are unchanged from FocusMarker (lock/unlock, show/hide, reset).

## Changes from FocusMarker 2.0.18

- **Renamed** to FocusMark Forever: folder, `.toc`, SavedVariables (`FocusMarkForeverDB`), frame names and the `/fmf` command. It won't clash with the original if both are installed, and it starts with its own settings.
- **`.toc`:** added Interface `16001` (WoW Forever's reported build) to the supported list.
- **Group chat:** `IsInGroup(LE_PARTY_CATEGORY_INSTANCE)` is now `IsInGroup(2)`, in case that constant is missing on Forever.
- **Macro update at login:** the original only updated the macro at `ADDON_LOADED`, when Forever has not loaded the macro list yet. It now also runs at `PLAYER_LOGIN`, with a retry 2 seconds later. *(Untested.)*
- **Macro update checks:** `EditMacro` is wrapped in `pcall`, passes the macro's existing icon instead of `nil`, then re-reads the body and prints `macro update OK` or `FAILED (reason)` to chat. The result is also written to the debug log.

## Known unknowns

- Whether the Edit Mode move and resize overlay works on Forever. It depends on `EditMode.Enter` and `EditMode.Exit` events that I could not confirm. The bar still works without it.
- Whether the auto-update at login now works. The original failed there on Forever.

## License

MIT. See [LICENSE](LICENSE). The original project's license page on CurseForge has an unfilled copyright line, so the original copyright is credited to the author by name. If the original author states a different line or asks for a change, update `LICENSE` to match.
