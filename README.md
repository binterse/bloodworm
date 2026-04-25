# Snake Crusher (Godot 4.x)

A playable Snake game in Godot where the "apples" are tiny people. Humans panic-run around, can be chased by a rare chainsaw maniac, and get crushed by the snake.

## Original User Instructions (for AI handoff)
- Make a snake game in Godot.
- Apples are small people that get crushed when the snake goes over them.
- Basic first version; make something working now.
- Include title screen and score counter.
- Control using arrow keys or WASD.
- Stop when there is something runnable and playable.
- Make startup easy for a beginner.
- Install Godot in `.devcontainer` and current container.
- Add feedback/testing so AI can validate behavior.
- Humans slowly run around in panic, about 1 square per 5 seconds.
- When one dies, two more spawn.
- Add title-screen checkbox: when checked, walls disappear and field wraps.
- Add chainsaw maniac chasing people; corrected spawn roll is `1/64`.
- Snake is vegetarian: it crushes people, it does not eat them.
- Chainsaw maniac kills should not give the player points.
- Crushing a chainsaw maniac should give the player 5 points.
- Spawn four regular human types: man, woman, grandma, grandpa.
- Increase sprite size and add more graphics detail.

## Current Features
- Title screen with start/exit buttons and wrap-mode checkbox.
- Snake movement on fixed grid (`WASD` + arrows).
- Game starts in fullscreen and is laid out for `1920x1080`.
- Pause on `Esc` during gameplay with resume/title/exit buttons.
- Polished HUD with live stats, game-over overlay, and nicer fullscreen layout.
- Humans and chainsaw maniacs use a shared AI phase every second.
- Only about 20% of eligible humans move in a given AI phase.
- After moving, each human waits about 2.0-3.5 seconds before becoming eligible again.
- Chainsaw maniacs act every AI phase, which means once per second.
- Human and maniac walk animations are split into separate subphases so they do not visually start together.
- Humans can also randomly explode on an AI phase, causing a larger blood burst without awarding points or spawning replacements.
- Some humans spawn armed, and armed humans sometimes shoot other humans.
- On each snake-crushed human death, two more humans spawn.
- Chainsaw maniac kills do not spawn replacement humans.
- Snake crushes humans and grows when it does.
- Chainsaw maniac kills humans without awarding player points.
- Crushing a chainsaw maniac awards 5 points, grows the snake by 1, and spawns 2 regular humans.
- Human variants: man, woman, grandma, grandpa.
- Chainsaw maniac spawn rolls at `1/64` on regular human spawns and is guaranteed to appear by the 20th regular human.
- No more than 3 chainsaw maniacs can exist at once.
- A velociraptor appears roughly every minute, eats several humans, and can bite off part of the snake to shorten it.
- If the board is packed and no chainsaw maniac exists yet, pressure converts one human into a chainsaw maniac instead of ending the run.
- Wrap mode removes wall death and wraps snake/AI at edges.
- Larger/more detailed character drawing, a top-down viper-style snake body with rounded flowing corners, a larger expressive head, zig-zag dorsal patterning, animated movement between grid cells, heavier blood splat effects, and temporary blood leftovers.

## Easy Start
From project root:

```bash
./play.sh
```

If needed once:

```bash
chmod +x play.sh
```

If editor opens first, press `F5` (Play).

## Controls
- Move: `WASD` or arrow keys
- Start game from title: `Enter` / `Space`
- In game: `Esc` pause / resume
- On game over: `R` restart

## Wrap Mode
- On title screen, check `Wrap Around Walls (No Wall Death)` before starting.
- If enabled, entities wrap across edges instead of colliding with walls.

## Quick Self-Tests (for AI)
Run the headless smoke test:

```bash
./play.sh --headless --script res://scripts/smoke_test.gd
```

Run the focused snake growth regression test:

```bash
./play.sh --headless --script res://scripts/snake_growth_test.gd
```

Run the focused scene visibility test:

```bash
./play.sh --headless --script res://scripts/visibility_system_test.gd
```

Run the focused chainsaw/maniac systems test:

```bash
./play.sh --headless --script res://scripts/maniac_system_test.gd
```

Run the focused movement animation test:

```bash
./play.sh --headless --script res://scripts/movement_animation_test.gd
```

Run the focused random explosion test:

```bash
./play.sh --headless --script res://scripts/explosion_system_test.gd
```

Run the focused snake visual regression test:

```bash
./play.sh --headless --script res://scripts/snake_visual_test.gd
```

Run the focused gunfire + velociraptor systems test:

```bash
./play.sh --headless --script res://scripts/predator_system_test.gd
```

Expected final line:
`Smoke test passed: snake growth, people, reproduction, maniac guarantee, and panic movement all active.`

The smoke test verifies:
- scene loads,
- snake grows after crushing a person,
- snake grows and spawns 2 humans after crushing a chainsaw maniac,
- snake and humans exist,
- one death causes two spawns (net +1),
- the chainsaw maniac is guaranteed by the 20th regular human spawn,
- panic movement path runs,
- no immediate unintended game over.

The focused tests verify:
- `snake_growth_test.gd`: snake grows after a crush and keeps the added length on the following move.
- `visibility_system_test.gd`: title-screen labels, wrap checkbox UI, score label, centered pause overlay, HUD/board separation, game-over label visibility, and wrap drawing adjacency behave correctly.
- `maniac_system_test.gd`: crushed maniacs award 5 points, grow the snake, spawn 2 humans, chainsaw kills do not award player points or spawn replacements, chainsaw count is capped at 3, and a full board does not trigger a loss.
- `movement_animation_test.gd`: snake and people draw between grid cells instead of snapping directly to the next square, and maniacs only start walking after the human subphase has finished.
- `explosion_system_test.gd`: forced random human explosions remove one human, do not award points, and leave blood behind.
- `snake_visual_test.gd`: rounded snake corners generate extra smoothed samples, wrap-separated runs stay split, and crushing a human activates the facial-expression timer.
- `predator_system_test.gd`: armed humans can kill another human without awarding points, velociraptors can eat humans, and velociraptors can shorten the snake.

## Key Files
- `project.godot`
- `play.sh`
- `scenes/title_screen.tscn`
- `scripts/title_screen.gd`
- `scenes/game.tscn`
- `scripts/game.gd`
- `scripts/test_support.gd`
- `scripts/snake_growth_test.gd`
- `scripts/visibility_system_test.gd`
- `scripts/maniac_system_test.gd`
- `scripts/movement_animation_test.gd`
- `scripts/explosion_system_test.gd`
- `scripts/snake_visual_test.gd`
- `scripts/predator_system_test.gd`
- `scripts/smoke_test.gd`
- `.devcontainer/Dockerfile`
