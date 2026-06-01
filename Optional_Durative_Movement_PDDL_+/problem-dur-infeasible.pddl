;; ============================================================
;; Problem: durative infeasible
;; Battery low (20), start very late (time-of-day = 75).
;;
;; Daylight remaining = 100 - 75 = 25 ticks.
;; Minimum feasible plan = 15 ticks travel + 20 ticks charging
;;                       = 35 ticks  >  25 available.
;; Even the fastest strategy cannot finish before nightfall.
;; Expected: UNSOLVABLE -- nightfall stops charging too soon.
;; ============================================================

(define (problem rover-dur-infeasible)
  (:domain rover-energy-durative)

  (:objects
    rover1               - rover
    locA locB locC locD  - location
  )

  (:init
    (at rover1 locA)
    (visited locA)

    (connected locA locB)
    (connected locB locC)
    (connected locC locD)
    (connected locA locD)
    (connected locB locD)

    (solar-zone locB)
    (solar-zone locC)

    (daytime)
    (= (time-of-day) 75)        ; only 25 ticks of daylight left

    (= (battery-level rover1) 20)
    (= (max-battery   rover1) 100)
    (= (travel-timer  rover1) 0)

    (= (move-cost locA locB) 10)
    (= (move-cost locB locC) 10)
    (= (move-cost locC locD) 10)
    (= (move-cost locA locD) 15)
    (= (move-cost locB locD) 20)

    (= (charge-rate locB) 0.2)
    (= (charge-rate locC) 0.5)
  )

  (:goal (and
    (visited locA) (visited locB) (visited locC) (visited locD)
    (< (time-of-day) 100)
  ))
)
