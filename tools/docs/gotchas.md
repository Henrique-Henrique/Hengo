# Gotchas

Format: **symptom** -> cause -> fix.

## Running the CLI

- **Nothing is printed on Windows** -> the GUI binary does not write to stdout -> use the console binary (`godot_console.exe`, `Godot_v4.x_win64_console.exe`).
- **Wall of `Parse Error: Could not find type "HenSaveParam"` / `Identifier "HenEnums" not declared` at `tools/hengo_cli.gd`, exit 1, even `--help` prints nothing** -> the project was never imported, so `.godot/global_script_class_cache.cfg` has no `class_name` globals and the CLI script fails to parse -> run `godot --headless --path <project> --import` once (or open the project in the editor once), then rerun. Repeat after adding addon files with a new `class_name`.
- **`WARNING: N ObjectDB instances were leaked` / `ERROR: N resources still in use at exit`** -> the CLI bootstrap does not free everything on quit -> harmless; judge by the exit code and the `OK ->` / `[hengo_cli]` lines.
- **No arguments prints help and exits 1** -> only `--help`/`-h` exits 0 -> pass a command.
- **Collection name argument ignored** -> the json `collection` key wins over `[collection_name]` -> change it in the json.
- **Edits made in the Hengo editor vanished** -> generate deletes and recreates the collection with that name and overwrites `hengo/scripts/<name>.gd` -> treat the json as the source, or use another collection name.
- **The editor still shows the old graph after a failed run** -> exit 1 and the action check of exit 2 stop before anything is written, so the previous collection and `.gd` stay as they were -> fix the error and regenerate.
- **Two scripts overwrite each other** -> build path is `hengo/scripts/<snake name>.gd`, shared across collections -> give every script a unique `name` project-wide.
- **`could not read or parse json`** -> invalid json (trailing comma, comment) or wrong path; paths are relative to the project folder -> validate the json, use a project-relative or absolute path.
- **`--lint-exprs` prints nothing useful / exit 3** -> it reads saved collections, and exit 3 only means hints were found -> generate first; treat hints as suggestions.

## Exit codes

- **Exit 0 but the game misbehaves** -> the CLI checks action ids, slots, round-trip and parse, never node paths, groups, input actions or properties of other nodes -> check `{"path": ...}` against the scene tree and input names against the Input Map.
- **Exit 2 with `actions that cannot be emitted, nothing was written`** -> the json is valid but codegen would skip some action -> each line reads `<script>: <state> / <action>: <reason>`, see the section below. Exit 2 is a failure, not a warning.
- **Exit 2 after `OK ->` lines** -> the files were written but the code does not parse or the reloaded graph differs -> read the `SCRIPT ERROR` lines for the line number in the written `.gd`, fix the json, rerun.

## Build errors (exit 1)

- **`unknown key "x" (valid: ...)`** -> typo or a key that does not exist (`funcs`, `ready`, `store`) -> use only keys from [json-format.md](json-format.md).
- **`unknown action id "x"; did you mean "y"?`** -> guessed or outdated id -> search `tools/actions.json` or `--list-actions`.
- **`unknown class "CharacterBody2d" in extends`** -> `extends` takes a native Godot class, spelled exactly -> fix the class name (`CharacterBody2D`).
- **`top level: unknown key "colection"`** -> in the `scripts` form the wrapper only takes `scripts`, `collection` and `debug` -> fix the key.
- **`input "mode": "captured" is not one of ...`** -> raw option slots take the engine constant -> copy the exact value from `options` (`MOUSE_MODE_CAPTURED`).
- **`input "x" expects Vector2, got String`** -> vector or color written as a string -> use arrays `[x, y]`, `[r, g, b, a]` (Color also accepts `"#rrggbb"`).
- **`phase "update" is not supported (supported: enter)`** -> each action has its own phases (tweens and spawns are often enter-only, input readers often have no physics) -> pick from `phases` in the preview, or omit `phase`.
- **`duplicated state "Idle"`** -> state names are unique across the whole script, sub-states, macro states and use names included -> prefix them (`PistolReady`, `MachineReady`).
- **`duplicated ref "x"`** -> `ref` is unique across the whole script, function bodies included -> name refs per state (`idle_dir`, `walk_dir`).
- **`unknown ref "x", a wire only reaches a step declared before it`** -> the wire points forward or to a typo -> declare the producer earlier in the build order (functions, macros, states, each in json order).
- **`output "x" is not declared on "check"`** -> a wire names an output by id or by display name, and neither matched -> use one of the ids listed in the error (function outputs have the id `<function>_<output>`, e.g. `mouse_in_range_distance`).
- **`a branch goes to a state or it runs steps, never both`** -> `{"actions": [...], "state": "X"}` -> end the steps with `{"id": "transition", "branches": {"to": "X"}}`.
- **`an inline action cannot feed a slot that needs a variable`** / **`a wire cannot be the left side of an assignment`** -> `lvalue`/`bind_only` slots need a source -> use `{"bind"}` or `{"prop"}` there.
- **`is not an inlinable value producer`** -> only pure producers go inline -> run the action as its own step with a `ref` and read it with `wire`.
- **`no input "x" in the definition being built`** -> `{"arg"}` used outside a function or macro, or wrong input name -> only use `arg` inside `functions`/`macros`.
- **`unknown native source`** / **`needs a RigidBody3D`** -> source name misspelled or not available to this class -> see the list in json-format.md; for a CharacterBody read `{"prop": "velocity"}` instead of `Velocity`.
- **`does not serve` on an action you saw in the catalog** -> the catalog lists every class -> filter with `--list-actions --class=<your class>`.

