> **FILES TO CHECK (final / correct):** <br>
> **PDDL (Q1)** → `codes/Basic_PDDL/domain.pddl` with `problem-optional.pddl` (recharge optional) and `problem-necessary.pddl` (recharge necessary).<br>
> **PDDL+ (Q2)** → `codes/PDDL_+/domain.pddl` with `problem-Q2-easy.pddl`, `problem-Q2-tight.pddl`, `problem-Q2-fastzone.pddl`, `problem-Q2-infeasible.pddl`. <br>
> **Bonus** → `codes/Optional_Durative_Movement/` is a **bonus** (travel takes time).

Author : Hani Bouhraoua &nbsp;|&nbsp; ID : 8314923

---

# Planetary Rover — Solar Energy and Charging Dynamics (PDDL / PDDL+)

> Assignment **D1-V7** — *Artificial Intelligence for Robotics 2 (AI4Ro2)*
> A solar-powered rover explores a graph of locations while managing battery
> consumption and solar recharging.
> **Planner:** ENHSP, run with `-planner sat-hadd`.

---

## Scenario

A single rover recharges its battery in sunlight-exposed regions; charging
efficiency varies by location. The rover must **balance exploration and
energy recovery**: visit every location without running out of battery.

The model uses only two object types — `rover` and `location`. Everything
else is a **predicate** (`at`, `connected`, `solar-zone`, `visited`,
`daytime`) or a **numeric fluent** (`battery-level`, `max-battery`,
`move-cost`, `charge-rate`, `time-of-day`).

The split `move-cost` (consumption) vs `charge-rate` (generation), with
`charge-rate` per-location, satisfies *"distinguish consumption from
generation"* and *"efficiency varies by location"*.

## Map (directional, used by both Q1 and Q2)

    A ──────► B
    │         │
    ▼         ▼
    D ◄────── C
    ▲
    └── (B ──► D shortcut, energy-expensive, decoy)

`A→B, B→C, C→D` cost 10 each (scenic route, total 30); `A→D` costs 15
(skips B,C); `B→D` costs 20 (decoy, skips C). Solar zones: B and C. Goal:
visit every location. There is no edge *into* A, so the rover starts at A.

---

## Q1 — Classical PDDL  (`codes/Basic_PDDL/`)

Two actions: **`move`** (precondition `(>= battery-level move-cost)`,
decreases battery, marks `visited`) and **`recharge`** (instantaneous
`(increase battery-level charge-rate)` at a solar zone).

| Problem | Battery | Result | Plan Metric |
|---------|---------|--------|-------------|
| `problem-optional.pddl`  | 50 | 3 moves, **no recharge** — optional | Length: 3.0 |
| `problem-necessary.pddl` | 25 | 3 moves **+ 1 recharge** — forced, else stranded at C | Length: 4.0 |

The only difference is initial battery (50 vs 25): same domain, different
behaviour → **energy genuinely influences planning**.

<details>
<summary><b>View Planner Outputs (Q1)</b></summary>

**`problem-optional.pddl`**
    Found Plan:
    0.0: (move rover1 locA locB)
    1.0: (move rover1 locB locC)
    2.0: (move rover1 locC locD)
    
    Plan-Length:3
    Metric (Search):3.0

**`problem-necessary.pddl`**
    Found Plan:
    0.0: (move rover1 locA locB)
    1.0: (move rover1 locB locC)
    2.0: (recharge rover1 locC)
    3.0: (move rover1 locC locD)
    
    Plan-Length:4
    Metric (Search):4.0

</details>

---

## Q2 — PDDL+  (`codes/PDDL_+/`)

`recharge` becomes a **process**, and night-time a **event**:

| Construct | Behaviour |
|-----------|-----------|
| `:process time-flow` | advances `time-of-day` at rate 1 |
| `:process charging`  | while at a solar zone, `(daytime)`, not full: `battery += (* #t charge-rate)` |
| `:event nightfall`   | at `time-of-day ≥ 100`, sets `(daytime)` false → charging stops instantly |
| `:event sunrise`     | at `time-of-day ≥ 200`, sets `(daytime)` true |

`charging` and `nightfall` are **not linked explicitly** — they coordinate
through the shared `(daytime)` fact. Charge rates are rescaled to 0.2 / 0.5
(per-tick) vs Q1's 15 / 25 (one-shot), since they multiply by elapsed time.
The goal includes `(< (time-of-day) 100)` so the mission must finish before
nightfall.

Four cases, varying only `time-of-day`, show timing drives feasibility:

| File | Battery | time-of-day | Outcome | Elapsed Time |
|------|---------|-------------|---------|--------------|
| `problem-Q2-easy.pddl`       | 60 | 0  | 3 moves, no charging | 0 |
| `problem-Q2-tight.pddl`      | 20 | 0  | valid 47-tick plan (charges both zones), not time-optimal | 47.0 |
| `problem-Q2-fastzone.pddl`   | 20 | 79 | only 21 ticks left → forced **optimal** 20-tick plan | 20.0 |
| `problem-Q2-infeasible.pddl` | 20 | 85 | only 15 ticks left → **unsolvable** (nightfall blocks goal) | N/A (Metric: -1.0) |

