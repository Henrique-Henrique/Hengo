# hengo_cli

`tools/hengo_cli.gd` builds Hengo scripts from a JSON file, headless, with no editor UI. The JSON describes script variables, a state machine (states, sub-states) and, per state, an ordered list of actions picked from the Hengo action catalog, plus optional functions and state macros. The CLI saves the graph as a Hengo collection the editor can open, compiles each script to plain GDScript in `res://hengo/scripts/<name>.gd`, then verifies that the saved graph reproduces the same code and that the code parses. It also exposes the action catalog (`--list-actions`, `--export-actions`, `--preview`), which is what an agent reads instead of guessing ids.

## Prerequisites

- Godot 4.7. On Windows use the console binary (`godot_console.exe`, `Godot_v4.x_win64_console.exe`), the GUI binary prints nothing.
- A project with `addons/hengo` (plugin enabled) and `tools/`.
- **Required once per fresh project**, before any command: `godot --headless --path <project> --import` (or open the project in the editor once). Without it the `class_name` globals are not registered and the CLI fails to parse (`Could not find type "HenSaveParam"`), even for `--help`.

## Commands

```
godot --headless --path <project> -s tools/hengo_cli.gd -- <command>
```

| command | does |
|---|---|
| `<script.json> [collection_name]` | builds every script of the json into one collection. Deletes and recreates the collection with that name. Name: json `collection` key, else the argument, else `"AI"`. Writes the graph to `res://hengo/collections/...` and the build to `res://hengo/scripts/<snake_name>.gd`, overwriting. Then checks round-trip and parse |
| `--list-actions [--class=Node2D]` | json contract of the actions that serve that class (default `Node`) |
| `--preview <action_id>` | inputs (defaults, options, flags), outputs, branches, emitted code per phase, per target class and per option, declared state, and a copyable json entry |
| `--export-actions [out.json] [--with-code]` | full catalog, default `tools/actions.json` (not versioned, generate it locally). `--with-code` adds `emits` and `usage` per action |
| `--lint-exprs` | lists expressions in saved scripts that an existing action covers |
| `--help`, `-h` | usage |

| exit | meaning |
|---|---|
| 0 | ok |
| 1 | error: bad json, schema or reference error. Nothing is written, the previous collection stays |
| 2 | failure. Either an action cannot be emitted (`<script>: <state> / <action>: <reason>`, nothing is written), or the written code does not parse or round-trip |
| 3 | `--lint-exprs` found expressions an action covers |

Leak warnings at exit (`ObjectDB instances were leaked`, `resources still in use`) are harmless.

## Agent workflow

1. **Catalog.** Run `--export-actions --with-code` once and grep `tools/actions.json`, or run `--list-actions --class=<the class the script extends>`. Never guess ids or slot names. See [docs/actions.md](docs/actions.md).
2. **Preview.** Run `--preview <id>` for each action you picked. Read phases, `serves`, slot flags, options, branches and every `emits` block (per class and per option).
3. **Write the json.** Start each action from the preview's `json` block. Keys: [docs/json-format.md](docs/json-format.md). Model: [docs/concepts.md](docs/concepts.md).
4. **Generate.** `-- path/to/script.json`.
5. **Read the report.** Exit 1: fix the reported key, id, slot or reference. Exit 2: fix every `<script>: <state> / <action>: <reason>` line, or the `SCRIPT ERROR` / round-trip line. Rerun until exit 0. Symptoms and fixes: [docs/gotchas.md](docs/gotchas.md).
6. **Use it.** Attach `res://hengo/scripts/<name>.gd` to a node whose class matches `extends`, with the child nodes your `path` sources expect. Do not hand-edit the `.gd`: regenerate.

The CLI does not check node paths, input action names or properties of other nodes, so run the scene to verify behavior.

## Minimal example

```json
{
  "collection": "Demo",
  "name": "blinker",
  "extends": "Node2D",
  "vars": [ { "name": "count", "type": "int", "value": 0 } ],
  "states": [
    {
      "name": "Idle",
      "start": true,
      "actions": [
        { "id": "print_value", "phase": "enter", "inputs": { "value": "idle" } },
        { "id": "input_action", "phase": "update",
          "inputs": { "action": "ui_accept", "mode": "is_action_just_pressed" },
          "branches": { "true": "Counting" } }
      ]
    },
    {
      "name": "Counting",
      "actions": [
        { "id": "add_to_value", "phase": "enter", "inputs": { "target": { "bind": "count" }, "amount": 1 } },
        { "id": "print_value", "phase": "enter", "inputs": { "value": { "bind": "count" } } },
        { "id": "wait", "phase": "update", "inputs": { "seconds": 0.5 }, "branches": { "finished": "Idle" } }
      ]
    }
  ]
}
```

```
godot --headless --path . -s tools/hengo_cli.gd -- blinker.json
```

## Docs

- [docs/json-format.md](docs/json-format.md): every json key, value forms, branches, functions, macros, coercion.
- [docs/concepts.md](docs/concepts.md): graph vs build, state machine, phases, action order, sub-states, cross-script, functions vs macros.
- [docs/actions.md](docs/actions.md): finding actions, reading `--preview`, input kinds, outputs, branches, bodies.
- [docs/gotchas.md](docs/gotchas.md): symptom, cause, fix.

## Examples

- [examples/01_simple.json](examples/01_simple.json): a single state script with vars and actions (spinning, drifting Node2D).
- [examples/02_branches.json](examples/02_branches.json): transitions via branches between states (CharacterBody2D with Idle/Walk sub-states, dash and recover; wires and nested inline actions).
- [examples/03_cross_script.json](examples/03_cross_script.json): two scripts where one drives the other (an Area2D switch opens a door by path, the door resets the switch with `check_instance`).
- [examples/04_function_macro.json](examples/04_function_macro.json): functions and state macros (functions with outputs and ways out, a macro with a hook, a way out and a use).