## Actions that cannot be emitted (exit 2, nothing written)

The check is the same one that paints an action card red in the editor, so the reasons match the UI.

- **`input "Node" must be bound to a variable or property`** -> action served only through its node slot (e.g. `stop_body` on a `CharacterBody2D` script) with that slot empty, or an `expr` placed on an `lvalue` slot -> check `serves` in `--preview`, bind `ref` to a node of the right class, and use `bind`/`prop` for assignment targets.
- **`no branch target set`** -> a branching action (or a `fn:` call whose function has `ways_out`) with no branch wired -> wire at least one branch; for a question you only read, use its output instead.
- **`no output stored`** -> a pure producer alone in a list -> read it with `wire` from a later step, or inline it.
- **`has no update body`** -> nested or hook step whose action does not support the owner's phase -> move it to a list running in a supported phase.
- **`a function cannot change the state of its own script`** -> a local transition inside a function -> return through a way out and branch in the caller.
- **`branch "x" points at a sub-state of another state`** -> sub-states are reachable only from their parent, siblings or descendants -> transition to the parent, or move the action.
- **`uses delta, which a function does not have`** -> an action whose template uses `delta` (`rotate_toward`, timers) inside a function body -> call it from a state `update`/`physics`, or use a delta-free action (`look_at_2d`); `--preview` shows whether the template uses `delta`.

## Runtime behavior

- **`enter` fires once, the state never restarts** -> transitions to the running state are ignored -> set `"can_reenter": true` on it, or go through another state.
- **A one-shot fires every frame** (impulses stack, a ram repeats) -> a per-frame branch re-enters a short state that jumps back while the condition still holds -> add a cooldown state (`wait` then back), or use `cooldown`/`do_once`.
- **Wrong state wins when two branches fire** -> a transition does not stop the list; the last one in the phase wins -> order branches by priority, most important last.
- **Crash reading an output after a branch** -> the steps after a transition still run that frame -> split reading and acting into two states.
- **`cooldown` or `every` restarts too often** -> their timers reset when the state is entered again -> keep the actor in one state and use `every` with a `body`, or move the gate to a parent state.
- **A timer inside `repeat`/`for_each` runs N times too fast** -> nested steps run once per iteration -> keep timers outside loops.
- **Movement stops during a dash or attack** -> movement lives in a sibling sub-state that is no longer active -> put continuous logic in the parent state, which keeps running under its sub-states.
- **`set_value` on `position.y` or another node fails** -> an assignment writes only a whole top-level var or property of the owner -> write the whole vector, put a script on that node, or use `set_property` with a node.
- **Cross-script transition does nothing** -> instance var is null or a node without a Hengo script, or the target is a sub-state -> check the path, set `check_instance: true`, target a top-level state.
- **`State not found: x` printed** -> the other script's state was renamed after this json was generated -> regenerate both scripts from one json.
- **Text with a single-letter word breaks an expression** -> words replace whole identifiers, a word named like a variable in the code collides -> use descriptive word names (`nm`, not `n`).
- **`screen_wrap`, mouse and `Input.mouse_mode` checks fail headless** -> headless has a 64x64 viewport, no mouse and a fixed mouse mode -> verify those in a window; keep game state in vars, not in display properties.
