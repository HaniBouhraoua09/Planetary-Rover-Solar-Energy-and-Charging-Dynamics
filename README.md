Author : Hani Bouhraoua <br>
ID : 8314923 <br>


# Planetary Rover — Solar Energy and Charging Dynamics (PDDL / PDDL+)

> Assignment **D1-V7** — *Artificial Intelligence for Robotics 2 (AI4Ro2)*
> Modelling a solar-powered planetary rover that must explore a graph of
> locations while managing battery consumption and solar recharging.

---

## Scenario

A single rover is equipped with solar panels and can recharge its battery
when located in sunlight-exposed regions. Charging efficiency varies by
location. The rover must **balance exploration and energy recovery**:
explore enough to visit every location, but never run out of battery.

| Domain characteristic | Choice in this model |
|-----------------------|----------------------|
| Robot                 | single rover         |
| Environment           | directional graph with energy zones |
| Tasks                 | exploration, recharging |
| Constraints           | energy availability  |

---

## Project status

| Part | Description | Status |
|------|-------------|--------|
| **Q1** | Classical PDDL with numeric fluents (recharge as an *action*) | ✅ Done |
| **Q2** | PDDL+ model (continuous charging *process* + night-time *event*) | ⏳ Planned |
| **Discussion** | Discrete vs continuous energy modelling; planning under uncertainty | ⏳ Planned |

This repository currently covers **Q1**.

---

## Repository structure

```
pddl-rover/
├── README.md          # this file
├── domain.pddl        # shared domain (rules of the world)
├── problem-A.pddl     # recharge OPTIONAL  (generous battery)
└── problem-B.pddl     # recharge NECESSARY (tight battery)
```

One domain, two problems — the classic PDDL separation between *the rules
of the world* and *a specific instance to solve*.

---

## The model (Q1)

### Types
Only two kinds of object exist in the world.

```lisp
(:types rover location)
```

Everything else (battery, sunlight, charging) is modelled as a **property**
(predicate) or a **quantity** (numeric fluent), not as an object.

### Predicates (boolean facts)

| Predicate | Meaning |
|-----------|---------|
| `(at ?r ?l)`          | rover `?r` is at location `?l` |
| `(connected ?l1 ?l2)` | a directional edge exists `?l1 → ?l2` |
| `(solar-zone ?l)`     | `?l` is sunlit and can be used to recharge |
| `(visited ?l)`        | `?l` has been visited (used by the goal) |

### Numeric fluents (quantities)

| Function | Meaning |
|----------|---------|
| `(battery-level ?r)`   | current battery of rover `?r` |
| `(max-battery ?r)`     | battery capacity |
| `(move-cost ?l1 ?l2)`  | energy consumed traversing `?l1 → ?l2` (**consumption**) |
| `(charge-rate ?l)`     | energy gained per recharge at `?l` (**generation**) |

The split `move-cost` vs `charge-rate` cleanly separates **energy
consumption** from **energy generation**, and `charge-rate` being
per-location captures the *"efficiency varies by location"* requirement.

### Actions

| Action | Precondition (summary) | Effect (summary) |
|--------|------------------------|------------------|
| `move`     | at origin, edge exists, **battery ≥ move-cost** | move to destination, mark visited, **decrease battery** |
| `recharge` | at a `solar-zone`, would not overcharge | **increase battery** by `charge-rate` |

The numeric precondition on `move` is what makes **energy actually
constrain the plan**: the rover cannot traverse an edge it cannot afford.

---

## The map

A 4-node **directional** graph:

```
        A ──────► B
        │         │
        ▼         ▼
        D ◄────── C
        ▲
        └── (B ──► D shortcut, energy-expensive)
```

Edges declared in `:init`:

```lisp
(connected A B)   ; A -> B   cheap   (cost 10)
(connected B C)   ; B -> C   cheap   (cost 10)
(connected C D)   ; C -> D   cheap   (cost 10)
(connected A D)   ; A -> D   skips B & C (cost 15)
(connected B D)   ; B -> D   decoy shortcut, skips C (cost 20)
```

