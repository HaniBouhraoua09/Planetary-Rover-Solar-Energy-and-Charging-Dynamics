Author : Hani Bouhraoua <br>
ID : 8314923 <br>

# Discussion — Planetary Rover (D1-V7)

> Companion to the main `README.md`. Reflects on the modelling choices
> made in Q1 (classical PDDL) and Q2 (PDDL+), grounded in the planner
> outputs produced by ENHSP, and closes with the optional durative-movement
> extension.

---

## 1. Discrete vs. continuous energy modelling

Both Q1 and Q2 modelled the same scenario — a rover exploring a graph
while managing battery — but expressed it in two different formalisms.
The comparison reveals three concrete trade-offs.

### 1.1. Expressive power vs simplicity

In Q1, `recharge` is a single discrete action with an instantaneous
effect. Plans read like a recipe: "move, move, recharge, move." Easy
to write, easy to verify. The cost is **fidelity**: a real solar
panel does not deliver +25 units of charge in zero time.

In Q2, the `:process charging` produces battery continuously,
integrated over the time the rover spends in a solar zone. The plan
now answers a question Q1 cannot: *how long does the rover sit?* This
is essential for real robotic execution — a controller needs to know
how long to keep the rover stationary, not just that it should
"recharge."

### 1.2. Agency: planner-driven vs world-driven

In Q1, the planner is the only source of state change. In Q2, the
*world* acts on its own through `:process` and `:event` constructs.
This shift is essential for any domain where physics evolves
regardless of the agent's choices — falling objects, draining tanks,
sunsets. In our model, **nightfall** is the obvious example: the rover
doesn't *decide* night comes; the world imposes it.

### 1.3. Optimality is not guaranteed

A surprising result emerged from comparing two Q2 runs:

| Problem          | Battery | Daylight | Plan time   | Strategy                       |
|------------------|---------|----------|-------------|--------------------------------|
| `tight`          | 20      | 100      | 47 ticks    | charge mostly at B (slow zone) |
| `fastzone-only`  | 20      | 21       | 20 ticks    | charge only at C (fast zone)   |

Both problems have the *same map, same battery, same charge rates*. The
only difference is initial `time-of-day`. Yet the second plan is 2.35×
faster.

The reason: ENHSP's satisficing search with the `hadd` heuristic counts
*remaining actions*, not *remaining time*. Without a
`(:metric minimize total-time)` directive, the first valid plan wins,
and that plan is often time-wasteful. A tighter deadline (constraint) is
what forced the planner into the optimal strategy.

> **General property:** PDDL+ planning guarantees *validity*, not
> *optimality*. Modellers must add explicit optimisation criteria, or
> constrain the problem until only good plans remain feasible.

### 1.4. Summary

Discrete models are pedagogically clean but cannot express *rate-based
phenomena* (continuous charging, draining, heating) or *autonomous world
dynamics* (events, processes). Continuous models are physically faithful
but require careful calibration — Q2's charge rates had to be ~50×
smaller than Q1's because they multiply with elapsed time rather than
acting as one-shot jumps. The choice is not "which is better" but
**which abstraction best matches the scale of decisions the planner
needs to make**.

---

## 2. Planning under energy uncertainty

Both Q1 and Q2 assume the world is fully observable and deterministic:
the rover always knows its battery level exactly, every move costs
exactly its declared `move-cost`, and the sun rises and sets at a known
threshold. Real planetary missions violate all three assumptions. PDDL
and PDDL+ cannot represent this uncertainty natively — a `(:functions)`
value is a single number, not a probability distribution. The course
identifies three relevant frameworks *(Part 2, MDP/POMDP slides;
Part 3, pp. 37–38, 83–85)*.

### 2.1. MDP — uncertainty in transitions

**The problem:** Our model says `move A → B` *always* costs exactly 10
battery. But in reality the wheels slip, the rover gets stuck — outcomes
vary.

**The MDP fix:** Replace "this action always does X" with "this action
does X with probability *p*, or Y with probability *1−p*". The planner
now computes *expected* outcomes and picks the action with the best
average reward.

**Key assumption:** The rover always *knows* exactly what state it's in.

> Core idea: *"I don't know exactly what my action will do, but I do
> know exactly where I am."*

### 2.2. POMDP — uncertainty in observation

**The problem:** Even what you "know" about yourself is wrong. The
rover's battery sensor reads 30 but the true value could be 27 or 33.

**The POMDP fix:** The rover doesn't track a single state; it tracks a
**belief** — a probability distribution over possible states. Every
sensor reading updates this belief. This is what real Mars rovers
actually use, because their sensors are always noisy.

> Core idea: *"Not only might my action do something unexpected — I
> don't even know exactly where I am."*

### 2.3. Robust / contingent planning

**The problem:** Full MDP / POMDP solvers are slow and complicated.
Often we just want a plan that "won't break."

**The robust fix:** Pretend the world is deterministic, but assume the
*worst-case* numbers (move costs 12 not 10; charge rate 0.4 not 0.5).
Solve normally. The plan has built-in safety margin.

**Contingent planning** goes further: pre-compute "if-then" branches —
*"if battery drops below 15 after move B→C, detour to the nearest solar
zone."*

> Core idea: *"Don't model the uncertainty — just be paranoid about it."*

### 2.4. Summary — when to use which