<details>
<summary><b>View Planner Outputs (Q2)</b></summary>

**`problem-Q2-easy.pddl`**
    Found Plan:
    0: (move rover1 locA locB)
    0: (move rover1 locB locC)
    0: (move rover1 locC locD)
    
    Plan-Length:3
    Elapsed Time: 0
    Metric (Search):3.0

**`problem-Q2-tight.pddl`**
    Found Plan:
    0: (move rover1 locA locB)
    0: -----waiting---- [45.0]
    45.0: (move rover1 locB locC)
    45.0: -----waiting---- [47.0]
    47.0: (move rover1 locC locD)
    
    Plan-Length:50
    Elapsed Time: 47.0
    Metric (Search):50.0

**`problem-Q2-fastzone.pddl`**
    Found Plan:
    0: (move rover1 locA locB)
    0: (move rover1 locB locC)
    0: -----waiting---- [20.0]
    20.0: (move rover1 locC locD)
    
    Plan-Length:23
    Elapsed Time: 20.0
    Metric (Search):23.0

**`problem-Q2-infeasible.pddl`**
    Problem unsolvable
    Metric (Search):-1.0

</details>

---

## Bonus — Durative Movement  (`codes/Optional_Durative_Movement/`)

Travel takes 5 ticks per move. ENHSP does not support `:durative-action`,
so duration is modelled the PDDL+ way: a `start-move` action sets a
`travel-timer` and a `traveling` flag, a `travel` process counts the timer
down, and an `arrive` event lands the rover. Adding travel time shifts every
feasibility boundary earlier (e.g. tight 47→65 ticks, infeasible boundary
85→75) without changing the lesson.

---

## How to run (ENHSP)

Path to the planner jar shown as `~/ENHSP-Public/enhsp.jar`
(adjust if yours is elsewhere).

    # Q1
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/Basic_PDDL/domain.pddl -f codes/Basic_PDDL/problem-optional.pddl  -planner sat-hadd
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/Basic_PDDL/domain.pddl -f codes/Basic_PDDL/problem-necessary.pddl -planner sat-hadd
    
    # Q2
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/PDDL_+/domain.pddl -f codes/PDDL_+/problem-Q2-easy.pddl       -planner sat-hadd
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/PDDL_+/domain.pddl -f codes/PDDL_+/problem-Q2-tight.pddl      -planner sat-hadd
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/PDDL_+/domain.pddl -f codes/PDDL_+/problem-Q2-fastzone.pddl   -planner sat-hadd
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/PDDL_+/domain.pddl -f codes/PDDL_+/problem-Q2-infeasible.pddl -planner sat-hadd -timeout 60
    
    # Bonus (durative movement)
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/Optional_Durative_Movement_PDDL_+/domain.pddl -f codes/Optional_Durative_Movement_PDDL_+/problem-dur-easy.pddl       -planner sat-hadd
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/Optional_Durative_Movement_PDDL_+/domain.pddl -f codes/Optional_Durative_Movement_PDDL_+/problem-dur-tight.pddl      -planner sat-hadd
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/Optional_Durative_Movement_PDDL_+/domain.pddl -f codes/Optional_Durative_Movement_PDDL_+/problem-dur-fastzone.pddl   -planner sat-hadd
    java -jar ~/ENHSP-Public/enhsp.jar -o codes/Optional_Durative_Movement_PDDL_+/domain.pddl -f codes/Optional_Durative_Movement_PDDL_+/problem-dur-infeasible.pddl -planner sat-hadd -timeout 60

To save a run into a file, append `> codes/outputs/NAME.txt 2>&1`
(create the folder first with `mkdir -p codes/outputs`).
Recorded outputs for every problem are in `codes/outputs/`.

---

## Limitations

- **Optimality not guaranteed.** Satisficing search (`sat-hadd`) returns
  valid but sometimes time-wasteful plans (the 47-tick `tight` case); a
  `(:metric)` or a tighter deadline forces optimality.
- **Instantaneous moves** in Q1/Q2 (travel time addressed in the bonus).
- **Edges assumed traversable** (no obstacles / task–motion gap),
  **single agent**, **deterministic** (no uncertainty; that would need
  MDP/POMDP, unsupported by PDDL planners).

---

## Repository layout

    .
    ├── README.md
    ├── Report/   
    ├──     report.pdf            
    ├── slide/    
    ├──     Rover_Presentation.pptx
    └── codes/
        ├── Basic_PDDL/                 Q1
        ├── PDDL_+/                     Q2
        ├── Optional_Durative_Movement/ bonus
        └── outputs/                    recorded planner outputs