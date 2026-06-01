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
| Constraints           | energy availability, daylight (Q2) |

---

## Project status

| Part | Description | Status |
|------|-------------|--------|
| **Q1** | Classical PDDL with numeric fluents (recharge as an *action*) | ✅ Done |
| **Q2** | PDDL+ model (continuous charging *process* + night-time *event*) | ✅ Done |
| **Discussion** | Discrete vs continuous energy modelling; planning under uncertainty | ✅ Done |
| **Bonus** | Durative movement (travel takes time, modelled with a process + event) | ✅ Done |

---

## Repository structure

```
.
├── README.md                              # this file
├── discussion.md                          # discrete vs continuous, planning under uncertainty
├── Basic_PDDL/                            # Q1 — classical PDDL
│   ├── domain.pddl
│   ├── problem-A.pddl                     # recharge OPTIONAL  (generous battery)
│   └── problem-B.pddl                     # recharge NECESSARY (tight battery)
├── PDDL_+/                                # Q2 — PDDL+ with processes & events
│   ├── domain.pddl
│   ├── problem-Q2-easy.pddl               # plenty of battery + plenty of day
│   ├── problem-Q2-tight.pddl              # low battery, plenty of day
│   ├── problem-Q2-infeasible.pddl         # nightfall blocks the goal
│   └── problem-Q2-fastzone-only.pddl      # tight deadline forces fast-zone charging
└── Optional_Durative_Movement/            # BONUS — travel takes time
    ├── domain.pddl
    ├── problem-dur-easy.pddl
    ├── problem-dur-tight.pddl
    ├── problem-dur-fastzone.pddl
    └── problem-dur-infeasible.pddl
```

One domain per question, multiple problem files per question — the classic
PDDL separation between *the rules of the world* and *a specific instance
to solve*.

---

# Q1 — Classical PDDL

## The model

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

## The map

A 4-node **directional** graph (used in all parts):

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

Solar zones in Q1: **B** (`charge-rate` 15, slow) and **C** (`charge-rate` 25, fast).

Goal (both Q1 problems): visit **every** location.

```lisp
(:goal (and (visited locA) (visited locB) (visited locC) (visited locD)))
```

## The two Q1 problems

| | **Problem A — optional** | **Problem B — necessary** |
|-|--------------------------|---------------------------|
| Initial battery | 50 (generous) | 25 (tight) |
| Can finish without recharge? | ✅ yes | ❌ no |
| Planner uses `recharge`? | ❌ no | ✅ yes (forced) |

The **only** substantive difference between the two problem files is the
initial battery level. Same domain, same map, same goal — different
optimal behaviour. This demonstrates that **energy genuinely influences
planning**, which is the central requirement of Q1.

## Expected Q1 results

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
unable to afford the 10-cost C→D move.

> An equally valid 4-action plan recharges at **B** instead of C. With ties,
> the planner picks one according to its heuristic; both are correct.

---

# Q2 — PDDL+ with Processes and Events

## What changes from Q1

In Q1, the planner is the *only* agent that changes the world. In Q2, the
**world itself** evolves:

| Construct | Who controls it | When it fires | Type of change |
|-----------|-----------------|----------------|------|
| **Action** | Planner (agent) | Planner's choice | Discrete |
| **Process** | World            | While precondition holds | **Continuous** |
| **Event** | World            | Instant precondition becomes true | Discrete |

So `recharge` is no longer an action the planner *picks*. It becomes a
**process** that runs automatically whenever the rover is sitting in a
solar zone during daytime. A **nightfall event** flips a global
`(daytime)` flag at a clock threshold, automatically stopping the charging
process.

## New predicates and fluents (Q2 only)

| Construct | Meaning |
|-----------|---------|
| `(daytime)` *(predicate, no parameters)* | True while the sun is up |
| `(time-of-day)` *(fluent)*               | Continuous clock, advanced by a `time-flow` process |

## Processes and events

