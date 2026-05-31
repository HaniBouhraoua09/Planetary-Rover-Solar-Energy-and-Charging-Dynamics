Author : Hani Bouhraoua <br>
ID : 8314923 <br>

# Discussion — Planetary Rover (D1-V7)

> Companion to the main `README.md`. Reflects on the modelling choices
> made in Q1 (classical PDDL) and Q2 (PDDL+), grounded in the planner
> outputs produced by ENHSP.

---

## 1. Discrete vs. continuous energy modelling

Both Q1 and Q2 modelled the same scenario — a rover exploring a graph
while managing battery — but expressed it in two different formalisms.
The comparison reveals three concrete trade-offs.

### 1.1. Expressive power vs. simplicity

In **Q1**, `recharge` is a single discrete action with an instantaneous
effect. The state machine is small: roughly *(rover position) × (battery
level)*. Q1 plans read like a recipe:

```
move A → B          (battery 25 → 15)
move B → C          (battery 15 → 5)
recharge at C       (battery 5 → 30)    ← one atomic step
move C → D          (battery 30 → 20)
```

This is *easy to write, easy to verify, easy to plan*. The cost is
**fidelity**: a real solar panel does not deliver +25 units of charge in
zero time. The model abstracts away the physics.

**Q2** explicitly models physics. The `:process charging` produces battery
at a continuous rate, integrated over the time the rover spends in a
solar zone:

```lisp
:effect (increase (battery-level ?r) (* #t (charge-rate ?l)))
```

The same scenario produces a plan with **explicit waiting periods**:

```
0:    (move rover1 locA locB)
0:    -----waiting---- [45.0]      ← 45 ticks at B, charging continuously
45.0: (move rover1 locB locC)
...
```

The plan now answers a question Q1 cannot: *how long does the rover
sit?* This is essential for real robotic execution — a controller needs
to know how long to keep the rover stationary, not merely that it should
"recharge."

### 1.2. Agency: planner-driven vs. world-driven

In Q1, the planner is the *only* agent of change. Nothing happens unless
an action is chosen. In Q2, the world acts on its own:

| Construct      | Who controls it | When it fires                       |
|----------------|-----------------|-------------------------------------|
| `:action`      | Planner         | When the planner chooses            |
| `:process`     | World           | While precondition holds            |
| `:event`       | World           | The instant precondition becomes true |

This shift is essential for any domain where physics evolves regardless
of the agent's choices — falling objects, draining tanks, sunsets. The
course illustrates this with the bouncing-ball and V-22 Osprey examples
(*Part 3, pp. 19–23*). In our model, **nightfall** is the obvious
example: the rover doesn't *decide* night comes; the world imposes it.

### 1.3. Optimality under each formalism

A surprising result emerged from comparing two Q2 runs:

| Problem                | Battery | Daylight left | Plan time   | Strategy                          |
|------------------------|---------|----------------|-------------|-----------------------------------|
| `tight`                | 20      | 100           | **47 ticks** | charge mostly at B (slow zone)    |
| `fastzone-only`        | 20      | 21            | **20 ticks** | charge only at C (fast zone)      |

Both problems have the *same map, same battery, same charge rates*. The
only difference is the initial `time-of-day` value. Yet the second plan
is 2.35× faster.

The reason: ENHSP's satisficing search with the `hadd` heuristic *counts
remaining actions*, not *remaining time*. It cannot distinguish "wait 2
ticks at C" from "wait 45 ticks at B" — both look like "one wait + the
remaining moves." Without a `(:metric minimize total-time)` directive,
the first valid plan wins, and that plan is often time-wasteful.
**Tightening the deadline (`time-of-day = 79`) is what forced the
planner into the optimal strategy.**

This illustrates a general property of PDDL+ planning: *validity is
guaranteed; optimality is not* (*Part 2 — Satisficing vs Optimal
Planning*). Modellers must either add explicit optimisation criteria
or constrain the problem until only good plans remain feasible.

### 1.4. Summary

Discrete models are pedagogically clean and produce short plans, but
they cannot express **rate-based phenomena** (continuous charging,
draining, heating) or **autonomous world dynamics** (events, processes).
Continuous models are physically faithful but require careful
calibration — Q2's charge rates had to be ~50× smaller than Q1's because
they multiply with elapsed time, not act as one-shot jumps. The choice
is not "which is better" but **which abstraction best matches the scale
of decisions the planner needs to make**.

---

## 2. Planning under energy uncertainty

Both Q1 and Q2 assume the world is *fully observable* and
*deterministic*: the rover always knows its battery level exactly, every
move costs exactly its declared `move-cost`, and the sun rises and sets
at a known threshold. Real planetary missions violate **all three**
assumptions:

- Battery readings are *noisy* and degrade over time.
- A move's actual cost depends on terrain slope, tyre slip, and dust.
- Solar irradiance varies with weather; a dust storm reduces the
  effective `charge-rate` unpredictably.

