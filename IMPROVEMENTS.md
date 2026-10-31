# Improvements backlog

A living list of suggested improvements, kept up to date as development goes on (see the rules in `CLAUDE.md`).
Priority: **P1** = do soon / blocks the design, **P2** = worth doing in the next stages, **P3** = nice to have.
When an item is done, tick it and add the date: `- [x] ... (done 2026-11-02)`.

Last full review: 2026-10-26 (Stage 5b). Tests (2026-10-30, after Stage 8e): `world.gd` 210 and `fight.gd` 82 pass, 0 fail, on Godot 4.7.2.

## Agreed roadmap (set by the user, 2026-10-26)
1. **Bug fixes**: the user's bug list first (plus the bugs under "Bugs / UX" below where they overlap). Confirmed for this step:
   - Done 2026-10-27 (Stage 7d): frozen maps leaked on restart (see "Bugs / UX").
   - Done 2026-10-27 (Stage 5b.3): the user's list `stage5b_fixes_plan.md` (king size, hall steps, courtyard gate steps, rats pinned on the east
     side). See the ticked items under "Bugs / UX".
2. **Cave map and its enemies**: the blocked cave hideout becomes a new map. Planned with the user on 2026-10-27 in three sub-stages
   (story decisions now in the design doc, Era 1 "the king's lost riders"):
   - Done 2026-10-27 (Stage 6a): the cave map (`cave.gd`), its art, light, the doors to and from the town, and enemies with today's brains.
   - Done 2026-10-27 (Stage 6b): open the cage, the rider joins as an archer companion (arrows every 0.5 s), the rescue ambush with the way back blocked.
   - Done 2026-10-27 (Stage 6c): the bandit chief (charge, axe sweep, enrage at half health) in a sealed room, slingers when his fight starts,
     the return scene in the throne room (with or without the rider). Plan: `stage6c_plan.md` (its three questions answered by the user).
     The cave step is finished; it needs the user's F5 play-test (both endings, the fight with and without the rider).
   - Done 2026-10-27 (Stage 6d, from the user's play-test): the abandoned camp's fire is lit and its rats burst from the tents when you walk
     in between; blood traces in the camp and the jail (stains, drag marks, arrows, a torn tunic; stocks, whipping post, fetters, branding
     irons); the ambush is 2 bandits, then 2 slingers, then 2 waiting on the way out; staked captive silhouettes in the boss room, and the
     return to the king waits until you cut down the riders' captain, who tells what happened. Needs an F5 play-test of the look and pacing.
   - Done 2026-10-27 (Stage 6e, from the user's three pictures): the camp soaked in blood (pools, broad drag smears, spatter, bloodied tents and
     tables) and its rats coming from both tents and both tunnels; the jail rebuilt (four pens, two holding the dead, chain frames, a strap bench,
     braziers); the boss room rebuilt (the chief's hoard behind his seat, a war table, tents, palisades, an empty cage, loot instead of
     stalagmites, slingers bursting from the tents). Needs an F5 play-test: the chief fight without stalagmites, the jail ambush among the new props.
3. **Inventory, objectives and quests, squad, save, item pickups, shop** (the user's order, 2026-10-27; one stage each, 7a-7h since the
   items-and-XP discussion of 2026-10-28, tests and docs at the end of each). The user's decisions that day are in the design doc (the scientist's trail, the squad rules, saving, the HUD layout,
   era-neutral menus, "Combat balance").
   - Done 2026-10-27 (Stage 7a): the inventory and the era-neutral menu (Tab / Esc / I), item toasts, a provisional starter set of items
     (Arshan's bread and pomegranate, the king's silver), the dev tuning panel (T), and the design doc's "Combat balance" section.
   - Done 2026-10-27 (Stage 7b): objectives and quests:
     - quest steps as data (`quest.gd STEPS`, `note()`), the optional "Free the caged rider", the Quests tab with the journal and a reader;
     - the stacked HUD (objective top-left, hearts and XP under it) and place names top-right;
     - the stranger's trail: lines in both return scenes, and at the ruins boot prints, a brass box and the first scientist log.
     Needs an F5 play-test: whether the prints are easy enough to notice, and the place banners' timing.
   - Done 2026-10-27 (Stage 7c): the squad. Farnaka follows through every door of Era 1; Follow / Wait / Stop following (home spot by the
     throne) from the Squad tab or by talking to him; kept per era. Needs an F5 play-test: the town and storeroom fights with him along.
   - Done 2026-10-27 (Stage 7d): saving. Rest spots (the town well, the cook's fire, the cave's two camp fires) restore hearts and save;
     the menu's System tab (save, load, new game); one slot; each map comes back as it was left. Needs an F5 play-test of a real
     save-quit-load.
   - Done 2026-10-27 (7d follow-ups, the user's notes): the journal has its own menu tab; only well-known places are named (the cave's
     rooms aren't); "Stop following" is now Disband, refused while the story needs the companion (`quest.gd NEEDS`: Farnaka from his
     rescue until the return to the king); one autosave (rest, doors, new objective) and four slots. Needs an F5 play-test of the new
     System tab and Journal tab layout.
   - Done 2026-10-28: the items-and-XP discussion with the user (decisions in the design doc, sections 7, 8 and 9). It split the rest of
     step 3 into 7e-7h, each stopping for the user's F5 play-test. Plan: `~/.claude/plans/lets-work-on-items-linear-petal.md`.
   - Done 2026-10-28 (Stage 7e): HP 100, stamina 100 (per-move costs), focus 50 and the strong lasso (hold Q), the boss bar, Bread / Apple /
     Coins, save version 2 (old saves upgraded); and the user's bug: the captain stayed in the cave after the return. Needs an F5 play-test:
     the stamina costs in a real fight (a full combo plus a dodge is 65 of 100), the strong lasso's feel, the bars' look.
   - Done 2026-10-28 (Stage 7f): hero level (cap 10, raised only by teachers) and weapon XP (Unarmed, Lasso), XP from story steps, side
     quests and logs, enemy levels (less XP from weaker foes), ordinary foes respawn on re-entry or a rest (not bosses or scripted fights),
     the Inventory tab became the Player tab (level and bars, weapons, items); save version 3. Plan: `~/.claude/plans/do-you-know-about-jiggly-dove.md`.
   - Done 2026-10-28 (Stage 7g, straight after 7f at the user's request): Small and Large Potions, rare boss finds (the necklace and the
     armlet: a lasting bonus while carried, sellable), prices, pickups lying on the maps (the cave's coin bags among them), random drops
     (bosses fixed), the king's reward 100 coins. 7f and 7g need one F5 play-test together: the levels reached in one run, the Player tab,
     foes coming back (and the band's fire), the drop rates, the pickups' glint and spots.
   - Done 2026-10-28 (Stage 7h): the shop at Scribe Nidu's stall (`shop.gd`): talk to Nidu, "Show me your goods."; Buy (Bread, Apple,
     both potions at their `"price"`) and Sell (rare finds at their `"sell"`, a second E confirms); a coin over Nidu instead of "...".
     Needs an F5 play-test: the panel's look, the coin mark, and whether the prices feel right against the coins a run finds.
   - Step 3 is finished, and with it the agreed roadmap. The next step is the user's choice.
   - Done 2026-10-28 (Stage 7i, the user's play-test notes): slower stamina (15/s after 1.2 s); the fight starts only once the hero is
     spotted or strikes first (Farnaka no longer shoots an enemy whose "?" is rising); enemies in the fight go after the nearest of the
     hero and his companions; Farnaka has 80 HP and 50 focus, falls at 0, and stays down until a Reviving Potion (10 % HP, E beside him
     or the menu) or a rest; a 3-arrow volley on a full focus bar; on Follow he moves freely in a fight and stays with the hero out of
     one, and on Wait he holds even while hit; Small / Large Focus Potions; giving food and potions to a companion (Use on in the
     Player tab, Give item in the Squad tab); his bars over his head and on the HUD; save version 4.
     Plan: `~/.claude/plans/1-stamina-is-regenerating-snazzy-brook.md`. Needs an F5 play-test of these things:
     - Farnaka's movement in the town and cave fights;
     - how often enemies reach him;
     - the volley's strength;
     - the fallen pose and the "E Revive" tag;
     - whether 8 s of stamina refill feels right.
   - Done 2026-10-28 (Stage 7j, the user's list): three journal entries (a record of the empire on a clay tablet in the hall's library,
     a rider's last note in the cave's jail, a second scientist log by the ruins), a new "record" kind in the journal; the scorpion
     (a den of three in the west of the ruins; a slow, short-sighted guard whose sting poisons: 10, then 4 a second for 5 s, never the
     last HP, cured by a rest); and the death screen (the user's choice: pick the autosave or a slot to go on from, or New game; no
     more getting up on the map). Needs an F5 play-test of these things:
     - how the scorpion, its tail and the den read on the sand;
     - whether the sting's wind-up is easy to see and dodge;
     - whether 30 HP a sting is fair at level 2-4;
     - whether the tablet's glint and the note behind the pen's poles are easy to notice;
     - whether the death screen reads well, and loading from it.
   - Done 2026-10-28 (Stage 7k, the user's list): focus no longer refills by itself (+3 a hit, +6 more for a full combo's kick);
     "Foes slain" left the HUD for an Enemies part in the journal (each kind cut down, its description, the number slain; save
     version 5); the alarm (an enemy joining the fight brings its side within 150 px and in sight); the Antidote (20 coins at Nidu's);
     the Map tab (blank) and the menu keys I Player, M Map, Tab Squad, Esc System. Needs an F5 play-test of these things:
     - whether focus now fills fast enough for the strong lasso (25 = about 8 hits, or 3 full combos);
     - how big the alarm feels in the town (rats) and the cave (bandits);
     - the Journal tab's two parts and the Map tab.
   - Done 2026-10-28 (Stage 7l, the user's play-test notes): enemies no longer walk off mid-fight (the leash and getting stuck count only
     while an enemy isn't engaged: `combat.gd ENGAGE`); hurt rats that hid now walk home after 4 s and heal; Datis's sword side quest
     (blade and hilt in the storeroom, then ten of the band, then 80 coins) and the sword itself (key 1, slash / slash / thrust, its own
     weapon XP, the HUD's weapon box); save version 6. Needs an F5 play-test of these things:
     - fights on the road and in the cave (no more walking off; and that running away still ends a chase);
     - where the blade and hilt lie, and whether the hilt by the giant's pile can be reached without waking it;
     - the sword's feel (reach 38-42 px, 15 / 15 / 25 stamina) and how it looks in hand, swinging and at the hip;
     - the weapon box at the bottom right next to the toasts.
   - Done 2026-10-28 (Stage 7l follow-up, the user's next play-test): the weapon box became a round gold-ringed badge (fist or sword,
     one at a time, a small round "1" notched into its lower-right, always shown, in the badge's gold); Q and Shift round too ("Shift" spelled out); HP, stamina and focus bars always the
     same length; every pickup pulses, bobs and glints more, and quest parts are 2x with a light on dark maps and their name when near;
     the alarm calls the whole plan group and the storeroom's fences no longer block sight. Needs an F5 look at:
     - the badge, the "1" chip and the round Q / Shift against the reference picture (sizes, the gold, the "Shift" text fitting);
     - the blade and hilt in the storeroom (easy to spot now?) and whether the halo on ordinary drops is too much in daylight;
     - the side room: hitting one rat should bring all three.
4. (Was "Save and inventory": now part of step 3.)
5. **Stage 8: the combat test arena** (the user's request, 2026-10-28): a separate square stage to work out weapons, combos and the feel
   of a fight against any enemy or boss, then port what works into the game. The user's choices: the same project with a different
   file to run, kept light, with the tuning panel; a separate copy of the combat code.
   - Done 2026-10-28 (Stage 8a): `arena/` (`arena.tscn`, F6): the map (four columns, the dummy), `arena_combat.gd` (the copy), the arena
     panel (Tab: spawner, cheats and levels, weapon picker, what is shown), the readouts (DPS, damage numbers, the combo timeline, hit
     boxes). Plan: `~/.claude/plans/stage-8-we-will-silly-dusk.md`. Needs a play-test in the arena (F6 on `arena/arena.tscn`):
     - whether the panel's one page reads well and has what a test needs;
     - whether the combo timeline under the hero is readable, or should move to the HUD;
     - each boss in the square (the chief's charge into the columns, the giant's summon ring with no pens).
   - Done 2026-10-29 (Stage 8b, the user's order of 2026-10-29): the 8-way aim, Mouse 1 light and Mouse 2 heavy, named strings for
     the fists (LLL, LLH shoulder charge, HHH hammer fist) and the sword (LLL, LHL rising cut, HHH overheads), and the arena's own
     tuning panel (T: every move's damage and stamina, each enemy's HP and hit damage). Plan:
     `~/.claude/plans/for-dash-we-have-wiggly-quasar.md`. Needs a play-test in the arena (F6):
     - whether the diagonal aim feels right (it keeps the last keys pressed, like the dodge);
     - the new moves' numbers and drawings (shoulder, knee, hammer, rise, overhead) and the strings' pauses;
     - whether the right mouse button suits the heavy attack;
     - whether a string's name floating up is wanted for every named string.
   - Done 2026-10-29 (Stage 8c): the spear (LLL, LLH sweeping arc, HHH charging lunge), the bow (quick arrows, an LLL volley, H held
     to draw and aim, unlimited arrows) and the block on Space (fists, sword, spear; not the bow). Needs a play-test in the arena (F6):
     - the spear's reach against the sword's, and whether its narrow line feels fair;
     - the bow: the quick arrow's 10 damage, the 0.8 s full draw, the stamina drain while drawing (20 a second);
     - the block: the % let through (fists 50, spear 35, sword 30), its stamina (15 / 12 / 12), the 0.6 s of a broken guard;
     - the slow walk behind the guard (40 %).
   - Done 2026-10-29 (8c follow-up, the user's notes): every combo names itself when its last move starts; the volley is earned
     (two hits in its string, 10 focus); the giant's slam, the chief's charge and stones pierce the block, with violet warnings;
     stamina refills at half speed behind the guard. Needs a play-test: whether the volley is still too easy (or now too hard at
     range: its two arrows must have landed before it leaves), and whether the violet warnings read well over the red ones.
   - Done 2026-10-29 (8c second follow-up, the user's play-test: "the bow is hard now"): the bow blocks too, with the weakest guard
     (55 % through, 15 stamina). The parry still leaves the bow out. If the bow is still too hard, other levers are the volley
     counting arrows still in flight (so it works at range), a faster draw, or a lower drain while drawing.
   - Done 2026-10-29 (Stage 8d): Q is the weapon's own move. The fists keep the lasso, and the strong one now pulls bandits too.
     The sword has a flaming flurry (4 thrusts, the foes burn), the spear a whirlwind (360 degrees), the bow a piercing arrow; each
     costs 25 focus. The parry (Space just before a hit; not the bow, nor piercing attacks): no damage, +8 focus, the attacker
     staggers. Needs a play-test in the arena (F6):
     - whether 25 focus feels right for each special (a full LLL string gives about 15 focus);
     - the 0.15 s parry window: too tight or too loose? (tuning panel: "parry ms");
     - the burn (6 x 4 over 3 s), the whirl's 42 px, the piercer's 50 damage;
     - whether pulling bandits with the strong lasso makes the fists too strong.
   - Done 2026-10-29 (8d follow-up, the user's play-test): the specials cost 15 focus (was 25) and fire on a tap, then a 5 s
     cooldown; the strong lasso keeps its 0.6 s hold, costs 15 and shares the cooldown; the giant rat and the chief are never
     pulled. Needs a play-test: whether 5 s is the right cooldown, and whether 15 focus is now too cheap with it.
   - Done 2026-10-29 (Stage 8f, the user's choice: the special as a named finisher, using the cooldown): a Q after a combo's second
     swing ends it with the weapon's special. It does 1.5 x damage, costs 10 focus and uses the 5 s cooldown. The finishers are fists
     LLQ / HHQ, sword LLQ / LHQ / HHQ, spear LLQ / HHQ and bow LLQ. Needs a play-test:
     - whether the timing of Q in the chain window feels natural;
     - whether 10 focus with 1.5 x makes finishers always better than plain specials (that is the point, but by how much);
     - each finisher's twist (Inferno's 5 thrusts and long burn, the Wide whirl's 54 px, the Bull catch's reach).
   - Done 2026-10-29 (the user's request): a **No Q cooldown** cheat in the arena panel's HERO part (`arena_combat.gd no_q_cooldown`).
     While it is on, the specials, finishers and strong lasso never wait, nor does the lasso's own throw; focus is still spent unless
     Endless focus is on too. The readout's Cheats line shows "no Q cd".
   - Done 2026-10-29 (the user's play-test): drawing the bow no longer roots the hero. He walks at 60 % (`arena_player.gd DRAW_WALK`),
     walking turns the aim, and a short dotted reticle shows the aim (`arena_combat.gd RETICLE`). The swing meter's red hit window
     stays as it is (the user's choice). 60 % was too fast, so it is 50 % now, and the reticle (4 dots of 2 px) shows for the quick arrows too (the user, same day). Needs a play-test: whether 50 % feels right, and whether kiting with the bow is now too safe
     (if so, a slower walk late in the draw, or more stamina drain while walking).
   - Done 2026-10-30 (**Stage 8e**, the user's request: "all combo changes look good, add those in game for now"): the arena's
     combat ported into `scripts/combat.gd` and `scripts/player.gd` (every weapon's strings, the 8-way aim, Space block and parry,
     Q specials and finishers, the names floating up), the menu's **Combos** tab before System, the spear (800) and the bow (1200)
     at Nidu's stall. The user's choices: the strong lasso pulls bandits; the sword's flurry bleeds while the blade still shows fire;
     unlimited arrows. Plan: `~/.claude/plans/all-combo-changes-looks-squishy-valiant.md`. Needs an F5 play-test:
     - the mouse attacks and Space block on the story maps (the bandits on the road, the giant, the chief and his slingers);
     - whether everything at once is too much for a new player before the teachers stage (section 13: teachers unlock skills);
     - the bleeding (6 x 4 over 3 s) and how the fire-lit blade reads;
     - the prices: how long saving 800 and 1200 coins takes;
     - the Combos tab: whether it reads well, and whether it wants a key of its own (C is free in the game).
   - Done 2026-10-30 (8e follow-up, the user's request): a finished string floats up by its name only ("Shoulder charge", not
     "LLH  Shoulder charge"). The arena still shows the letters.
   - Next: the teacher-taught moves, the timing evaluation and the enemy punishment. Details: "The next combat plan" under
     "Next-step ideas".

Items below that don't fit a roadmap step stay as suggestions until the user picks them.

---

## Decisions pending (the user decides; then they move into the design doc)
- [x] **The item list and where items lie.** Decided by the user on 2026-10-28 (design doc sections 7-9): Bread, Apple, Small and Large
      Potions (more HP per coin the higher the tier), plain Coins, rare boss finds that can be sold, random drops with fixed boss drops.
      The placement on the maps is in the 7g plan (the coin bags in the chief's room become pickups; the riders' supplies in the camp).
- [ ] **P2. The arena's spear, bow and block numbers (Claude's defaults in 8c, not the user's choice).** These are:
      - the spear: jab 15 / long thrust 30 / sweep 20 / drive 25 / lunge 35 damage;
      - the bow: a quick arrow 10, the volley 3 x 10, a full draw 40 (35 % of that when let go at once), 0.8 s to a full draw, 20
        stamina a second while drawing, and only a half draw or more staggers;
      - the block: about 70 degrees either side of the aim; bow 55 % through / 15 stamina (the user asked that the bow block; the
        numbers are Claude's), fists 50 % / 15, spear 35 % / 12, sword 30 % / 12; a
        broken guard lasts 0.6 s; stamina refills at half speed behind the guard (the user asked that it refill; the half is
        Claude's); 40 % walking speed;
      - the volley (the user chose "earned by aim, costs focus"): two earlier hits, 10 focus, a plain arrow otherwise;
      - which attacks pierce: the user chose the giant's slam, the chief's charge and stones (done in the 8c follow-up). The violet
        `PIERCE_COL` is Claude's.

      Change them in `arena_combat.gd` (or live on the tuning panel, T).
- [x] **P2. The strong lasso pulling heavy foes (arena, 8d) vs the design doc.** Decided by the user on 2026-10-29 (Stage 8e): the
      strong lasso pulls every non-boss, bandits too, in the game as in the arena; heavy foes resist only the plain throw. Written
      into the design doc, section 7. (`rat.gd bind()` and its "bound" state are unused since; see "Code health".)
- [ ] **P3. The arena's specials and parry numbers (Claude's defaults in 8d).**
      - **Cost and cooldown:** 15 focus each and a 5 s cooldown, shared with the strong lasso's 0.6 s hold. The user asked for a
        lower cost, a cooldown and the lasso's hold; the numbers are Claude's.
      - **Specials:** flurry 4 x 10 + burn 6 x 4; whirl 30 within 42 px; piercer 50.
      - **Parry:** a 0.15 s window, +8 focus; piercing attacks can't be parried.
      - **Focus:** a special's hits give none.
      - **Finishers (8f):** 1.5 x damage and 10 focus. Their twists are Claude's: Lasso yank / Bull catch (1.3 x reach), Blazing
        flurry / Rising blaze (stun) / Inferno (5 thrusts, a 10-tick burn), Wide whirl (54 px) / Vaulting whirl (a dash), Piercing
        volley (3 arrows).
- [x] **P2. A flame sword in Achaemenid Persia? (historical care, pillar 6; raised 2026-10-29).** Decided by the user on 2026-10-29
      (Stage 8e): in the game the flurry makes foes **bleed** (`combat.gd BLEED`), but the blade still flickers with fire while it runs,
      so the special looks different from plain swings. The arena's flurry still burns, for comparison. Written into the design doc,
      section 7. The fire on the blade is now only a visual cue; if it ever needs a story reason, see the P3 note below.
- [ ] **P3. The fire on the sword's blade during the flurry** (Stage 8e, the user's choice to keep it as a visual cue). It still reads
      as fantasy in Era 1. If that matters later, other cues that set the special apart could be a bright blade trail, speed lines, or
      a red flash on each thrust. Names like "Inferno" and "Blazing flurry" go with the fire.
- [x] **The bow's ammunition vs the design doc** (raised and decided 2026-10-29, Stage 8e): the user chose unlimited arrows; the design
      doc's "ammunition balanced to avoid unlimited easy damage" became the stamina a draw costs and the earned volley (section 7).
- [ ] **P2. Weapon moves or fighting-game chains (the user isn't sure yet).** (2026-10-28: to be tried in the arena first as combo strings and
      teacher-taught special moves; see "The next combat plan" under "Next-step ideas". 2026-10-29: the arena now plays named light /
      heavy strings (Stage 8b), with a special on Q to come in 8d. 2026-10-30, Stage 8e: the game plays the named strings too, every one
      open from the start "for now"; what stays open is which teacher teaches what.) Weapon XP only makes a known weapon stronger (section 13: teachers
      unlock skills). Proposal: a weapon level makes a move learnable, and a teacher teaches it (Datis for Unarmed: a fourth hit, a charged
      kick, or a choice of combo strings in the Player tab).
- [ ] **P2. Which teachers raise the level cap, and how far** (the cap starts at 10; since 7f `progress.gd raise_cap()` and
      `raise_weapon_cap()` exist, with no caller yet: the first teacher's TALK entry will call them). Weapon caps (5) work the same way;
      a weapon's `WEAPONS "xp"` list needs more totals before its cap can go above 5.
- [ ] **P2. Should a teacher unlock the strong lasso?** Since 7e it is available from the start, like the combo. Section 13 says teachers unlock
      skills; Datis (or a herder in the town) could teach it with a short task.
- [ ] **P3. Coins per era.** The money is plain yellow "Coins" for now (the user's decision); each era may get its own coins later.
- [ ] **P3. The shop's rules (Claude's defaults in 7h, not the user's choice).** Stock never runs out; all four healing items are on sale
      from the start (a Large Potion as soon as you have 80 coins); only rare finds can be sold (not food); one item per E; nothing sold
      can be bought back. Change any of them in `shop.gd SHOPS` / `buy()` / `sell()` if you prefer otherwise.
- [ ] **P3. The sword quest's small rules (Claude's defaults in 7l, not the user's choice).** These are:
      - Datis asks only after the hero has met the king (stage 2), so the "?" doesn't pull a new player away from the main road;
      - "ten bandits" counts bandits, slingers and the chief (the band), not rats or scorpions;
      - the reward is 100 XP and 80 coins until the sword skills exist;
      - the blade lies in the storeroom's side room, the hilt beside the giant's pile;
      - the sword's numbers: 20 / 20 / 35 damage, 15 / 15 / 25 stamina.
      Change them in `dialogue.gd TALK "datis"`, `quest.gd SIDE`, `storeroom.gd PICKUPS` and `combat.gd SWORD_COMBO`.
- [ ] **P2. Does Datis handing over the sword fit section 13?** The rule is "teachers unlock skills; weapons do not automatically grant
      mastery". Datis is a teacher and gives a basic three-swing combo at weapon level 1, with the skills later; that reads as his first
      lesson. Confirm, or have the combo start weaker until he teaches it.
- [ ] **P3. Poison can't kill (Claude's default in 7j, not the user's choice).** A poison stops at 1 HP, so a sting can't finish the hero
      after he has walked away; only the next hit can. Since a fall now loads a save, a death by poison while walking off would
      feel unfair. Change `combat.gd _update_poison()` (the `b.hp - 1`) if poison should be able to kill.
- [ ] **P3. The death screen's small rules (Claude's defaults in 7j).** These are:
      - the autosave is listed first and picked, even when a slot is newer (each row shows its time);
      - New game needs no second E there (nothing is lost after a fall; the saves are kept);
      - there is no Quit row (the window can be closed).
      Say if any should change (`death.gd _open()` / `resume()`).
- [ ] **P3. Who tells the king about the stranger when the rider stayed caged?** The design doc now says the captain's account reaches the king.
      That is Claude's default from the 7a plan, not the user's own choice; change it if you prefer someone else (the king's own scouts?).
- [ ] **P1. Who rules here: "King Rostam" or someone else?** Rostam is the legendary hero of the *Shahnameh* (written about 1000 CE), not an Achaemenid
      king. At a provincial castle on a trade road in 550–330 BCE, a *satrap* (governor) or a local noble would be more credible.
      Renaming is cheap now (`dialogue.gd PEOPLE` and `SCENES` (the 6c return says "the house of Rostam"), `quest.gd TRACKER`).
- [ ] **P2. The lasso is currently a starting tool.** This settles the design's open decision "starting tool or early unlock" by default. Confirm or change it.
- [ ] **P2. Concept art direction.** `Untitled.png` and `Four-Quadrant Pixel Fantasy Map.png` show Egyptian pyramids and a sphinx (Era 1), a Mesoamerican-style step
      pyramid (green) and an Atlantis-like sunken city (blue). They don't match the design (Achaemenid Persia, an Indian Ocean port, Nalanda).
      Fine as mood pieces, but they shouldn't guide era props.
- [ ] **P2. Target in-game sprite size.** The `Sprites/StandStill` PNGs are 256x384, while the code-drawn hero is about 16x24 on a 480x270 screen.
      Choose the target size (e.g. 24x36 or 32x48) and the number of directions (the game uses 4, the art has 8) before importing.
- [ ] **P2. Style rule for PNG art next to code-drawn art.** The statue PNG (2026-10-27) has finer shading and about 32 colours, while the code-drawn
      props use an outline plus three tones. Before character PNGs arrive, decide a rule (e.g. palette size, outline colour, max detail per 16 px)
      and add it to `prep_prop.py` as defaults, so imported art doesn't drift from the hand-drawn look.
- [ ] **P3. Combat feel at the start.** The hero starts with a full punch-punch-kick combo. The design says "inexperienced; a simple shove or evasive move".
      Decide whether the combo is taught (e.g. by Datis) or stays as the baseline.

## Design gaps (design doc vs what is built)
- [ ] **P1. Scientist logs and clues.** This is the core progression mechanic in the design. Since 7b there is a first one: `dialogue.gd LOGS`
      (logs and clues), the journal in the Quests tab with a reader, and the ruins' torn page, brass box and prints. Since 7j (2026-10-28)
      a second page by the scorpions' den (optional; it hints at why he came: the tribute counts from the east) and two records of the
      era (the library's tablet, the jail's note). Still to come: more logs (one per major step of the scientist's trail), and logs that
      unlock something (a route, the next era) rather than only an objective. The second page could be the one that points onward,
      once the next area is decided.
- [ ] **P2. Teachers and skill unlocks.** No teacher exists, and all skills are available from the start. The training yard (dummy and rack) and Veteran Datis
      already fit a first teacher, and since 5c.1 the dummy reacts to hits (`level.gd hittables`), so a lesson like "land the full combo on the dummy" is easy.
- [x] **XP does nothing.** Hero level (+10 HP, +10 stamina, +5 focus each), weapon XP, XP from story steps, side quests and logs, enemy
      levels, a cap raised by teachers (done 2026-10-28, Stage 7f). Skill points are not planned: teachers unlock skills.
- [ ] **P2. Rewards beyond XP.** The design calls for supplies, keys, maps and clues. Since 7g (2026-10-28) the bosses leave fixed rare
      finds, the others random drops, and supplies lie on the maps. Keys and clues as rewards are still open (a jailer's key, the chief's
      seal ring).
- [ ] **P2. Weapon XP is not cut against weak foes.** Kill XP shrinks when the hero is above the foe, but weapon XP doesn't, so with
      respawning a player can train Unarmed (250 weapon XP, about 170 punches on rats) or the Lasso on the town's rats. Weapons stop at
      level 5, so the gain is small; if it matters, scale `combat.gd _weapon_xp()` by the same `progress.gd kill_xp()` factor.
- [ ] **P3. A level-up refills the bars mid-fight.** The user's rule ("fills them") means a kill that levels the hero in a boss fight is
      a full heal. Watch it in the play-test (the chief at level 4-5); if it's too kind, refill only out of combat.
- [ ] **P3. Drops pile up.** Drops never vanish (as planned for 7g), and respawned foes roll again, so the town road can collect coin and
      bread piles over a long session (each is a small prop and is saved). If it shows, merge a new drop into a pile of the same item
      nearby, or cap the piles per map.
- [ ] **P3. Resting by the band's fire doesn't bring back the bandits around it.** Three of them stand within `RESPAWN_CLEAR` (160 px)
      of the fire, so they wait for the next time the hero walks into the cave. That's the safety rule working; mention it if the
      play-test finds it odd.
- [ ] **P3. Picking something up is quiet.** Only the "+N" toast shows. A small sparkle (and a sound, once there is audio) would make it
      feel better.
- [x] **Saving.** Rest spots and the menu's System tab, one slot (done 2026-10-27, Stage 7d).
- [ ] **P3. More from saving.** Several slots and the autosave on doors are done (2026-10-27, 7d follow-ups). Not yet: a title screen with
      Continue (needs a test flag, since the suites build `main.tscn` directly; the newest slot by `saved_at` would be the one to continue),
      the giant rat's "already summoned" (it can summon again after a load), and which sleeping groups were awake (they sleep again;
      harmless under the healing rule).
- [x] **The autosave can catch a bad moment.** A door autosave on one heart keeps one heart. The user's decision (2026-10-27): keep it; a
      save keeps the hearts the hero had, and loading (also after dying) starts with them. Revisit with the HP-system rework the user has
      planned. (Since 7e the hero has 100 HP; the rule is the same: a save keeps the HP he had.)
- [x] **Couldn't rest at the band's fire** (the user's play-test, fixed 2026-10-27). The rest rect only covered the south side of the fire,
      and a fleeing or cowering rat anywhere counted as "after you" for good. The rect is now a ring round the fire, and `rest_open()` uses
      `rat.gd hunting()`. Lesson for new rest spots: the rect must surround the prop on every walkable side.
- [x] **Rest prompt with words, the Squad tab after the reference picture, A/D inside an open choice** (the user's notes, done
      2026-10-27). Needs an F5 look at the new Squad tab and the "E Rest" tag.
- [x] **Short rest notices ("Game saved." / "Enemies nearby.") and Quit game in the System tab** (the user's notes, done 2026-10-27).
- [x] **Companion HP and stats (the user's plan).** Done 2026-10-28 (Stage 7i): HP 80 and focus 50 on the Squad tab, his bars over
      his head and on the HUD, falling and the Reviving Potion, and giving him food and potions. More stats (armour, gear) come with
      equipment; `squad.gd MATES "stats"` and `menu.gd _stat()` are where new lines go.
- [x] **Farnaka shot before a fight began** (the user's play-test). He picked targets with `rat.gd after_hero()`, which is already true
      while an enemy's "?" meter rises. Now `in_fight()` (spotted, or the hero struck first) decides (fixed 2026-10-28, Stage 7i).
- [ ] **P2. Reviving or feeding a companion from the paused menu is free mid-fight** (like eating, below). E beside him is the risky way;
      the menu's Use on and Give item pause the game. Options: let the menu give items only out of a fight (`combat.fighting()`), or
      give the potion a short use time while the game runs.
- [ ] **P2. Enemies rarely catch Farnaka on Follow.** He backs away at 74 px/s from enemies within 60 px, faster than a rat (50) or a
      bandit (54), so on Follow mostly the slingers, the slam and the chief's charge reach him; on Wait he is caught. Watch the play-test;
      to make him easier to reach, lower `RIDER.speed` in a fight or `keep_min`.
- [ ] **P3. Should a companion heal slowly out of a fight?** Like the hero he heals only from items, a rest, or "You fell" (Claude's
      default in 7i). A slow heal after a fight (a few HP a second) would save potions and coins.
- [ ] **P3. The volley on the tuning panel.** `RIDER "focus_per_hit"`, `"volley"` and `"hp"` are constants only; one RIDER row on the T
      panel would help tune them in the play-test.
- [ ] **P3. Focus and Reviving Potions as drops.** Since 7i they are only sold at Nidu's. A rare Small Focus Potion from slingers (they are
      the band's specialists) would fit `combat.gd DROPS`.
- [ ] **P3. A lunge hurts only the one it was aimed at.** Since 7i a rat's or a bandit's lunge hurts its `foe`; the hero standing in the
      path of a lunge aimed at Farnaka is not hit. Simple and fair for now; area attacks already hurt everyone inside.
- [x] **Fewer rest spots** (the user's notes, done 2026-10-27): only the town well and the cave's band fire (before the chief) remain,
      and a rest spot is only there while no enemy is after the hero (`level.gd rest_open()`). Needs an F5 play-test: the band's fire
      opens only once its four bandits are dealt with or haven't noticed you.
- [ ] **P3. "Autosaved." on every door may be noisy.** It shows in the middle of the screen like the rest notice. A small corner icon
      would be quieter; see how it feels in the play-test.
- [x] **Group alerts.** An enemy that joins the fight brings the rest of its side (rats with the giant, the band, the scorpions) within
      150 px and in sight (done 2026-10-28, Stage 7k, `combat.gd ALARM` / `SIDE`, `alarm()`). Still open: scouts as their own role
      and independent guard / bandit territories (design doc "Independent Factions").
- [ ] **P3. The alarm's small rules (Claude's defaults in 7k, not the user's choice).** These are:
      - only the same side joins (a bandit's alarm doesn't wake rats);
      - the radius is 150 px, and a wall between them stops it;
      - those it calls don't call others in turn, so one alarm never sweeps the whole map;
      - but every awake member of its `enemy_plan()` group joins, however far (added 2026-10-28 after the user's storeroom report);
      - sleeping groups and bosses keep their own wake-ups;
      - a foe killed before it noticed the hero raises no alarm (a quiet kill stays quiet).
      Change any of them in `combat.gd ALARM` / `SIDE` / `alarm()`.
- [ ] **P3. Focus can run dry between fights.** Since 7k it fills only from hits (the user's rule), and a rest fills it. A fight with
      an empty bar has no strong lasso until 8 hits land; the Small Focus Potion (30 coins) is the way round it. Watch in the play-test.
- [ ] **P2. Reward for avoiding fights.** Stealth and clever avoidance give nothing yet (design 9 "Rewards and balance").
- [ ] **P3. Courtyard guard posts.** The reference image has guards at the fountain, the armoury and the hall doors. Courtyard guards only patrol or stand at
      the bridge; one standing at the armoury (with a line about the missing men) would also tie into the king's quest.
- [ ] **P3. Local motivation for the bandits.** They just pace the road. A line from a guard or a camp prop would give them a reason (design 5 type B).
- [x] **Scorpion enemy.** A type A den of three in the west of the ruins; a tail sting with a long wind-up that poisons (done 2026-10-28,
      Stage 7j, the user's request; code-drawn, the `Sprites/StandStill/Scorpion` art is still unused).
- [x] **An antidote.** A vinegar, honey and herbs draught at Nidu's for 20 coins (`items.gd "antidote"`, `"cure"`, `main.gd use_item()`)
      (done 2026-10-28, Stage 7k, the user's request).
- [ ] **P3. The shop's Buy list can't scroll.** Since 7k Nidu sells eight goods, which exactly fill the list; a ninth would be cut off.
      Scroll the list with the selection (as the journal does) before adding more.
- [ ] **P3. Poison on the tuning panel.** `combat.gd POISON` (4 HP a tick, 5 ticks) is a constant only; one POISON row on the T panel
      would help tune it in the play-test.
- [ ] **P3. A running poison isn't saved.** A door's autosave during a poison drops it on load (Claude's default; the count is a few
      seconds). If it matters, save `poison` with the hero and the squad (a `save.gd VERSION` bump).
- [x] **The cave hideout was blocked.** It is now its own map, `cave.gd`, reached through the mouth in the north-east cliff (done 2026-10-27, Stage 6a).
- [x] **The quest tracker knew nothing of the cave.** `quest.gd STEPS` now runs the whole slice, with "Free the caged rider" as an optional
      objective (done 2026-10-27, Stage 7b).
- [x] **Nothing followed the return to the king.** The stranger's trail to the ruins (decided by the user; done 2026-10-27, Stage 7b). The slice
      now ends at "The trail goes on..."; what comes after the ruins (the log points to "the coast", a placeholder) is the next story step.
- [ ] **P3. The ruins' boot prints are faint.** They are drawn as dents in the sand at 42 % strength, so they read as tracks rather than
      decoration, but they may be easy to miss in the play-test. If so: a little darker, or a rider shout ("Look, the sand!") when the hero
      first walks near them.
- [ ] **P3. Place names are placeholders.** Waystation Road / Town, The Ancient Ruins (`PLACES` in each map). Since 2026-10-27 only
      well-known places are named (the user's rule), so the cave's rooms have none. Rename freely; a real Old Persian name for the
      waystation would add flavour.
- [ ] **P3. Weapons and inventory.** Since 7l there is a sword (Datis's side quest, key 1). Era-weapon forfeiting (design 7) is still
      open. There are no equipment slots: key 1 toggles between the two, which won't scale past a third weapon (a weapon wheel or keys
      1-4 then).
- [ ] **P3. Weapon XP against weak foes applies to the sword too** (see "Weapon XP is not cut against weak foes"): respawning rats can
      train it.
- [ ] **P3. The bandits' scimitars next to the hero's straight sword.** Now that the hero has a sword, the bandits' curved blades
      (see "Bandit weapons" under Historical care) are easier to compare.
- [ ] **P2. Eating from the paused menu is a free heal mid-fight.** Since 7a, Tab -> E heals at any moment, even with the chief's axe coming down.
      Options once food is easy to find: a short eating time while the game runs, or no eating while an enemy is after you (`rat.gd after_hero()`).
      7g's potions (75 and 150 HP) make this stronger. A quick-heal key (drinks the smallest potion that is enough, with a short drinking time
      while the game runs) would fit a Hades-like fight better than pausing. Since 7h the shop sells potions without limit, so coins
      now turn straight into paused mid-fight heals (selling the armlet alone buys three Large Potions). Since 7i the same goes for focus
      potions and for items given to a companion (see "Reviving or feeding a companion from the paused menu").
- [ ] **P3. The tuning panel has no enemy damage.** It covers HP, XP, the hero's / rider's damage, and since 7e stamina and focus. Enemy damage is
      spread over several keys per enemy (`dmg`, `slam_dmg`, `charge_dmg`, `sweep_dmg`); one "+/- HP per hit" row could be added if wanted.
- [ ] **P2 (the user's idea, 2026-10-28). Maps for sale.** A shop sells an area's map; buying it shows that area in the menu (or as a
      minimap) with its places and doors marked. The shop exists since 7h: a map would be a new item kind (bought once, never sold),
      added to a keeper's `"sells"` in `shop.gd SHOPS`; the work is the map view itself. Since 7k the menu has a blank Map tab (M)
      waiting for it (`menu.gd _draw_map()`).
- [ ] **P3. The journal's Enemies list starts empty for old saves.** A save from before 7k kept only the total of foes slain, so the
      list fills from the next kill on. Harmless; mention it if the play-test runs on an old save.
- [ ] **P3. Enemy entries are placeholder words** (`dialogue.gd FOES`), like the logs. Rewrite them freely.
- [x] **Focus-refill items.** The Small and Large Focus Potions (+25 / +50, 30 / 50 coins at Nidu's), the user's "mana potions" (done
      2026-10-28, Stage 7i).
- [ ] **P3. Nidu's stall still shows pots.** Since 7h it sells bread, apples and healer's flasks, but `Props.stall_striped(..., 0)` draws a
      row of clay pots. A goods kind with loaves, apples and two waxed flasks (`props.gd stall_striped`, one more `goods` value) would show
      what is for sale, and the waxed flask is already the Small Potion's icon.
- [ ] **P3. Buying several at once.** Each E buys one, so stocking up on bread means many presses. A held E that repeats, or a count
      chosen with A/D before E, would help if the play-test finds it tedious.
- [ ] **P3. Tests for 7e-7h's new systems.** The suites don't cover stamina, focus, the strong lasso, the boss bar, levels, weapon XP,
      kill XP by level, drops, pickups, the save upgrades or the shop (throwaway checks passed 21/21 for 7e, 46/46 for 7f-7g and 33/33
      for 7h on 2026-10-28). New tests only when the user asks; a "hero bars and levels" section in `fight.gd` and a "pickups, drops and
      the shop" one in `world.gd` would do. Since 7j the same goes for the scorpion and its poison, and the three new journal spots
      (a throwaway check passed 51/51); a "scorpion den" section in `fight.gd` would cover the sting, the ticks and the 1 HP floor.
      Since 7k: focus from hits only, kills by kind, the alarm, the antidote and the menu keys (a throwaway check passed 26/26).
- [ ] **P3. Loading from the death screen isn't tested.** It calls the menu's own `main.gd load_game()` (a scene reload). The suites
      build `main.tscn` under the root rather than as the current scene, so a reload can't run there; the suites check that the screen
      opens and what it lists, then stand the hero up by hand (`suite.gd get_up()`). Making the suite's main the current scene would let
      a test load a slot for real.
- [ ] **P3. The ordinary lasso is now thrown when Q is let go** (so a held Q can become the strong lasso). A quick tap feels the same, but
      watch in the play-test whether it feels late; the alternative is a separate key for the strong lasso.
- [ ] **P3. Tuning values go into the game by hand.** Today: E on the panel prints them, and they are copied into the `combat.gd` constants
      (README "Where to tune"). A key that writes `user://tuning.json`, loaded by the dev build at start, would let a tuning session carry
      over between runs without editing code (the constants stay the shipped values).
- [ ] **P2. The rider now fights everywhere (since 7c).** He used to stay in the cave; now he follows through every door, so the town's
      bandits and rats and the storeroom's giant rat (12 HP: 6 s of arrows alone) are easier with him. Watch the play-test; options: a
      lower `RIDER.dmg` / slower `shot_every` outside the cave, or leaving him as he is (Wait / Disband are the player's choice).
- [ ] **P3. Companions walk through props.** Farnaka walks the hero's own trail, which is always walkable; but when he is called to follow
      from his home spot on the same map he walks straight to the hero, through anything in between (the hall's steps are clear, so it
      doesn't show there yet). A short straight-line check, or snapping him to the hero, would do if a home spot ever sits behind a wall.
      Since 7i he also moves on his own in a fight and walks back afterwards. He steers round props, but there is no pathfinding: behind a
      long wall he gives up after 1 s and joins the hero at once (a visible jump). A small grid path (the maps have a collision grid) would
      smooth it if the play-test shows the jump.
- [ ] **P2. The rider's arrows are strong.** One arrow (1 damage) every 0.5 s is about half the hero's own damage again: in a throwaway check his arrows
      alone cleared the 4-bandit ambush in about 18 s while the hero stood still. Fine for the ambush; against the 6c chief (20 HP, chosen without the
      rider in mind) he adds about 2 damage a second, so the fight with him may be short. Tune after the play-test (`CHIEF.hp`, or `RIDER.shot_every` /
      `dmg` in `combat.gd`); the slingers also soak some of his arrows.
- [x] **The rider shot sleeping enemies too.** The user decided he shoots only enemies that are awake and after the hero (`rat.gd after_hero()`,
      `rider.gd _pick_target`); now in the design doc (done 2026-10-27, Stage 6c).

## Historical care (Era 1, about 550–330 BCE)
- [ ] **P2. Library props are anachronistic.** Bound books on bookcases and a terrestrial globe (`castle_props.gd bookshelf/globe`, `hall.gd _library`)
      are much later. Period-credible options: clay tablets on shelves, scroll baskets and leather scrolls, writing boards, a seal-stamp table.
      Since 5c this is more visible: Scholar Utana talks about clay tablets and leather scrolls while standing in front of bound books.
      Since 7j the desk holds a clay tablet the player reads, right beside the globe, so the contrast is now part of a story moment.
- [ ] **P2. The library's tablet names Darius** (7j). Its record (Cyrus's conquests, Darius's satrapies and road, Hindush's gold dust)
      sets the Era 1 slice in Darius I's reign or later (Hindush joined the empire around 515 BCE). That fits the design's 550-330 BCE
      and the road stations, but it is a choice: confirm it, or make the record end with Cyrus if the slice should be earlier.
- [ ] **P3. Who can read the tablet and the note?** Utana reads the tablet out (its "by" line says so); the jail's note is in Aramaic,
      and the hero reads it as he understands everyone's speech. If the game ever makes language a theme, these are the places to show it.
- [ ] **P2. Bandit weapons.** The bandits carry curved scimitars (`rat.gd _draw_bandit`), but the curved sabre is much later. An *akinakes* short sword,
      spear, bow, sling or *sagaris* axe would fit. More visible since 6a: the cave adds 8 more bandits. The cave's weapon rack already shows spears.
      Since 6c the chief carries a *sagaris* and his slingers a sling, so only the ordinary bandits still have the scimitar (`rat.gd _draw_bandit`).
- [ ] **P3. Review the castle props.** The portcullis and the long dining table with chairs are worth a quick check against Achaemenid-era references
      before more interiors are built on the same props.

- [ ] **P3. The statue itself.** Free-standing heroic statues of warriors aren't typical for Achaemenid Persia (relief carving on walls and stairways was
      the norm, e.g. the guards at Persepolis). The bearded figure, round shield and spear fit; a relief-carved guard wall, or a figure in a
      fluted tiara/hood with a wicker shield, would be more period-credible. The eagle emblems were removed on 2026-10-27.
- [ ] **P3. The new houses are empty.** Since 5c.2 the town has four houses but only Arshan, Nidu and the potter suggest who lives there. A woman
      at the water jar or a child on the stair would make them feel lived-in (ambient NPCs with a line or two each).
- [ ] **P3. The dummy's painted target.** The red ring-and-dot (from the user's reference, 5c.1) reads as a modern archery target. A plain stitched
      leather pad or a wicker shield tied to the chest would be period-neutral, if you want it to match the rest of the era care.
- [ ] **P3. Give the seated king a sceptre and a lotus.** Achaemenid audience reliefs (e.g. the Persepolis Treasury reliefs) show the enthroned king
      holding a long sceptre in one hand and a lotus flower in the other, with his feet on a footstool. A thin gold sceptre from his right hand to
      the floor (`castle_props.gd king_seated`) and a footstool on the throne base would make him read as a Persian king at a glance.
- [ ] **P3. A scribe selling a spear and a bow** (Stage 8e). Nidu's is the only stall, so the weapons are sold there for now. A smith,
      or the garrison's quartermaster near the training yard, would fit Era 1 better; `shop.gd SHOPS` takes a second keeper as data.

## Bugs / UX
- [ ] **P2. No attack without a mouse** (Stage 8e, the arena's keys in the game). Light and heavy are Mouse 1 / Mouse 2 only, and Space
      now blocks, so a player on a keyboard alone (or a laptop touchpad) can't attack well. Keyboard keys for light and heavy (e.g. J / K,
      though J opens the journal now) would need the user's choice of keys.
- [ ] **P3. A press during a special's recovery is dropped** (seen in the 8e check). A light or heavy pressed during a special (outside
      the strings) is buffered but never played, since the special's own pause runs after it. The same in the arena; maybe fine, but a
      player mashing through a flurry may expect the next string to start.
- [x] **The storeroom's side-room rats didn't all join a fight** (the user's report, fixed 2026-10-28, Stage 7l follow-up). Fence rails
      blocked sight and the far rats were past the alarm's 150 px; now fences are `low` and the plan group joins as one.
- [x] **The stamina bar outgrew the HP bar after a level-up** (the user's report, fixed 2026-10-28). All three bars are now `BAR_W`.
- [x] **Quest parts on the ground were hard to see** (the user's report: the sword's hilt, fixed 2026-10-28). Halo, 2x size, a light on
      dark maps, the name when near.
- [ ] **P3. Other low things may still block sight.** Only the storeroom's fence rails were made `low` here. The cave's stake palisades,
      the training yard's fence and the jail's pens may stop an alarm or a rat's eyes where a player expects them to see over. Check
      each `solid()` that draws a rail or a fence.
- [ ] **P3. The hint line doesn't mention key 1.** "WASD move  Space attack ..." at the start says nothing of the sword switch; a short
      "1 sword" (once the sword is carried) would help. The "1" chip on the badge now always shows, which may be enough.
- [x] **The placeholder portrait spilled out of small boxes** (found while building the shop, fixed 2026-10-28, Stage 7h). The silhouette
      in `dialogue.gd draw_portrait()` kept its 56 px sizes in any box, so in the Squad tab's 31 px cards the head and neck ran about 8 px
      below the frame. It is now drawn in a 56 px square and scaled to the box. Needs a look at the Squad tab in the play-test.
- [x] **The captain stayed in the cave after the return** (the user's report, fixed 2026-10-28, Stage 7e). Once cut down he goes back with
      the hero (the king says he is with the healers); the cave now shows his stake empty when the hero comes back or a save is loaded
      (`cave.gd _captain_gone()`).
- [ ] **P3. See the captain again later.** He could be found at the healers (the courtyard or the hall) with a line or a small reward,
      which would also give the "with the healers" line a place.
- [x] **Game-over text was wrong outside the town.** It always said "Back to the waystation gate…". The death screen (7j) replaces it and
      names the place where the hero fell (done 2026-10-28).
- [x] **The objective never updated after meeting the king.** `hall.gd _intro_finished` notes `met_king`, and the objective moves on to the
      cave (done 2026-10-27, Stage 7b).
- [x] **Enemies walked off mid-fight** (the user's play-test, on the road and in the cave; fixed 2026-10-28, Stage 7l). The leash ended a
      chase whoever stood next to the enemy, and in the cave a moment stuck on a tent did too. Now both count only while it isn't engaged
      (`rat.gd engaged()`, `_give_up()`, `combat.gd ENGAGE`); 1.75x the leash still ends any chase.
- [x] **Hurt rats kept their part-empty bar** (the user's screenshot; fixed 2026-10-28, Stage 7l). A rat that fled hid for good, and
      walking home healed only an unhurt one. Now it walks home after `RAT "calm_time"` (4 s) with the hero away, and home always heals.
- [ ] **P3. An engaged enemy stuck behind a wall jitters for up to 4 s** (`ENGAGE "stuck_max"`) before giving up, trying both sides.
      Pathfinding (see "Enemies still have no pathfinding") would fix the root; watch it in the cave's camp.
- [x] **Foes slain on the HUD.** Moved into the journal's Enemies part (done 2026-10-28, Stage 7k, the user's request).
- [ ] **P3. The HUD hint line doesn't mention mouse attacks.** It says "Space attack", but a left click also attacks (`combat.gd _mouse_click`).
      Since 7a it also leaves out B and G (dev keys, still in the README) to make room for "Tab menu".
- [x] **Old tests don't give a clear pass/fail.** They're now real asserts inside `tests/world.gd` and `tests/fight.gd` (done 2026-10-27).
- [x] **Frozen maps leaked on restart.** `main._exit_tree()` now frees the maps you left, so R and the menu's Load no longer leak them
      (done 2026-10-27, Stage 7d; loading made it urgent). `tests/suite.gd _free_main()` still frees them first, which is safe.
- [x] **The king was about 2.4x a person.** Redrawn at person size, about 48 px with the tiara; the throne back is 8 px lower (done 2026-10-27).
- [x] **The hall steps didn't read as stairs.** `terrain.gd steps()` (treads, lit lips, shaded risers), a stepped carpet with gold stair rods, and
      side walls with newel posts (`castle_props.gd stair_cheek`, solid) (done 2026-10-27).
- [x] **The courtyard gate steps didn't read as stairs.** Same painter, darker toward the tunnel (done 2026-10-27).
- [x] **Rats pinned on walls and rocks on the east side of the town.** Progress watcher (gives up when it makes no headway), one-side steering,
      and a wider cliff gap below the last nest. Sweep: pinned cases 200 -> 0 (done 2026-10-27).
- [x] **Play-test: a bandit stuck at a column drum and a rat stuck at its nest, neither noticing the hero.** The first 5b.3 steering flipped sides
      along long faces. Now: keep the side while blocked, a patrol goal time-out, a headway check in `return`, walkable roam spots, and rats also see
      the way their sprite faces (done 2026-10-27).
- [x] **Low props blocked sight.** The user decided (2026-10-27, now in the design doc, section 8 "Enemy behaviour"): nests, dead trees, cacti,
      column drums and scatter (agaves, small rocks) are see-through; walls, buildings, cliffs, pillars and big rocks still block. `level.gd solid(..., low)`
      keeps those out of `los()`; the B debug view draws them orange (done 2026-10-27).
- [ ] **P3. More see-through candidates.** Not decided yet, so they still block sight: torch posts (6x4), the bones/cart/crate landmarks, living
      trees and palms (their solid is just the trunk), and the storeroom's sacks, barrels and crates. Since 6a the cave adds tents, camp tables,
      stake palisades, sacks, barrels and crates, which also still block; only its fire rings, the spilled pot, the stool and the agaves are see-through.
      Since 6e the boss room has no stalagmites; its strongbox and crate stack are meant to block (cover, and something for the chief to charge into),
      and the jail's strap bench, braziers and the low loot are see-through.
- [ ] **P3. Enemies still have no pathfinding.** Since 5b.3 a stuck rat gives up and walks home instead of pinning, but it still can't find a way
      round a long wall or through a gate (e.g. the town's east wall from nest 4). An `AStarGrid2D` with 8 px cells built once per map from `solid_rects`, queried
      only when a chase starts or the watcher fires, would let rats and bandits follow the hero through gaps. Not picked for the cave (2026-10-27): there,
      bandits chasing up the winding jail tunnel will give up at its bends. The 6b rider follows the hero's own trail, so he doesn't need it.
- [x] **The east watch post stood lower than the gate pillar beside it.** Moved up 8 px; its base is now level with the north east-gate
      pillar's (y 412) (done 2026-10-27).
- [x] **Should enemies keep their damage after a fall?** The user decided: every enemy that walks back home heals to full (after a fall or a given-up
      chase), bosses included; now in the design doc, section 8 "Enemy behaviour". The chief, which kept his damage in the first 6c build, now heals
      and can enrage again; `rat.gd heals` was removed (done 2026-10-27).
- [ ] **P3. A fall against the chief restarts his fight.** Since 7j a fall loads a save, and no save can be made in his sealed room, so it
      always goes back to before the fight (usually the band's fire). Watch in the play-test whether that feels fair; if not, lower
      `CHIEF.hp`.
- [ ] **P3. Remind the player to rest before the chief.** Now that a fall costs everything since the last save, a rider shout or a sign at
      the band's fire ("Rest here; there's no going back up those steps") would help a first-time player. The same goes for the
      ambush in the jail: a fall there usually goes back to the autosave made on entering the cave.
- [ ] **P3. Teach the sideways roll.** Against the chief's charge (230 px/s) a roll straight back along the line (170 px/s) ends before he arrives, so
      you are still hit; only a sideways roll, or one through him, saves you. A line from the rider ("Roll aside!") on his first charge would teach it.
- [ ] **P3. No boss health bar on the HUD.** The chief's bar floats over his head (as the giant's does); in a crowded fight with three slingers a bar at
      the top of the screen (name + HP) would read better.
- [ ] **P2. Play-test the boss fight without stalagmites (6e).** Mid-room only the strongbox (762, 298) and the crate stack (892, 298) daze the
      chief's charge; everything else that does is at the walls (tents, palisades, the hoard, the war table). Check that baiting him into one is
      still easy to find. If not, a line from the rider on his first charge ("Lead him into the chest!") or a third tall piece near the middle.
- [ ] **P3. The jail is busier since 6e.** Pens, chain frames, a bench, a tool table and two braziers ring the room. In the play-test, watch that
      the ambush's slingers (they back off inside 70 px) still find room and don't stick on a corner prop.
- [ ] **P3. The 6a camp crate touches the rock.** `cave.gd PROPS` `["crate", 212, 1062]`: its left corner sits on the rock rim (the 6e layout check's
      one miss). Nudge it 4 px east.
- [ ] **P3. Lights in the boss room.** Since 6e about nine lights can be in view there at once (two torches, six fire bowls, the war table's lamp).
      Fine on this machine; check frame time on a weaker one.
- [ ] **P3. A cactus stands on top of a cliff.** `world_waystation.gd CACTI` `[980, 760]` is on the cliff `[930, 748, 76, 48]` (this was already so before
      the cliff was shortened). Move it to the sand, e.g. (1000, 812).

## Code health
- [x] **Duplicated lighting helpers.** `level.gd` now has `point_light(pos, radius, colour, energy, flicker)` and `flicker_lights(depth)`; the storeroom,
      the hall and the cave use them (done 2026-10-27, Stage 6a).
- [ ] **P2. Duplicated NPC set-up.** The `start_npcs()` loop is the same in `world_waystation.gd`, `courtyard.gd`, `hall.gd` and now `cave.gd`. Give `level.gd`
      a default `start_npcs()` that reads an `npc_list()`.
- [ ] **P3. Redundant overrides in `world_waystation.gd`.** It re-declares `npc_by_id`, `chatter_for` and `mark_for`, which are identical to `level.gd`. Delete them.
- [ ] **P3. Duplicated wall helpers.** `_wall_h` / `_wall_v` exist in both `world_waystation.gd` and `courtyard.gd`. Move them to `level.gd`.
- [ ] **P3. Duplicated supply placement.** The `match kind` blocks for barrels, crates, stacks and sacks exist in `storeroom.gd _add_props`, `courtyard.gd _camp`
      and now `cave.gd _add_props` (three copies). Use one `level.gd` helper.
- [ ] **P3. Town-specific water code.** `atmosphere.gd _draw_water` hard-codes the town's shore range (y 460–765, x 1195). Pass it in through `setup()`.
- [ ] **P3. Timing-sensitive test setups.** `fight.gd _bandits` only passed when the bandit happened to be pausing as the hero arrived (fixed in 5b.3 with
      `b.wait`). Other setups that set `face` on a moving enemy may hide the same trap; when one breaks after a movement change, pin the state, not the timing.
- [ ] **P3. Stale header comments.** `main.gd` ("Stage 1"), `hud.gd` ("edge toast" was removed), `npc.gd` ("one waystation character").
      `world_waystation.gd` and `level.gd` were fixed in 6a; `combat.gd` and `rat.gd` (`kind`) in 6c.
- [ ] **P3. `rat.gd` is the base of three enemy scripts now.** The chief and the slinger override `_chase`, `hit` and drawing, and `rat.gd` still holds
      the giant's slam and summon inline (`kind == "giant"` checks). Moving the giant into its own `giant.gd` the same way would leave `rat.gd` as the
      plain rat / bandit brain plus the shared base.
- [ ] **P3. A freed enemy compares equal to `null`.** In Godot 4 a variable holding a freed node is `== null`, so code that caches an enemy and looks it up
      again when it is null will find nothing after it dies (the 6c cave hit this; it now uses `is_instance_valid` and stops looking once he has fallen).
      Worth a line in `CLAUDE.md` if it bites again.
- [ ] **P3. One ground-paving helper.** `courtyard.gd _pave_plaza()` paints slabs inside any mask shape; `_slabs()` / `_grass()` (courtyard) and the
      town's flagstones do rectangle-only versions of the same thing. Move a mask-based `pave(mask)` into `terrain.gd` and use it everywhere.
- [ ] **P3. Solid ellipses.** The planter's stacked-band solids (`courtyard.gd _statue()`) would suit the well and other round props too; make it a `level.gd` helper.
- [ ] **P3. A shared texture helper for PNG props.** `castle_props.gd` keeps the statue texture in its own static var. When a second PNG prop arrives,
      move that into one helper (e.g. `Props.tex(path)` with a static cache) instead of a static var per prop.
- [ ] **P3. Scatter props follow the solids.** `world_waystation.gd _scatter()` skips spots that are blocked, so changing a cliff or a building can
      drop a random rock somewhere new. Shortening a cliff in 5b.3 put one at (1019, 739), right at the top of the widened gap (a 24 px lane is still
      clear). Add a `KEEP_CLEAR` list of rects (passages, the gap, doorways) that `_scatter()` never uses.
- [ ] **P3. `cave.gd _add_props` keeps growing.** Since 6e it handles over 40 prop kinds in one `match`. A table of `kind -> [solid rect, low, draw
      function, animated]` (or one helper per room) would make it shorter and let other maps share the common kinds (see "Duplicated supply placement").
- [ ] **P3. Vignette rebuilt per map.** `atmosphere.gd` rebuilds the 480x270 vignette pixel by pixel for each map that uses it. Cache it once (static).
- [ ] **P3. `combat.gd` keeps gathering systems.** Since 7f / 7g it also holds respawning, enemy levels, weapon XP and drops next to the
      fight itself. If it grows again (more weapons), move respawn and drops into a small `spawns.gd`, keeping the tuning constants
      where the README's "Where to tune" table points. (The shop went into its own `shop.gd` in 7h, with the prices in `items.gd`.)
      2026-10-30: it did grow, with the 8e port (four weapons, strings, specials, the bow, the block; about 1300 lines). Now P2: the
      weapons' tables (`*_MOVES`, `WEAPON_KIT`) could move to a `weapons.gd` data file, and respawning and drops to `spawns.gd`.
- [ ] **P2. `arena/arena_combat.gd` will drift from `scripts/combat.gd`** (Stage 8a, the user's choice of a separate copy). Every
      fix made to `combat.gd` later (a play-test bug, a new enemy table) is missing from the arena until copied over, and the arena's
      changes are missing from the game until ported. Keep the "What the arena changed" list in `arena_combat.gd`'s header current: it is
      the porting checklist. When the two get far apart, consider making the arena copy `extends combat.gd` with only its changes, so
      it picks up the game's fixes by itself (constants can't be overridden that way, so the arena's own tables would need new names).
- [ ] **P3. The game's tuning panel shows only the fists and the sword** (Stage 8a; still so after the 8e port). The game now has
      every arena move, the block, the parry, the specials and the Q timers in `combat.gd tune`, but `tuning.gd` edits only punch,
      kick, slash and thrust. The arena's panel (`arena_tuning.gd`) has a "weapon in hand" page that reads `WEAPON_KIT`; moving that
      page into `tuning.gd` would give the game the same rows (and shrink the arena's panel to its enemy-damage rows).
- [x] **P3. `player.gd` draws only the fists and the sword.** Done 2026-10-30 (Stage 8e): every arena drawing moved into
      `player.gd`; `arena_player.gd` is empty, for arena-only drawings to come.
- [ ] **P3. `rat.gd bind()` and the "bound" state are unused** (since Stage 8e: the strong lasso pulls a bandit instead). Remove them,
      with their drawing, once the user is sure the pull stays (the arena shares `rat.gd`, so check it too).
- [ ] **P3. The arena's copy is a full copy again** (Stage 8e). After the port, `arena_combat.gd` and `combat.gd` differ mostly by the
      arena's extras (cheats, readouts, live enemy tables, getting up) and the flurry's burn. This is a good moment to make the arena
      copy `extends combat.gd` with only its extras, so later fixes to the game reach the arena by themselves (see the drift item
      above); it needs the user's OK, since the separate copy was their choice.

## Tooling
- [ ] **P1. Start using git.** The project isn't under version control, and work goes stage by stage. `git init`, with `.godot/` in `.gitignore`.
- [ ] **P2. `run_all.ps1` says OK despite script errors.** During 6c a compile error in the new `chief.gd` printed `SCRIPT ERROR` lines, yet both suites
      reported OK (the error was only visible with `-Verbose`). Count any `SCRIPT ERROR` / `Parse Error` line as a failure.
      The same day a parse error in `rat.gd` made `world.gd` loop forever (a section kept retrying a call on a null enemy and never ended), so
      `run_all.ps1` never returned. Give each suite a time limit (e.g. kill it after 5 minutes and report FAILED), and let `suite.gd` end a section
      after a set number of frames.
- [x] **A one-command test run.** `tests/run_all.ps1` plus the shared base `tests/suite.gd`; 18 test files became 2 suites (done 2026-10-27).
- [ ] **P3. Engine version mismatch.** `project.godot` says `config/features "4.2"` and the README says "4.2 or newer", but the installed engine is 4.7.2.
      Newer scripts (`level.gd`, `courtyard.gd`, `hall.gd`, `castle_props.gd`, `storeroom.gd`, the test suites) have no `.uid` files. Open the project in
      the editor once so it upgrades and generates them.
- [x] **`overview.gd` never exits / Linux-only screenshot scripts.** All screenshot scripts were removed by choice (done 2026-10-27).
- [x] **Python image library for the art pipeline.** Pillow 13 installed per-user, plus `Code/prep_prop.py` for props (done 2026-10-27).
- [ ] **P3. Pin the Python packages.** Add `Code/requirements.txt` (`pillow`) so the pipeline can be set up again on another machine in one command.
- [x] **Leak warnings at exit.** The suites now free the game (and its frozen maps) before quitting, so the logs are clean (done 2026-10-27).

## Next-step ideas (match the design; pick per stage)
- **Combat arena, next steps (Stage 8):**
  - **P2. The next combat plan.** The user's ideas of 2026-10-28, re-ordered and decided on 2026-10-29. It is tried in the arena first,
    one step at a time, each stopping for a play-test. Words: **L** = a light attack (Mouse 1), **H** = a heavy attack (Mouse 2). A
    *string* is the run of attacks in one chain (3 long so far).
    - [x] **8b (done 2026-10-29):** the 8-way aim (the move keys, as the dodge), Mouse 1 / Mouse 2, named strings, the arena's own
      tuning panel (every move, each enemy's HP and hit damage). The fists have LLL, LLH (shoulder charge: a short dash and a big push)
      and HHH (knee, knee, hammer fist). The sword has LLL, LHL (rising cut: stuns a light foe) and HHH (three overheads). Matching:
      a press continues the string if one starts that way, else starts a new one. Data: `arena_combat.gd FIST_MOVES` / `SWORD_MOVES`
      and `ARENA_WEAPONS[w]["strings"]`. The hammer's "guard break" was dropped: a hit already staggers a bandit in his wind-up, and
      the bosses' armour is a design rule.
    - [x] **8c (done 2026-10-29): the spear, the bow, the block** (the user's keys: Space blocks, Shift dashes). Built as below.
      `arena_combat.gd SPEAR_MOVES` / `BOW_MOVES` / `BOW` / `BLOCK`; the block is judged in `hurt_player()` and its numbers are on the
      tuning panel. Follow-up (the user's notes): the slam, the charge and stones pierce it (`PIERCE`, violet warnings); the volley
      is earned; every combo names itself.
      - **Spear** (Achaemenid spearmen fit Era 1): long reach, a narrow box, its own strings and drawing.
      - **Bow:** unlimited arrows. L is a quick, weak arrow. H held is drawing and aiming (stamina drains while held), and letting
        go fires a strong arrow.
      - **Block** (Space held): every weapon (at first not the bow; the user's play-test gave it the weakest guard). A front hit does part damage and costs
        stamina; with no stamina the guard breaks (full damage and a stagger). He moves slowly while blocking. Judged in
        `hurt_player()`. The numbers go in a `BLOCK` const, with `"block": false` on the bow's row.
      - **To ask when it is built:** the block's numbers; whether some enemy attacks pierce the block (the giant's slam, the chief's
        charge, a stone).
    - [x] **8d (done 2026-10-29), built as below.** Claude's choices: each special costs 25 focus; the flurry is 4 x 10 and burns
      6 x 4 over 3 s; the whirl hits within 42 px for 30; the piercer does 50; the parry window is 0.15 s and gives 8 focus; piercing
      attacks can't be parried; a special's own hits give no focus. All of these are on the tuning panel or in `arena_combat.gd`.
    - **8d: the Q specials, then the parry.** Q is the lasso with the fists and the special with every other weapon. Specials cost
      focus.
      - **Fists:** the strong lasso (hold Q) pulls every non-boss, heavies too, instead of binding them.
      - **Sword:** a flaming lunge flurry, 3-4 fast fencing thrusts stepping along the aim; foes hit burn (a damage-over-time count
        like the poison). See the historical-care note under "Decisions pending".
      - **Spear:** a 360-degree strike.
      - **Bow:** a big piercing arrow that goes through foes.
      - **Parry:** Space pressed just before a hit lands; no damage, the attacker staggers, the hero gains focus. Not the bow.
    - [x] **8e (done 2026-10-30): a Combos tab in the inventory menu, with the port to the story game.** It lists each weapon the
      hero has, its strings, its Q move or special and what each does, and its guard. For now every string is known from the start
      (the user's "for now"), so nothing about known moves is saved yet; the toast for a new combo and the saved list (`progress.gd`,
      a `save.gd VERSION` bump) come with the teacher-taught moves.
    - [x] **8f (done 2026-10-29): combos with specials.** The strings end in Q after two swings (LLQ, LHQ, HHQ), each a named
      finisher: the weapon's special changed by the string's `"fin"`, at 1.5 x, for 10 focus, with the special's cooldown (the
      user's choices). The numbers and each finisher's twist are Claude's.
    - **Then:**
      - teacher-taught moves: each weapon starts with its plain string and basic Q move; its other strings, its special and the parry
        are taught (design doc section 13), with a "starting moves only" switch in the arena;
      - the timing evaluation: too early / early / perfect / acceptable / late, a small reward for perfect, in a `TIMING` const;
      - the enemy punishment: a whiff near a person enemy, or the long pause after an H finisher, lets him counter faster, still
        telegraphed.
  - **P3. Enemy hit damage on the game's own tuning panel.** Since 8b the arena's T panel edits how hard each enemy hits (its tables
    are `var` copies there). The game's `tuning.gd` still edits only enemy HP and XP. Doing the same in `combat.gd` would let a hit's
    damage be tried in the story maps too.
  - **P3. Arena: a mouse-aim switch.** The 8-way aim keeps the last keys pressed. An optional mouse-aim mode (attacks toward the
    cursor, snapped to 8 ways) would be easy to compare now that the attacks are on the mouse.
  - **P2. A feel pass**, each piece a switch in the arena panel so it can be compared on and off: hit-stop (a freeze of 2-4 frames on a
    hit, longer on the last swing); knock-back that grows down the combo; an input buffer for the whole swing instead of after 30 % of
    it (`combat.gd` `swing_t / dur > 0.3`); dodge-cancelling the end of a swing; a short lunge toward the nearest enemy in front.
  - **P2. New weapons to try**, kept to Era 1's history (see "Bandit weapons" under Historical care): the *akinakes* short sword (fast,
    short), a spear (long reach, a thrust line), the *sagaris* axe (slow, a wide arc). Each is a row in `ARENA_WEAPONS`, two tune keys
    and its drawing.
  - **P3. Arena options**: enemies that don't leash home (`leash` very high) to test a long fight; a slow-motion key (`Engine.time_scale`)
    to watch a combo frame by frame; a "spawn on the cursor" mode.
  - Porting: when the user is happy with something, one stage copies it into `scripts/combat.gd` (and decides how the hero gets it in
    the story, section 13: teachers unlock skills).
- [x] Stage 5c as planned: the servant and scholar in the hall (done 2026-10-27: a walking servant, Scholar Utana talkable in the library).
- Give Utana something to do once the story decisions above are made: he keeps the court's records, so he is a natural place for the first
  scientist log or a clue about the king's missing riders.
- The first scientist log in Era 1 (e.g. in the library alcove or the storeroom barn after the boss) plus a journal UI.
- Datis teaches at the training yard (the first teacher), e.g. unlocks the kick finisher or a guard-break.
- [x] The cave hideout map for the "hostile band" (done 2026-10-27 as Stages 6a, 6b and 6c; reworked by the user's notes in 6d).
- P2 (tests, suggest only): neither suite covers the cave's scripted events (camp rats, ambush timing, the seal, the captain's return). A 6d
  throwaway check did, 19 / 19, and a 6e one checked the new layout (props on floor, reach, four rat spots, slingers at the tent doors, a daze on
  the strongbox), 36 / 37; they could become a `world.gd` section if the user asks.
- P3: a late rescue after a return to the king without the rider (the design says he then stays caged; 6c removed the cage's E then).
  Since 6d the cage can still be opened after the chief falls, until you cut the captain down and leave, so a late rescue inside the cave works.
- **P2 (the user's idea, 2026-10-28, "just an idea"). A new area that shows the scientist's intentions.** It would come after the ruins.
  The design doc wants the early logs to be curious and the later ones to show "urgency, obsession, and a willingness to change
  history", so this area is where the first doubt about him could come. Some options to choose from:
  - his camp: a hidden spot off the coast road (a cave shelf, a ruined watchtower) with his bedroll, his tools and a crossed-out map;
  - a log that compares what the tablets say with what he thinks "should" have happened, and ends with something like "it only needs a
    small push";
  - a physical clue that he has taken or altered something here (a page torn from a court record, a missing tablet Utana noticed);
  - a type C spot (the design's "facility connected to the scientist's research") kept small in Era 1.
  It also gives the trail a next destination after "The trail goes on...". Decide its place and its one main reveal before building.
- **P2. The soldiers' logs in the abandoned camp** (the user's idea, 2026-10-27, for later; since 7j a first one exists, the rider's note in
  the jail's east pen, `dialogue.gd LOGS "jail_note"`): a few accounts left by the riders who camped there,
  about how the chief killed their men and how they tried to run. Finding them would spring the camp rats (today the trigger is just walking in
  between the tents, `cave.gd CAMP_TRIGGER`). Historical care: most riders could not write; the "log" could be an officer's short Aramaic note
  on leather (the empire's working script), a tally scratched on a tent pole, or a dying rider's words. Keep each to a line or two (design doc).
- P2: the captain Vahauka only exists in the cave (`cave.gd CAPTAIN`); both king return scenes say he is with the healers. He could appear in the
  hall (or the courtyard's tents) after the return, and give the hero something (a teacher? a clue toward the scientist?).
- P3: the captain is cut down by E alone; the hero has no blade (fists, kicks, lasso). A line or a short animation of untying could fit better.
- P3: the camp rats (since 6e two from the tents, two from the tunnels) always come at full strength; if the hero runs back out of the camp, they
  chase like any rat (pursuit limits apply).
- P3: a key from the jailer instead of E at the cage, once there is an inventory.
- [x] `hall.gd INTRO` / `CALL_LINE` were spoken text outside `dialogue.gd`; now `dialogue.gd SCENES["king_intro"]` and `SHOUTS["king_call"]`
  (done 2026-10-27, Stage 6c).
- P3: loot from the chief (the band's banner, a royal rider's seal ring) once there is an inventory; it could also carry the first scientist clue.
  Since 6e his hoard (behind his seat) and the coin bags on the floor are drawn but can't be taken; they are the natural place for it.
- P3: the rider could say a word now and then while following (a shout when the hero is hurt, or when a group wakes), from `dialogue.gd SHOUTS`.
- [x] A scorpion den near the ruins (type A) (done 2026-10-28, Stage 7j).
- Level-ups from XP, and a save checkpoint at the waystation well.