| Construct | Behaviour |
|-----------|-----------|
| `:process time-flow`  | Clock ticks at rate 1 (always active) |
| `:process charging`   | While rover is at a solar zone *and* `(daytime)` *and* battery is not full: `battery-level` rises by `(* #t charge-rate)` |
| `:event nightfall`    | At `time-of-day ≥ 100`, sets `(daytime)` to false |
| `:event sunrise`      | At `time-of-day ≥ 200`, sets `(daytime)` back to true |

> ⚙️ Charge rates are much smaller in Q2 (`0.2` and `0.5`) than in Q1
> (`15` and `25`). Q1 rates were *jumps* applied once per recharge action;
> Q2 rates are *per-tick* gains over continuous time. Without rescaling,
> Q2 charging would be unrealistically fast.

## The four Q2 problems

| File | Initial battery | `time-of-day` | Demonstrates |
|------|-----------------|----------------|--------------|
| `problem-Q2-easy.pddl`          | 60 | 0  | Process exists but is never used |
| `problem-Q2-tight.pddl`         | 20 | 0  | Process forced into the plan; charging splits across both solar zones |
| `problem-Q2-infeasible.pddl`    | 20 | 85 | Nightfall blocks completion → planner returns "Problem unsolvable" |
| `problem-Q2-fastzone-only.pddl` | 20 | 79 | Only 21 ticks of daylight: the slow zone is no longer time-affordable, forcing the optimal fast-zone strategy |

Goal in all four:

```lisp
(:goal (and
  (visited locA) (visited locB) (visited locC) (visited locD)
  (< (time-of-day) 100)        ; must complete BEFORE nightfall
))
```

The strict `< 100` time bound makes the deadline real: a plan finishing
exactly at t=100 is rejected.

## Expected Q2 results

### `problem-Q2-easy.pddl` — no charging needed

```
0.0: (move rover1 locA locB)
0.0: (move rover1 locB locC)
0.0: (move rover1 locC locD)
Elapsed Time: 0.0
```

Three instantaneous moves, no waiting. Battery: 60 → 50 → 40 → 30.
Charging process is *available* but the planner doesn't invoke it.

### `problem-Q2-tight.pddl` — process forced, suboptimal plan

```
0:     (move rover1 locA locB)
0:     -----waiting---- [45.0]      # charging at B (rate 0.2)
45.0:  (move rover1 locB locC)
45.0:  -----waiting---- [47.0]      # charging at C (rate 0.5)
47.0:  (move rover1 locC locD)
Elapsed Time: 47.0
```

The planner splits charging across **both** solar zones — gaining 9 battery
at B (45 × 0.2) and 1 at C (2 × 0.5), exactly the 10 needed. The plan is
*valid* but not *time-optimal*: a smarter plan would skip B and charge for
20 ticks at C. The `hadd` heuristic counts remaining actions, not remaining
time, so it cannot distinguish "short wait" from "long wait."

### `problem-Q2-infeasible.pddl` — nightfall blocks the goal

```
Problem unsolvable
Expanded Nodes: 815
Number of Dead-Ends detected: 151
```

With `time-of-day = 85`, only 15 ticks of daylight remain. The minimum
charging time at C (10 ÷ 0.5 = 20 ticks) does not fit before the
`nightfall` event fires. The planner searches 815 states and declares the
problem unsolvable.

### `problem-Q2-fastzone-only.pddl` — constraint forces optimality

```
0:    (move rover1 locA locB)
0:    (move rover1 locB locC)
0:    -----waiting---- [20.0]       # charging at C only (rate 0.5)
20.0: (move rover1 locC locD)
Elapsed Time: 20.0
```

With only 21 ticks of daylight remaining (`time-of-day = 79`), the slow
"charge at B first" strategy is no longer time-affordable. The planner is
*forced* into the optimal strategy: rush to C, charge for exactly 20 ticks,
finish at t=99 (one tick before nightfall). **A constraint made the planner
produce the time-optimal plan that the unconstrained `tight` problem failed
to find.**

## Q2 — the timing-feasibility spectrum

