# Stage 6c plan: the chief, the slingers and the return to the king

Written 2026-10-27, after Stage 6b. The story decisions behind it are in the design doc (Era 1, "the king's lost riders").
6a built the cave map; 6b added the cage, the rider Farnaka as an archer companion, and the rescue ambush.
6c finishes the cave: the band's chief in the boss room, slingers that join his fight, and the return to the throne room.

## Decisions already made (by the user)
- **The chief** is a camp leader with **new moves**: a **charge** and an **axe sweep**. At **half health he becomes enraged**: he moves and
  attacks faster (the user said 1.2-1.5x).
- **Slingers** appear **only when the chief's fight starts**, never before.
- **When the chief falls:** fade to the throne room. The hero appears south of the stairs, not too close, walks up to the king, and a
  dialogue plays. If the rider was freed, he appears and walks up too.
- **If the chief falls before the rider is freed:** the return plays **without him** (a lesser ending), and the rider stays caged.

## The user's answers (2026-10-27; built as Stage 6c, see `timetravel_godot/README.md`)
- **Rider targets:** he shoots only enemies that are awake and after the hero (not asleep, not patrolling or walking home), nearest first.
- **Chief's health:** the default, 20 HP; tune after a play-test.
- **Escape from the boss room:** none. Once he wakes, the room is sealed (a barricade across the steps) until he falls; "You fell" puts you
  back inside the room.
Where the build differs from the plan below: the giant rat does not in fact keep its damage after a fall, and the user then decided that
every enemy, the chief included, heals to full once it walks home (design doc, section 8), so the chief does not keep his damage either;
and `arrived()` is called at the end of `main.travel()` (after the fade), not inside
`_switch_level`, because `travel()` hands control back after the switch.

---

## 1. The chief (`scripts/chief.gd`, new)
- `extends "res://scripts/rat.gd"`, so patrol, sense, return, calm, dying and the hit flash stay shared. `rat.gd` stays the rat / bandit / giant brain.
- `combat.gd _spawn_rat` picks the script by kind: `"chief"` -> `chief.gd`, `"slinger"` -> `slinger.gd`, everything else `rat.gd`.
- Numbers in a new `CHIEF` const in `combat.gd` (all tunable):

| Key | Value | Meaning |
|---|---|---|
| `hp` | 20 | health |
| `xp` | 150 | `XP_CHIEF` |
| `chase_speed` | 48 | walking after the hero |
| `charge_min` / `charge_max` | 70 / 200 | the distance at which he may charge |
| `charge_wind` / `charge_lock` | 0.8 / 0.25 s | the red line follows you, then freezes for the last 0.25 s |
| `charge_speed` / `charge_len` | 230 / 190 px | the rush |
| `charge_dmg` | 2 | hearts on contact |
| `daze_time` | 1.2 s | after running into a wall or stalagmite |
| `charge_cd` | 3.5 s | time between charges |
| `sweep_range` | 40 px | up close he sweeps instead |
| `sweep_wind` / `sweep_arc` / `sweep_radius` | 0.6 s / 120 deg / 44 px | the red arc in front of him |
| `sweep_dmg` | 1 | hearts if you are inside the arc when it lands |
| `recover_time` | 0.9 s | his opening after a move |
| `enrage_frac` / `enrage_mul` | 0.5 / 1.3 | once, at half HP: speeds x1.3, wind-ups and recovery / 1.3 |
| `enrage_time` | 0.8 s | the roar (red tint, sparks, a camera shake) |
| `leash` / `lose` | 300 / 360 | the whole boss room |