- **Scenic route** `A → B → C → D` visits everything (total cost 30).
- **Shortcut `A → D`** skips B and C — cannot satisfy a *visit-all* goal.
- **Decoy edge `B → D`** skips C — proves the planner uses *goal reasoning*,
  not just connectivity.

Solar zones: **B** (`charge-rate` 15, slow) and **C** (`charge-rate` 25, fast).

Goal (both problems): visit **every** location.

```lisp
(:goal (and (visited locA) (visited locB) (visited locC) (visited locD)))
```

---

## The two problems

| | **Problem A — optional** | **Problem B — necessary** |
|-|--------------------------|---------------------------|
| Initial battery | 50 (generous) | 25 (tight) |
| Can finish without recharge? | ✅ yes | ❌ no |
| Planner uses `recharge`? | ❌ no | ✅ yes (forced) |

The **only** substantive difference between the two problem files is the
initial battery level. Same domain, same map, same goal — different
optimal behaviour. This demonstrates that **energy genuinely influences
planning**, which is the central requirement of Q1.

---

## How to run

### Option 1 — Online editor (no install)

1. Open <https://editor.planning.domains/>
2. Paste `domain.pddl` in the left panel.
3. Paste `problem-A.pddl` (or `problem-B.pddl`) in the right panel.
4. Click **Solve**.

### Option 2 — ENHSP locally

`:numeric-fluents` requires a numeric planner such as
[ENHSP](https://gitlab.com/enricos83/ENHSP-Public).

```bash
# Problem A (expect: no recharge)
enhsp -o domain.pddl -f problem-A.pddl

# Problem B (expect: one recharge step)
enhsp -o domain.pddl -f problem-B.pddl
```

---

## Expected results

### Problem A — recharge optional

```
0.00000: (move rover1 locA locB)
1.00000: (move rover1 locB locC)
2.00000: (move rover1 locC locD)
```

Three moves, **no recharge**. Battery: 50 → 40 → 30 → 20. The planner never
inserts a recharge because the goal is reachable without it.

### Problem B — recharge necessary

```
0.00000: (move rover1 locA locB)
1.00000: (move rover1 locB locC)
2.00000: (recharge rover1 locC)
3.00000: (move rover1 locC locD)
```

Three moves **plus one recharge**. Battery: 25 → 15 → 5 → (recharge) 30 → 20.
Without the recharge step the rover would be stranded at C with 5 units,
unable to afford the final 10-cost move to D.

> An equally valid 4-action plan recharges at **B** instead of C. With ties,
> the planner picks one according to its heuristic; both are correct.

---

## Design notes

- **Directional edges.** `(connected A B)` does **not** imply
  `(connected B A)`. Movement is one-way unless both directions are
  declared. (There is no edge *into* A, so the rover must start at A.)
- **Recharge is instantaneous in Q1.** This is acceptable for the classical
  model; Q2 replaces it with a continuous charging *process* per the
  assignment guideline *"avoid modelling recharge as instantaneous unless
  justified."*
- **No reactive battery threshold.** The model does **not** hard-code a rule
  like *"recharge if battery < 60."* The planner derives *when* to recharge
  from the energy preconditions — this is deliberative planning, not scripted
  reactive control.
- **Obstacles / terrain are out of scope.** Edges are assumed traversable;
  modelling real geometry would require task-motion planning to close the
  symbolic-geometric gap.

---

## Next steps

- [ ] **Q2 — PDDL+**: continuous `:process charging` (`* #t` battery rise),
      `:event nightfall` that stops charging at a time threshold, and a
      timing-dependent feasibility example.
- [ ] **Discussion**: discrete vs continuous energy modelling; planning
      under energy uncertainty (belief space / POMDP).

---

## License

Coursework — for educational use.
