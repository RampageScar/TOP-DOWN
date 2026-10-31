# Stage 5b fixes: bugs found and planned changes

Source build: `timetravel_godot_stage5b_hall.zip`. Findings come from reading the code and running the project headless (Godot 4.3) with throwaway test scripts. No project files were changed for the diagnosis.

## Status key
- **DONE** = written in the working copy, not yet verified in a running game
- **TODO** = agreed, not yet written
- **CUT** = discussed and dropped

---

## Bug 1: The king looks much bigger than the other people
**Cause.** `king_seated()` in `castle_props.gd` drew him about 66px tall. A standing person is about 27px, so he was roughly 2.4x normal size. His head was 10x10 against 8x8 for everyone else, and the tiara added another 13px. A seated figure should be shorter than a standing one, not taller.

**Planned change**
- Redraw the king at person proportions: 8px head, 10px torso, seated skirt, boots on the throne base. About 48px tall from the floor, tiara included. He still sits above the guards because the seat is raised. **DONE**
- Trim the throne back by 8px so he isn't lost in it. The seat and base are unchanged. **DONE**
- Lower his floating-line offset in `npc.gd` from -74 to -58. **DONE**

**Check.** Screenshot of the throne with the guards and the hero beside it; run `tests/hall.gd`.

---

## Bug 2: Hall stairs don't look like stairs
**Cause.** The steps in `hall.gd` are flat alternating grey stripes with no vertical risers, so there is no sense of height. The red carpet is also painted flat over them, so the middle of the flight reads as a plain red strip. The grey blocks either side have no side walls. The dais front face is only 12px tall, while the steps run 36px deep.

**Planned change**
- Shared helper `paint_steps()` in `castle_props.gd`: every step has a light tread (lit top edge) and a darker riser with a contact shadow. **DONE**
- Shared helper `paint_cheek()`: side walls with a stepped stone cap and a newel post with a gold ball at the bottom. **DONE**
- Wire the helpers into `hall.gd`: 6 steps of 7px (4 tread + 3 riser), so the flight is 42px deep. Update `STAIRS` to match. **TODO**
- Draw the carpet stepped: dark riser strip and a gold lip on each step instead of one flat red band. **TODO**
- Add collision for the new side walls and newel posts (about x 304..312 and 408..416, y 212..244). **TODO**
- Check that `SCENE_ZONE` (starts at y 246) still sits clear of the longer flight. **TODO**

**Check.** Screenshot of the hall steps; `tests/hall.gd` (reachability, king scene, hero auto-walk up the steps).

---

## Bug 3: Courtyard gate stairs don't look like stairs
**Cause.** Same recipe as the hall: seven 5px flat bands in `courtyard.gd _paint_gate_tunnel()`, with no risers and no shading as they climb into the tunnel.

**Planned change**
- Use `paint_steps()` with 7 steps (4 tread + 3 riser), starting at y 66, inside the 60px-wide gate. **TODO**
- Darken each step toward the top so the stairs fade into the tunnel. **TODO**
- Add a soft shadow along the bottom of the flight. **TODO**
- The flanking gate pillars act as the side walls, so no cheek walls are needed here. **TODO**

**Check.** Screenshot of the courtyard gate; `tests/courtyard.gd`.

---

## Bug 4: Rats get stuck on the east side of the town
**Cause.** Rats steer straight at the hero with no pathfinding. When a wall or rock is between them and the hero, they slide along it back and forth. The slide counts as "moving", so the existing stuck check never fires, and they never give up.

**Measured.** About 1,400 chase scenarios around the six nest rats. Chasing in open ground works. The failures were:

| Where | What happens |
|---|---|
| Nest at (882, 648) | Rats pin on the town's east wall (x about 798) when the hero is inside the town |
| Nest at (985, 540) | Rats pin on the east face of the rock at (846, 527, 88x73), at x about 938 |
| Nest at (1052, 708) | Rats pin on top of the south cliffs (y about 749). The gap between the two cliffs below the nest is only about 36px wide (x 1025..1061). |

**Planned changes**
1. **Progress watcher** in `rat.gd`, with the tuning in `combat.gd`. **TODO**
   - While chasing, track the closest distance to the hero. If the rat hasn't got at least 6px closer for 1.5 seconds, it gives up and walks home.
   - After giving up it ignores the hero for about 3 seconds, so the proximity bubble doesn't pull it straight back.
   - Applies to rats and bandits. The giant rat is left out because it jumps and has its own fight rules.
   - New numbers: `progress_time`, `progress_gain`, `lost_time`.
2. **Cliff gap.** In `CLIFFS` in `world_waystation.gd`, shorten `[930,748,96,48]` to `[930,748,76,48]`. The gap becomes about 55px. The array drives both painting and collision, so this is a one-line edit. **TODO**
3. **Commit-to-a-side steering.** When a rat is blocked, it commits to going around one side for about 1 second instead of flipping sides every frame. This helps with the rock at (846, 527). **TODO**
4. **Nest 4 (882, 648)** is left where it is. The watcher handles it. Optional later nudge: (915, 655). **CUT for now**

**Check.** Re-run the same chase sweep and compare the pinned-rat counts (before: 24, 15, 14, 42, 50 and 76 per nest). Run `tests/combat.gd`, `tests/escape.gd`, `tests/bandit.gd` and `tests/boss.gd`.

---

## Not in scope
- The east town gate stays exactly as it is. It is not a bug and is not on this list. Widening it was discussed and dropped.

## Verification and packaging (all TODO)
1. Run the existing headless tests: `smoke`, `maps`, `courtyard`, `hall`, `combat`, `escape`, `bandit`, `boss`, `validate`.
2. Re-run the rat pin sweep.
3. Render screenshots of the throne, hall steps and courtyard gate.
4. Package a new zip (the project is not a git repository, so there is no git commit) and update the Stage 5 notes.
