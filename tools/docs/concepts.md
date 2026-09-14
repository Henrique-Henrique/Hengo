# Concepts

What the json describes and how it becomes GDScript. Keys are in [json-format.md](json-format.md).

## Graph vs generated script

Each run writes two things per script:

| artifact | path | role |
|---|---|---|
| graph | `res://hengo/collections/<collection id>/<script id>/identity.res` and `save.res` | the editable truth the Hengo editor opens |
| build | `res://hengo/scripts/<script name>.gd` | plain GDScript Godot runs. Attach it to a node |

The build is overwritten on every run and on every save in the editor: never hand-edit it, change the json (or the graph) and regenerate. Generating also deletes and recreates the whole collection with the same name, so editor changes to that collection are lost.

A collection is a group of scripts opened together in the editor. Scripts in one json can reference each other (cross-script branches); scripts in different runs cannot.

Before writing, the CLI asks codegen which actions it would skip (the same check that paints a card red in the editor). Any hit gives exit 2 and nothing is written. After writing, it reloads `save.res` from disk and regenerates: the code must be identical (round-trip), parse, and hold no `# hengo: action <id> (<n>) unresolved: <reason>` line. Any of these failing also gives exit 2.

## State machine

A script is one state machine. The generated file looks like:

```gdscript
extends CharacterBody2D

var speed = 200.0
var _STATE_CONTROLLER = HengoStateController.new(self)

func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		_STATE_CONTROLLER.change_state("idle")

func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)

func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)

class Idle extends HengoState:
	func enter() -> void: ...
	func update(delta) -> void: ...
```

- Each state is an inner class. Inside it, the owner node is `_ref` (`_ref.velocity`, `_ref.speed`).
- Exactly one top-level state runs at a time. The start state enters in `_ready`.
- The first state in `states` is the start state unless another sets `"start": true`. Setting `start` on one state clears it on its siblings. The first state also stays the base state, which the editor will not delete or nest.
- `HengoState` and `HengoStateController` are runtime classes shipped in `addons/hengo`, so the addon must stay in the project that runs the script.

### Phases

| json | editor label | runs |
|---|---|---|
| `enter` | Start | once when the state becomes active |
| `update` | Every Frame | each `_process` frame |
| `physics` | Physics | each `_physics_process` tick. Move bodies here |
| `exit` | End | once when the state is left |

Each action declares which phases it supports and a default one (`phases`, `default_phase` in the catalog). Rules the builder enforces: an action with no flow inputs is update-only; an action with a required branch cannot run on `exit` (a transition from exit would re-enter forever).

### Action order

Within a state, actions are grouped by phase and run in json order inside each phase. A transition does not stop the list: the steps after it in the same phase still run in that frame, and when two branches fire in the same frame the last transition wins. Put transitions last, and never dereference an output after a branch that may have left the state.

### Branches are transitions

A branching action (`if_condition`, `compare`, `wait`, `input_action`, ...) emits an `if` and, for each wired branch, `change_state("<target>")`. Unwired optional branches cost nothing: the action emits its plain body. A required branch with nothing wired leaves the action unresolved.

`transition` is the unconditional one (`"branches": {"to": "Run"}`). A branch can also run steps in place (`{"actions": [...]}`) without leaving the state.

### Re-entry

A transition to the state that is already running is a no-op, so `enter` does not re-fire while a per-frame condition holds. Set `"can_reenter": true` on the target to allow A to A. A to B to A always re-enters.

### Sub-states

`sub_states` is a nested machine owned by a state:

- entering the parent runs its `enter` actions, then enters its start sub-state;
- every frame the active sub-state's `update`/`physics` runs first, then the parent's;
- leaving the parent exits the sub-state too.

Put what must never stop (movement, gravity, look) in the parent and switch modes in the children. A branch may target a sub-state only from its parent, a sibling or a descendant. Names are unique across the whole script, so two parents cannot both have an `Idle` child.

## Values between actions

- `bind`/`prop` read and write script vars and owner properties. Anything stored across frames belongs in a script var.
- `wire` reads the output of an earlier step in the same list without a var.
- An inline `action` input computes a value in place (pure producers only).
- `expr` is raw GDScript with bound words. Prefer an action when one covers it: `--lint-exprs` lists expressions an action could replace.

A pure producer (an action whose only job is an output) placed alone emits nothing and is reported as `no output stored`: read it with `wire` or use it inline.

## Cross-script

A branch of the form `{"script": "enemy", "state": "Alert", "instance": "enemy_ref"}` calls `enemy_ref._STATE_CONTROLLER.change_state("alert")` on another node's machine. The node comes from a var (`instance`) or a node path (`path`). Both scripts must be in the same json. `check_instance: true` guards against a freed node or a node without a Hengo machine. Only top-level states of the other script are reachable.

Reading another node's value goes through sources: `{"path": "../Player"}` as a node input, or an `expr` word such as `{"p": {"path": ".."}}` with `p.velocity`. The CLI does not verify node paths or property names on other nodes.

## Functions vs macros

| | function | macro |
|---|---|---|
| is | a method: an action list run on each call | a reusable state machine |
| declared in | `functions` | `macros` |
| used by | an action `fn:<name>` in any list | an entry in a state's `uses` |
| parameters | `inputs`, read with `{"arg"}` | `inputs`, read with `{"arg"}` |
| result | `outputs` (via `finish:`), `ways_out` the caller branches on | `ways_out` wired per use to states of the script |
| extension points | none | `hooks`, filled per use with `steps`, run inside with `run:<hook>` |
| state | none of its own, cannot transition its own script | real states, phases, sub-states |
| emitted as | one method `fn_<name>` | a copy of the states per use |

Use a function to share a sequence of steps (fire, show ammo). Use a macro when several states share a whole behavior with states of its own (a weapon with ready and reload), differing only by inputs and a few steps.
