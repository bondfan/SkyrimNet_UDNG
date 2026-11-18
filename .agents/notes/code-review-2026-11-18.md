# Code Review 2026-11-18

## Bugs

1. `skynet_DeviousScript.psc:25` — `deviceInventory` used before its declaration (line 29). Compile error, or `None.GetName()` at runtime.
2. `skynet_DeviousScript.psc:74,80` — `refinement = "..."` overwrites instead of appending (`+=`). Only the last disallowed target reaches the action description. (The `!=` comparison was fixed in 9e2c9be.)
3. `skyrimnet_UDNG_Groups.psc:164-166` — keys are added to the *target's* inventory and never removed. NPCs (and UD's NPC escape logic) can unlock themselves afterwards.
4. `skyrimnet_UDNG_Groups.psc:205-207` — `JArray.getObj(devices, wearing)` passes a JContainers object id as an index. Result is unused; delete the three lines.
5. `skyrimnet_UDNG_MCM.psc:106-108`, `151-153` — remapping a key calls `RegisterForKey` even when the hotkey toggle is off. Disabled hotkey becomes active.
6. `skyrimnet_UDNG_MCM.psc:247-251` — debug key "Equip on X" does nothing (branch commented out).
7. `skynet_DeviousScript.psc:699-786` — `armbinder` at index 0 and 13; decorator lists it twice.
8. `skynet_DeviousScript.psc:363` — `ExtCmdUnequip` ignores `quest_devices_allowed` and `IsChild()`; `LockDeviceOnActor` checks both.
9. `skynet_DeviousScript.psc:306-313` — Binder, ElbowTie, StraitJacket all map to `zad_DeviousHeavyBondage`. "Remove armbinder" removes a yoke too.
10. `skyrimnet_UDNG_PlayerAlias.psc:40-115` — no `None` checks on `WearerF`/`Inv`; uses `GetActorBase().GetName()` instead of `GetDisplayName()` (wrong name for renamed/leveled NPCs, inconsistent with the rest).
11. `skyrimnet_UDNG_PlayerAlias.psc:117` — orgasm event always uses the player as source regardless of who orgasmed.
12. `LockDeviceOnActor` — no `None` check on `inventoryDevice`, `libs_local`, `renderDevice`.

## Performance

1. Triggers: every `SkyrimNetDDUDNG_Event` matches `ddudng_context`, `ddudng_other` (interrupting direct narration), `ddudng_thoughts` (player thought, also for NPC-only events), and orgasm events also match `ddudng_orgasm`. One event → up to 3 LLM calls.
2. Duplicate events: `LockDeviceOnActor`/`ExtCmdUnequip` send their own event, and UD's `UDEvent_DeviceLocked/Unlocked` sends another for the same lock → doubles the trigger fan-out above.
3. `UDEvent_VibDeviceEffectUpdate` registered with an empty handler. Fires repeatedly for nothing; unregister.
4. 23 unequip actions registered with an eligibility check that only tests combat. All 23 are sent to the LLM on every action evaluation. Checking whether any nearby actor wears the keyword, or one parameterised action, would shrink the prompt.
5. `ddudng_get_devices` allocates and fills two 43-element arrays plus `GetFormFromFile` per call. Not referenced by any prompt; either cache arrays or drop the decorator.
6. `Game.GetFormFromFile` for zadlibs/MCM on every action call; `mcm.libs_local` already caches it. `Keyword.GetKeyword` up to 4 string lookups per lock; cache in MCM.
7. `OnStartMinigame` runs 5 `StringUtil.Find` calls; use `elseif`.

## Cleanup

- Dead code: `bHasDD`, `bHasDDExpansion`, `GetNearestAdultActor`, `skyrimnet_UDNG_PlayerActions.psc` (also wrong path), commented `BuildDeviceListJson` call.
- `SendPapyrusEvent` duplicated in two scripts, declared `bool`, returns nothing; `target` parameter unused.
- `LockDeviceOnActor` repeats the same failure message 5 times; one helper/flag.
- Debug-target path (`ScanCellActors`) runs in production `ExtCmdUnequip`.
- Unequip of a device the target doesn't wear returns silently; LLM gets no feedback.
- Double spaces in narration (`" forcefully "` + `" unlocked"`), trailing space in `"Gently by player "`, empty `Debug.Notification` when nothing changed.
- `group-devices.json` uses `Keyword`/`Name` keys, code reads `keyword`/`name`. Works only if JMap keys are case-insensitive (unverified); align `build-group-device.py` output.
