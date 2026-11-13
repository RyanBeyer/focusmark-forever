# FocusMark Forever

A focus-marker bar for **WoW Forever**. It adds a small movable bar of raid icons. Click an icon and the addon writes your focus macro, so one keybind sets your focus and marks it.

FocusMark Forever is a fork of **[FocusMarker](https://www.curseforge.com/wow/addons/focusmarker)** by **Dentee-Frostmourne**, used under the MIT License. All credit for the original addon goes to them. This fork is not affiliated with or endorsed by the original author.

> **Beta.** The original FocusMarker is a Retail addon with no WoW Forever version. This fork adapts it for Forever. Please report anything that doesn't work on the [issue tracker](https://github.com/RyanBeyer/focusmark-forever/issues).

## Install

**CurseForge app:** search for "FocusMark Forever" under WoW Forever and install it.

**Manual:** extract the `FocusMarkForever` folder into:

```
World of Warcraft\_forever_\Interface\AddOns\
```

Restart the game after installing. A new addon is only picked up on a full launch, not on `/reload`.

## Set up the macro

1. Type `/macro` and create a macro named exactly **FocusMark**, with any icon and any body. The General tab works fine.
2. Drag it onto an action bar.
3. Click an icon on the FocusMark Forever bar. The addon rewrites the macro to:

```
#showtooltip
/focus [@mouseover,exists,nodead][]
/stopmacro [@focus,noexists]
/tm [@focus] ~<icon number>
```

Pressing the macro focuses your mouseover, or your target if you have no mouseover, then marks the focus with your chosen icon. The macro can't be edited during combat, so pick your icon before you pull.

## Commands

`/fm` or `/fmf` opens settings. The other options are unchanged from FocusMarker: lock and unlock the bar, show and hide it, and reset it to defaults.

## Known issues

- The Edit Mode move and resize overlay may not work on Forever. The bar still works without it, and you can move it from the settings panel.
- Updating the macro when you log in is new in this fork and may not work for everyone. If your macro doesn't change after a login, click an icon on the bar to update it, and report it.
- After each update the addon prints `macro update OK` or `FAILED (reason)` in chat. Include the `FAILED` text in a bug report.

## Changes from FocusMarker 2.0.18

For developers and anyone comparing the two versions. Newer retail releases of FocusMarker (up to 2.0.23 at the time of writing) are not merged in.

- **Renamed** to FocusMark Forever: folder, `.toc`, SavedVariables (`FocusMarkForeverDB`), frame names and the `/fmf` command. It doesn't clash with the original and starts with its own settings.
- **`.toc`:** added Interface `16001`, WoW Forever's reported build.
- **Group chat:** `IsInGroup(LE_PARTY_CATEGORY_INSTANCE)` is now `IsInGroup(2)`, in case that constant is missing on Forever.
- **Macro update at login:** the original only updated the macro at `ADDON_LOADED`, when Forever hasn't loaded the macro list yet. It now also runs at `PLAYER_LOGIN`, with a retry 2 seconds later.
- **Macro update checks:** `EditMacro` is wrapped in `pcall`, passes the macro's existing icon instead of `nil`, then re-reads the body and reports the result in chat and the debug log.

## License

MIT. See [LICENSE](LICENSE). The original project's CurseForge license page has an unfilled copyright line, so the original copyright is credited to the author by name. If the original author states a different line, `LICENSE` should be updated to match.