PDDL and PDDL+ cannot represent this kind of uncertainty natively. A
`(:functions)` declaration like `(battery-level ?r)` carries no
probability distribution — it is a single number. The course identifies
three frameworks that *can* handle uncertainty (*Part 2 — MDP/POMDP
slides; Part 3, pp. 37–38, 83–85*).

### 2.1. MDP — uncertainty in transitions

A Markov Decision Process replaces deterministic effects with a
**transition probability** `P(s' | s, a)`. In our rover, this would let
us say *"`move A → B` succeeds with probability 0.9, and with probability
0.1 the rover gets stuck and the battery is wasted."* The planner would
then optimise expected reward (e.g. negative battery used minus a reward
for visiting). MDPs assume *full observability* — the rover knows
exactly which state it is in.

### 2.2. POMDP — uncertainty in observation

A Partially Observable MDP adds an observation function: the rover
cannot know its true state, only its **belief** over states. For energy
uncertainty: the true `battery-level` is hidden; only a noisy sensor
reading is observed. The planner reasons over a **belief state** — a
probability distribution over possible battery levels.

This is the appropriate framework for a real Mars rover. *Part 3,
pp. 83–85*, shows how a `loc-precision(robbie, X)` semantic attachment
encodes the belief that the rover's true location is normally
distributed around `X`. The same idea applies to battery: replace
`battery-level` with `(mean-battery)` and `(battery-variance)`, then
update both via a Kalman filter as the rover senses and acts.

### 2.3. Robust / contingent planning

A lighter-weight alternative is **robust planning**: plan
deterministically but assume worst-case parameters. In our model, set
`move-cost` to *upper-bound* values and `charge-rate` to *lower-bound*
values, then solve as before. The resulting plan is conservative but
tolerant of small disturbances. **Contingent planning** goes further:
pre-compute branches for different outcomes (e.g. *"if battery < 15
after this move, detour to the nearest solar zone"*).

### 2.4. Why we did not use any of these

Three reasons:

1. **Assignment scope.** D1-V7 asks for PDDL and PDDL+; uncertainty
   modelling would require a different formalism.
2. **Tool availability.** No mainstream PDDL planner natively supports
   probability. POMDP solvers (POMCP, SARSOP) use entirely different
   input formats.
3. **The deterministic model already exposes the core trade-off.** The
   `tight` vs `fastzone-only` comparison shows how a *known* deadline
   shapes the plan. Adding uncertainty would amplify this effect (a
   wider distribution over `time-of-day` would shrink the feasibility
   window) without changing its character.

### 2.5. A pragmatic compromise: Sense–Plan–Act

For a real rover, a practical pipeline would be:

1. **Off-line.** Use PDDL+ (this assignment's model) to plan an
   *optimistic*, deterministic plan.
2. **On-line.** Monitor true battery and time at execution. If a
   precondition is about to fail, re-plan from the current *observed*
   state.
3. **Across re-plans.** Maintain a belief over uncertain parameters
   (e.g. the `charge-rate` actually achieved on this Martian sol), and
   update it as data arrives.

This is exactly the **Sense–Plan–Act** loop described in *Part 0,
pp. 5–6* — with PDDL+ playing the *Plan* role inside a larger system
that handles the noisy *Sense* and uncertain *Act* parts. The
assignment's deterministic model is therefore not a finished product
but a **module** of a complete robotic architecture.

---

## 3. Other limitations worth mentioning

For completeness, three further simplifications of the present model:

- **Instantaneous moves.** `move` consumes battery but no time. In
  reality, travel between rocks takes minutes. Upgrading to a
  `:durative-action` (per *PDDL_Class2 Ex.6*) would make travel time
  compete with charging time for the daylight budget. This would
  amplify, not change, the conclusions above.
- **Edges are always traversable.** The model ignores the *task–motion
  gap* (*PDDL_Class2 Ex. 8*): `(connected A B)` assumes the geometric
  path exists and is safe. Real terrain would require integrating a
  motion planner (RRT, A* on a grid) with the symbolic planner.
- **Single agent.** Multi-rover coordination (*PDDL_Class2 Ex. 7*)
  would introduce additional constraints — only one rover at a
  charging zone at a time, communication delays, joint exploration
  goals.

---

## References (course materials)

- *Part 0 — Introduction:* Sense–Plan–Act, STRIPS basics.
- *Part 2 — Planning Fundamentals:* PDDL anatomy, satisficing vs.
  optimal planning, MDP/POMDP definitions.
- *Part 3 — Advanced Planning Concepts:* PDDL+ semantics
  (pp. 14–24, processes/events), bouncing ball (pp. 19–23),
  belief-space planning (pp. 37–38, 83–85), semantic attachments.
- *PDDL_Introduction_1 — Ex. 5:* Energy Navigation with
  `:numeric-fluents`.
- *PDDL_Class2 — Ex. 6, 8, 9, 10:* Durative actions, task–motion gap,
  PDDL+ basics, water-tank hybrid dynamics.