| Framework | When to use it |
|-----------|----------------|
| **PDDL+ (our model)** | Everything known and deterministic. |
| **Robust planning**   | Small disturbances; want a quick safe plan. |
| **MDP**               | Action outcomes uncertain, but state fully known. |
| **POMDP**             | Both action outcomes *and* current state uncertain (real robots). |

### 2.5. Why we did not use MDP, POMDP, or robust planning

1. **The assignment didn't ask for it.** D1-V7 explicitly requires PDDL
   and PDDL+. MDPs and POMDPs use entirely different languages
   (transition matrices, reward functions — no `:action` or `:process`).
2. **The tools don't support it.** ENHSP and other mainstream PDDL
   planners cannot read probabilities. Handling uncertainty would
   require different software (POMCP, SARSOP, RDDL planners) with
   different input formats.
3. **The deterministic model already shows the lesson.** The `tight` vs
   `fastzone-only` vs `infeasible` comparison already demonstrates how
   *timing affects feasibility* — the exact requirement of Q2. Adding
   probabilities would only make the feasibility window fuzzy; it would
   not change the lesson.

### 2.6. A pragmatic compromise: Sense–Plan–Act

For a real rover, a practical pipeline would be:

1. **Off-line.** Use PDDL+ (this assignment's model) to plan an
   *optimistic*, deterministic plan.
2. **On-line.** Monitor true battery and time during execution. If a
   precondition is about to fail, re-plan from the current *observed*
   state.
3. **Across re-plans.** Maintain a belief over uncertain parameters
   (e.g. the `charge-rate` actually achieved on this Martian sol) and
   update it as data arrives.

This is exactly the **Sense–Plan–Act** loop from *Part 0, pp. 5–6* —
with PDDL+ playing the *Plan* role inside a larger system that handles
the noisy *Sense* and uncertain *Act* parts. The deterministic model is
therefore not a finished product but a **module** of a complete robotic
architecture.

---

## 3. Durative movement (optional extension)

In Q1 and Q2, `move` is instantaneous: the rover crosses an edge in zero
time, and time only advances while it waits to charge. The optional
extension in `Optional_Durative_Movement/` makes **travel itself take
time** (a fixed 5 ticks per move).

### 3.1. Modelling duration without `:durative-action`

PDDL 2.1 offers `:durative-action` for timed actions, but ENHSP — a
numeric / PDDL+ planner — does not support that syntax. Travel time was
therefore modelled the **PDDL+ way**, with three coordinated constructs:

- `start-move` *(action)* — the rover commits: it leaves the origin,
  spends battery, sets a `travel-timer` to 5, and marks itself
  `traveling` toward a `dest`.
- `travel` *(process)* — counts `travel-timer` down continuously while in
  transit.
- `arrive` *(event)* — when the timer reaches 0, the rover lands at the
  destination, marks it `visited`, and clears the `traveling` flag.

Charging during travel is blocked automatically: while `(traveling ?r)`
is true, `(at ?r ?l)` is false for every location, so the `charging`
process cannot run. This neatly preserves the convention that the rover
charges only while stationary at a solar zone.

### 3.2. Effect on feasibility

Running the same four cases with durative movement shifts every boundary:

| Case        | Instantaneous (Q2) | Durative (bonus) | Why it shifts                    |
|-------------|--------------------|--------------------|----------------------------------|
| easy        | finishes t=0       | finishes t=15      | travel now costs 3 × 5 ticks     |
| tight       | 47 ticks           | 65 ticks           | +15 travel on top of slow charge |
| fastzone    | boundary t=79      | boundary t=64      | travel eats daylight earlier     |
| infeasible  | fails at t=85      | fails at t=75      | deadline bites sooner            |

### 3.3. What it teaches

Adding travel time shifts every feasibility boundary *earlier* — the
rover has less daylight to spare because moving itself consumes the day.
Crucially, the **underlying lesson is unchanged**: timing still drives
feasibility, and the same `tight` → `fastzone` → `infeasible` story
holds. The numbers simply tighten. This confirms that durative movement
adds *realism and pressure*, not a new concept — which is why it belongs
as an optional extension rather than part of the core model.

---

## 4. Other limitations

Two further simplifications remain in the present model:

- **Edges are always traversable.** The model ignores the task–motion
  gap (*PDDL_Class2 Ex. 8*): `(connected A B)` assumes the geometric
  path exists and is safe. Real terrain would require integrating a
  motion planner with the symbolic planner.
- **Single agent.** Multi-rover coordination (*PDDL_Class2 Ex. 7*) would
  introduce additional constraints — only one rover at a charging zone at
  a time, communication delays, joint goals.

---

## References (course materials)

- *Part 0 — Introduction:* Sense–Plan–Act, STRIPS basics.
- *Part 2 — Planning Fundamentals:* PDDL anatomy, satisficing vs.
  optimal planning, MDP/POMDP definitions.
- *Part 3 — Advanced Planning Concepts:* PDDL+ semantics (pp. 14–24,
  processes/events), bouncing ball (pp. 19–23), belief-space planning
  (pp. 37–38, 83–85), semantic attachments.
- *PDDL_Introduction_1 — Ex. 5:* Energy Navigation with
  `:numeric-fluents`.
- *PDDL_Class2 — Ex. 6, 8, 9, 10:* Durative actions, task–motion gap,
  PDDL+ basics, water-tank hybrid dynamics.
