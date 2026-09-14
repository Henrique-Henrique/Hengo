# Actions

An action is a step of a state: `{ "id": "set_velocity", "inputs": {...} }`. The id comes from the catalog, never from memory: ids and slot names change between versions, and a guessed id fails the build.

The pool has the native actions of `addons/hengo/actions/<category>/` plus the user macros of `res://hengo/macros/`. Script functions (`fn:`, `finish:`) and macro hooks (`run:`) are added per script, see [json-format.md](json-format.md#functions).

## Finding the right action

1. Generate the catalog once per project version:

   ```
   godot --headless --path . -s tools/hengo_cli.gd -- --export-actions --with-code
   ```

   It writes `tools/actions.json` (not versioned): `{version, categories, actions}`. Each action has `id`, `name`, `category`, `description`, `phases`, `default_phase`, `inputs`, `outputs`, `branches` (with `optional`), `has_body`, `target_classes`, and with `--with-code` also `emits` and `usage`.

2. Search it instead of guessing. By concept in names and descriptions, then by category:

   ```
   grep -n '"name": ".*Velocity' tools/actions.json
   grep -n -i 'description.*distance' tools/actions.json
   jq -r '.actions[] | select(.category=="physics2d") | "\(.id)  \(.name)"' tools/actions.json
   ```

3. Filter by the class the script extends. An action serves a script when `target_classes` is empty, when the script class is one of them or inherits from one, or when its first input is a node `ref` slot (it can act on another node through that slot). `--list-actions --class=CharacterBody2D` applies exactly this rule, inheritance included; the default class is `Node`.

   An action served only through its `ref` slot must get that slot bound (`{"path": "Body"}`) when the script class is not in `target_classes`; left empty, it means the owner and codegen reports `must be bound to a variable or property`.

4. Check for a near duplicate before settling: descriptions say how similar actions differ ("Cooldown fires right away; Every N Seconds waits first").

Categories are the folder names: `animation`, `array`, `audio`, `camera`, `control`, `convert`, `debug`, `dictionary`, `event`, `flow`, `input`, `logic`, `math`, `navigation`, `node2d`, `node3d`, `physics`, `physics2d`, `physics3d`, `render`, `save`, `scene`, `string`, `tilemap`, `time`, `tween`, `variable`, `vector`.

## Reading `--preview`

```
godot --headless --path . -s tools/hengo_cli.gd -- --preview compare
```

Sections, in order:

| section | read it for |
|---|---|
| header | id, display name, category, description |
| `phases: ... default: ...` | allowed `phase` values |
| `serves:` | classes the action accepts (`any class` or a list) |
| `has body / loop only` | whether `body` is accepted, whether it only works inside a loop (`break_loop`) |
| `inputs` | slot id, type, flags (`raw`, `lvalue`, `bind only`, `optional`, `type from x`), `default`, `options`, doc |
| `outputs` | output ids, for `wire` and inline `output` |
| `branches` | branch ids and `required` or `optional` |
| `emits` | the GDScript with `{{slot}}` placeholders, under a bare `enter, update:` line naming the phases that share that code |
| `emits on <Class>` | one block per target class when classes emit different code |
| `emits with "<input>" = <values>` | a different code shape when that option is picked |
| `output x = ...` | the expression each output stands for |
| `state_vars:`, `script_vars:`, `reset:`, `teardown:`, `override <method>:` | what the action declares besides its body (timers, `_input` hooks). Multi-line values are flattened with ` / ` |
| `json` | a copyable action entry filled with the defaults |

Start every action entry from the `json` block: it already has Colors and Vectors as arrays, `bind_only` slots as `{"bind": "<variable>"}` and branches as `"SomeState"` placeholders.

Read every `emits on` block, not only the first: `change_color` writes `modulate` on a CanvasItem and a material on a Node3D, `set_rotation_3d` writes degrees. The block that applies is the class of your script (or of the node bound to `ref`).

Read `emits with` blocks for option inputs: some options change more than a constant (a mouse wheel option turns polling into an `_input` override).

## Input kinds

- **Literal**: any slot without `lvalue` or `bind_only`. Coerced to the slot type; see [literal coercion](json-format.md#literal-coercion).
- **Raw with options**: the value is pasted into code. Use the exact option string, which is an engine constant or code token (`MOUSE_MODE_CAPTURED`, `is_action_just_pressed`, `<`). The template may add a prefix (`Input.{{mode}}`), which `emits` shows.
- **lvalue**: the assignment target of `set_value`, `add_to_value`, ... Needs `{"bind": "var"}` or `{"prop": "position"}`. Writes only a whole top-level var or property of the owner (`position`, not `position.y`, not another node's property).
- **bind_only**: needs a source, typically the `ref` node slot of node actions: `{"path": "Sprite"}` or `{"bind": "target"}`. Left empty, it means the owner node, which only works when the script class matches `target_classes`.
- **Expression**: `{"expr": "...", "words": {...}}` on any non-lvalue slot. Use it for one-line math; use actions for anything an action covers (`--lint-exprs` checks saved scripts).
- **type_from**: the slot takes the type of another slot's binding (`set_value.value` follows `target`), so `"amount": 2` on an int var emits `2`, not `2.0`.

## Outputs

An output is consumed in one of two ways. There is no "store" key.

- `wire`: give the producer a `ref`, read it later in the same script with `{"wire": {"from": "<ref>", "output": "<id>"}}`.
- inline: put the producer inside the consuming slot, `{"action": {...}, "output": "<id>"}`. Only pure producers qualify (outputs, no branches wired, no body, nothing declared).

To keep a value across frames, write it to a var with `set_value`, feeding `value` from a wire or an inline producer. Event actions (`on_body_entered`, `on_signal`, ...) have their own optional `lvalue` slot that stores the received value into a var.

A producer standing alone with no reader emits nothing: `unresolved: no output stored`.

## Branches

Each id in `branches` is a flow output. Wire only the ones you need:

- `required` branch: at least one branch must be wired or the action is unresolved (`no branch target set`).
- `optional` branch: the action works without it, and emits no `if` when nothing is wired. Many questions (`compare`, `is_on_floor`, `get_node`) have both an output and optional branches: use the output inline for a value, the branches to transition.
- A branch value can run steps instead of transitioning: `{"actions": [...]}`, ending with `transition` if it should also leave.

## Body actions

`has_body: true` actions (`do_if`, `repeat`, `for_each`, `every`, `do_n_times`, ...) take `body`. Nested steps run at the owner's phase and at its rate: inside `repeat` or `for_each`, a nested timer or counter advances once per iteration, not once per frame.

## Checklist per action

1. id exists and serves the script class (or its `ref` slot is bound to a node that it serves).
2. `phase` is in `phases` (or omitted to take the default).
3. Every `lvalue` slot has `bind` or `prop`; every needed `bind_only` slot has a source.
4. Raw option values copied from `options`.
5. Vectors and Colors as arrays.
6. At least one branch wired when the branches are required.
7. Outputs read by `wire` or inline, never left alone.