- **States** (on top of rat.gd's): `charge_wind` -> `charge` -> `daze` or `recover`; `sweep_wind` -> `sweep` -> `recover`; `enrage`.
- **Armour:** hits hurt him but never interrupt `charge_wind`, `charge`, `sweep_wind`, `sweep` or `enrage` (like the giant).
  He is heavy (no lasso: "Too heavy!").
- **The charge:** a red line drawn on the ground from him to the hero, following, then frozen. He rushes along it. Each step checks
  `world.sight_blocked()` / `feet_blocked()`: a tall solid (rock wall, stalagmite) stops him -> `daze` (stars over his head, takes hits).
  Touching the hero on the way -> `combat.hurt_player(charge_dmg)` once. A dodge's invulnerability lets him pass through.
- **The sweep:** a red arc (cone) on the ground in front of him, locked at the start of the wind-up. At the hit moment, the hero inside
  the arc and radius takes `sweep_dmg`. Stepping behind him or dodging avoids it.
- **Drawing:** a big bandit (about 1.3x, darker clothes, a felt cap, a fur over one shoulder) with a *sagaris* axe (a long haft with a
  narrow head: period-credible, unlike the curved swords). Reuses `rat.gd _draw_bandit` scaled, plus the axe and his telegraphs
  (charge line, sweep arc), drawn on the fx layer like the giant's slam circle.
- **In the cave:** `ENEMIES` gets `{"kind": "chief", "pos": seat front (820, 176), "group": "boss"}`, and `WAKE["boss"]` gets the middle of
  the boss room (about (820, 260), radius 70, `aggro`). He sits on his seat (dormant) until you walk in.

## 2. The slingers (`scripts/slinger.gd`, new)
- `extends "res://scripts/rat.gd"`, with a `SLINGER` const in `combat.gd`: `hp` 2, `xp` 15, keeps 80-130 px away (backs off if you get closer
  than 70), `wind` 0.7 s (the sling spins overhead while a thin aim line shows), then throws a stone with `combat.shoot(..., "enemy", "stone", 1, 180)`.
  Cooldown about 1.6 s. Lasso-able (light).
- They never spawn with the map. `cave.gd SLINGER_SPOTS` (3 points round the boss room's edges, behind the palisades by the stairs and
  in the east and west corners): when the chief's group wakes, `cave.gd` spawns them with `combat.spawn_enemy(e, true)` and a dust puff.
- Stones use the 6b projectile code: tall solids stop them, a dodge lets them fly past. Drawing: a lean bandit with a sling, no sword.

## 3. When the chief falls
- `cave.gd` notices the chief is dead (as it checks the ambush), waits about 1.5 s (a "+150 XP", the band's banner sags), then:
  - sets `quest.flags["chief_down"]` (new: `quest.gd` gets a small `flags` dictionary next to `stage`), and `rider_joined` if he was following;
  - calls `dialogue.travel.call("hall", "king_return")`.
- **Without the rider:** the cage's `usable("cage")` returns false from now on (no E), and he stays inside, muttering.
- The slingers left alive stay in the cave (frozen with it); they are not part of the return.

## 4. The return to the throne room (`hall.gd`)
- New spawn `king_return` about 90 px south of the steps (around (360, 336)), facing up.
- New level hook `arrived(spawn_name)` in `level.gd` (default: nothing), called by `main._switch_level` at its end.
  `hall.gd arrived("king_return")` starts the return scene.
- **The walk:** the stair-scene walk in `hall.gd _process` becomes a reusable `_walk_hero_to(target)`. Control locks (`talking`,
  `player.scripted`), the camera looks up at the king (as in the intro), and the hero walks to `SCENE_STOP`.
  If the rider was freed, a plain NPC with look `rider` appears beside the hero and walks up with him to a spot beside the throne steps
  (moved by `hall.gd` directly, not by a route, so he never waits for the hero).
- **The dialogue:** `dialogue.start_scene` with lines from a new `dialogue.gd` table (spoken text stays in `dialogue.gd`). A line may
  name its speaker (`{"t": "...", "who": "rider"}`), so the king and the rider can both speak in one scene: the box shows that person's
  name and portrait. Two versions:
  - **with the rider:** the king sees his rider alive, the rider reports the raid and the chief's fall, the king thanks the hero;
  - **without him:** the band is broken, but the king asks after his men; the hero has no answer (the lesser ending).
  Neither version assumes the hero met the king before (you can reach the cave without the stair scene).
- **After it:** `intro_done = true` (the first stair scene never plays afterwards), the king is talkable, and `return_done` is set.
  The rider stays by the throne as a talkable NPC with a couple of lines (`TALK["rider"]` at a later key, or a separate id such as `rider_hall`).
- The hall's `CALL_LINE` / `INTRO` move into `dialogue.gd` at the same time (the CLAUDE.md rule; backlog item).

## 5. Data and files touched
| File | Change |
|---|---|
| `scripts/chief.gd` | new: the chief's brain and drawing |
| `scripts/slinger.gd` | new: the slinger's brain and drawing |
| `scripts/combat.gd` | `CHIEF`, `SLINGER`, `XP_CHIEF`, `XP_SLINGER`; spawn picks the script by kind; `rat_killed` XP for the new kinds; the chief's telegraphs on the fx layer |
| `scripts/cave.gd` | the chief in `ENEMIES`, `WAKE["boss"]`, `SLINGER_SPOTS`, spawning the slingers on wake, the chief's death -> the return; the cage's E off after a return without the rider |
| `scripts/level.gd` | `arrived(spawn_name)` hook |
| `scripts/main.gd` | `_switch_level` calls `arrived()` |
| `scripts/hall.gd` | spawn `king_return`, `arrived()`, the return scene, the rider NPC by the throne, `_walk_hero_to()` |
| `scripts/dialogue.gd` | the return lines (both versions), per-line speaker (`"who"`), the rider's hall lines, the hall's call line and intro moved in |
| `scripts/quest.gd` | `flags` (`rider_joined`, `chief_down`, `return_done`) |
| `scripts/rider.gd` | (if the user picks it) shoot only enemies that are awake and after the hero |
| `scripts/sprites.gd` | looks `chief`, `slinger` (if drawn through `person`) |

## 6. Tests and checks
- Run `tests/run_all.ps1` at the end. No new tests unless the user asks; `fight.gd` should pass unchanged (the giant, rats and bandits keep `rat.gd`).
- A throwaway check (not kept), like 6b's:
  - the chief sleeps until you reach the room's middle, then charges;
  - the charge line freezes before the rush, a stalagmite dazes him, and a dodge passes through him;
  - the sweep hurts only inside its arc;
  - he enrages once at half HP;
  - the slingers appear only when he wakes, their stones hurt, and a dodge or a wall stops them;
  - his death leads to the hall at `king_return`, the walk and the right dialogue (with / without the rider), and the cage has no E after the lesser return;
  - walking back to the cave afterwards works.
- Play-test with F5: both endings, and the fight with and without the rider.

## 7. Docs (rule 2)
README (current state, the file map with `chief.gd` / `slinger.gd`, Stage 6c history), IMPROVEMENTS (tick roadmap 6c, the rider items,
the hall's spoken text; add what the play-test shows), CLAUDE.md (stage, `CHIEF` / `SLINGER` in the constants list). The design doc already
holds the decisions; update it only if the user decides something new (e.g. the rider's targets).

## Not in 6c
A late rescue after the lesser return; the rider leaving the cave before the chief falls; keys and inventory; quest-tracker text (roadmap
step 3); loot or a scientist clue from the chief (pending decision: how the king's thread leads back to the scientist); camp alarms and pathfinding.