| Initial `time-of-day` | Daylight left | Outcome | Lesson |
|-----------------------|----------------|---------|--------|
| 0                     | 100           | 47-tick suboptimal plan | Plenty of margin → planner is lazy |
| 79                    | 21            | 20-tick optimal plan ✅ | Constraint forces the fast strategy |
| 80                    | 20            | Unsolvable (boundary)   | Plan would end exactly at t=100, violating `< 100` |
| 85                    | 15            | Unsolvable ❌            | Even fast charging cannot fit |

---

# Bonus — Durative Movement (`Optional_Durative_Movement/`)

## Motivation

In Q1 and Q2, `move` is **instantaneous** — the rover crosses an edge in
zero time, and time only advances while it waits to charge. This bonus
makes **travel itself take time** (a fixed 5 ticks per move), so the
daylight budget is consumed by *moving* as well as *charging*.

## Why not `:durative-action`?

ENHSP is a numeric / PDDL+ planner built around **processes and events**;
it does not support PDDL 2.1 `:durative-action` syntax. So travel time is
modelled the **PDDL+ way**, with three coordinated constructs:

| Construct | Type | Role |
|-----------|------|------|
| `start-move`  | `:action`  | Rover commits: leaves origin, spends battery, sets `travel-timer = 5`, marks `traveling` and `dest` |
| `travel`      | `:process` | Counts `travel-timer` down continuously while in transit |
| `arrive`      | `:event`   | When the timer reaches 0: rover lands at `dest`, marks it `visited`, clears `traveling` |

**Charging during travel is naturally blocked**: while `(traveling ?r)` is
true, `(at ?r ?l)` is false for every `?l`, so the `charging` process
cannot run. This matches the convention that the rover only charges while
stationary at a solar zone.

## The four bonus problems

| File | Initial battery | `time-of-day` | Expected |
|------|-----------------|----------------|----------|
| `problem-dur-easy.pddl`       | 60 | 0  | Feasible — 3 moves, finishes ~t=15, no charging |
| `problem-dur-tight.pddl`      | 20 | 0  | Feasible — travel + charging, finishes ~t=65 |
| `problem-dur-fastzone.pddl`   | 20 | 64 | Feasible — only the fast zone fits in the remaining daylight |
| `problem-dur-infeasible.pddl` | 20 | 75 | Unsolvable — 25 ticks daylight < 35 needed |

## Expected bonus results

### `problem-dur-easy.pddl`

```
0:    (start-move rover1 locA locB)
0:    -----waiting---- [5.0]       # travel
5.0:  (start-move rover1 locB locC)
5.0:  -----waiting---- [10.0]      # travel
10.0: (start-move rover1 locC locD)
10.0: -----waiting---- [15.0]      # travel
```

3 moves × 5-tick travel → arrives at D at t=15. No charging.

### `problem-dur-tight.pddl`

```
0:    (start-move rover1 locA locB)
0:    -----waiting---- [55.0]      # travel (5) + charging at B (50)
55.0: (start-move rover1 locB locC)
55.0: -----waiting---- [60.0]      # travel
60.0: (start-move rover1 locC locD)
60.0: -----waiting---- [65.0]      # travel
```

Feasible, finishes at t=65. The planner again charges at the slow zone B
(satisficing, not time-optimal — same behaviour as the Q2 `tight` case).

### `problem-dur-fastzone.pddl`

```
0:    (start-move rover1 locA locB)
0:    -----waiting---- [5.0]       # travel
5.0:  (start-move rover1 locB locC)
5.0:  -----waiting---- [30.0]      # travel (5) + charging at C (20)
30.0: (start-move rover1 locC locD)
30.0: -----waiting---- [35.0]      # travel
```

With only 36 ticks of daylight (`time-of-day = 64`), the slow-zone strategy
no longer fits, so the planner is forced to charge at the fast zone C.
Finishes at t = 64 + 35 = 99 < 100.

### `problem-dur-infeasible.pddl`

```
Problem unsolvable
```

Started at `time-of-day = 75` → only 25 ticks of daylight. Minimum plan =
15 (travel) + 20 (charging) = 35 ticks > 25. Nightfall stops charging
before enough energy is recovered.

