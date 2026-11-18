# Review of the November 18 code review

Reviewed against `61de330`. Static inspection only.

## Bugs

- **1, 12 — Lock validation.** The rejection branch reads `deviceInventory` before its assignment and can dereference a missing target. Caprica allows use before declaration in Skyrim mode. The branch is defective even if compilation succeeds. The inventory armor cast, resolved DD library and rendered armor are also used without checking them. [Caprica compiler options](https://github.com/Orvid/Caprica/blob/master/Caprica/main_options.cpp#L1951)
- **2 — Source fixed, bundled script stale.** `61de330` fixes both comparisons and concatenation. `Scripts/skynet_DeviousScript.pex` last changed in `4887bc8`.
- **3 — Inventory side effect.** Opening the device submenu grants missing keys before selection, including when the user cancels. The script does not reclaim them. NPC self-unlocking depends on UD and the device.
- **4, 5, 6, 7 — Confirmed in source.** The array lookup uses an object handle and discards the result. Both remaps register while disabled, and the key handler checks only the key code. Debug Equip is a no-op. The decorator lists armbinder twice when the speaker has one in inventory.
- **8 — Separate the checks.** Unequip has no explicit child-target check. Its action category checks the acting NPC. The MCM setting is explicitly about equipping. Whether protected devices can be removed depends on DD's unlock implementation.
- **9 — Type ambiguity.** Binder, ElbowTie and StraitJacket use the same removal keyword. Yoke maps to its own keyword, and the review does not establish whether a specific yoke also carries the shared keyword.
- **10, 11 — Confirmed code paths.** UD handlers dereference unchecked wearer and inventory forms and use base names. The orgasm handler always emits from the player. Check the upstream sender before using it for actor attribution.

## Missed findings

- `Groups.psc:99–103,186–195` accepts negative menu results. A `-1` result can index Papyrus arrays in the parent menu and reach device lookup in the submenu. Confirm dismissal behavior with the installed UIExtensions. [UIListMenu implementation with a negative dismissal result](https://git.eddoursul.win/enderal/enderalse/src/commit/acb132637628befd75f969be3e1ccf5eaca46826/source/scripts/uilistmenu.psc#L156)
- `skynet_DeviousScript.psc:64–85` builds permission text during action registration. The MCM toggles change runtime enforcement immediately but never refresh the registered descriptions. See `PlayerAlias.psc:27–28` and `MCM.psc:314–344`.

## Performance and cleanup

- **1, 2 — Measure requests.** Three rules share the event criterion and a fourth matches the orgasm payload. Persistent context records an event. Narration and thought rules have cooldowns. Action and UD callbacks can each emit an event when both paths run. Match counts alone establish neither LLM call counts nor a doubling. [SkyrimNet trigger response types](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/main/docs/modding/WORKFLOW_TRIGGERS.md#step-25-choose-response-type)
- **3–7 — Confirmed code observations.** The empty update handler is registered. There are 23 unequip actions with a combat check beneath a separate category child check. Prompt inclusion depends on SkyrimNet. The decorator allocates two arrays and has no in-repo prompt caller. The library cache is an MCM field private to that script. Repeated lookups are low priority without profiling. Use `elseif` only if the minigame names are mutually exclusive.
- The debug actor scan requires a nonempty `debug_target` other than `self` or `player`. A missing worn keyword logs a trace but emits no feedback event. The duplicate helpers, unused source, repeated message and whitespace are cleanup. JMap key casing remains unverified.