## Instantaneous vs durative — the comparison

| Case | Instantaneous (Q2) | Durative (bonus) | Why it shifts |
|------|--------------------|--------------------|----------------|
| easy        | finishes t=0     | finishes **t=15**  | travel now costs 3 × 5 ticks |
| tight       | 47 ticks         | **65 ticks**       | +15 travel on top of slow charge |
| fastzone    | boundary t=79    | boundary **t=64**  | travel eats daylight earlier |
| infeasible  | fails at t=85    | fails at **t=75**  | deadline bites sooner |

**The takeaway:** adding travel time shifts every feasibility boundary
*earlier* — the rover has less daylight to spare because moving itself
consumes the day. The lesson is unchanged (timing drives feasibility); the
numbers simply tighten.

---

## How to run

PDDL+ requires a planner that supports processes and events. We use
[ENHSP](https://gitlab.com/enricos83/ENHSP-Public).

### Building ENHSP (one-time setup, Windows / PowerShell)

```powershell
git clone https://gitlab.com/enricos83/ENHSP-Public.git
cd ENHSP-Public
mkdir out -Force
javac -encoding utf8 -d out -classpath "libs/*" (Get-ChildItem -Recurse src/planners/*.java, src/*.java | Select-Object -ExpandProperty FullName)
jar --create --file enhsp.jar --manifest manifest.mf -C out/ .
```

### Running each part

```powershell
# Q1
cd Basic_PDDL
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-A.pddl -planner sat-hadd
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-B.pddl -planner sat-hadd

# Q2
cd ..\PDDL_+
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-Q2-easy.pddl          -planner sat-hadd
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-Q2-tight.pddl         -planner sat-hadd
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-Q2-infeasible.pddl    -planner sat-hadd -timeout 60
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-Q2-fastzone-only.pddl -planner sat-hadd

# Bonus
cd ..\Optional_Durative_Movement
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-dur-easy.pddl       -planner sat-hadd
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-dur-tight.pddl      -planner sat-hadd
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-dur-fastzone.pddl   -planner sat-hadd
java -jar <path>\ENHSP-Public\enhsp.jar -o domain.pddl -f problem-dur-infeasible.pddl -planner sat-hadd -timeout 60
```

---

## Design notes

- **Directional edges.** `(connected A B)` does **not** imply
  `(connected B A)`. Movement is one-way unless both directions are
  declared. (There is no edge *into* A, so the rover must start at A.)
- **Q1 recharge is instantaneous.** Acceptable for the classical model;
  Q2 replaces it with a continuous `:process charging` per the assignment
  guideline *"avoid modelling recharge as instantaneous unless justified."*
- **Charge-rate rescaling between Q1 and Q2.** Q1 rates (15, 25) are
  per-action jumps; Q2 rates (0.2, 0.5) are per-tick continuous gains.
- **Travel duration via process + event.** The bonus models a 5-tick move
  using a timer process and an arrival event, because ENHSP does not
  support `:durative-action`.
- **No reactive battery threshold.** The model does **not** hard-code a
  rule like *"recharge if battery < 60."* The planner derives *when* to
  recharge from the energy preconditions — deliberative, not scripted.
- **Obstacles / terrain are out of scope.** Edges are assumed traversable;
  modelling real geometry would require task-motion planning.
- **Satisficing vs optimal planning.** `sat-hadd` finds valid plans
  quickly but does not guarantee minimum time. The `tight` vs
  `fastzone-only` comparison makes this concrete.

---

## Discussion

See [`discussion.md`](./discussion.md) for a full discussion covering:

- **Discrete vs continuous energy modelling** — the Q1 action vs the Q2
  process, agency (planner- vs world-driven), and the satisficing-vs-optimal
  property illustrated by `tight` vs `fastzone-only`.
- **Planning under energy uncertainty** — MDP and POMDP frameworks, robust
  and contingent planning, and how PDDL+ fits inside a Sense–Plan–Act loop.
- **Durative movement** — how adding travel time tightens every feasibility
  boundary without changing the underlying lesson.

---

## License

Coursework — for educational use.
