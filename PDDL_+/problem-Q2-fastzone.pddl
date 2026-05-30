;; ============================================================
;; Problem: rover-Q2-fastzone-only
;; Battery tight (20), only 20 ticks of daylight remaining.
;;
;; Charging at the SLOW zone (B, rate 0.2) would need 50 ticks
;; to recover the missing 10 battery -- but only 20 ticks of
;; daylight remain. So the slow-charge strategy is INFEASIBLE.
;;
;; Charging at the FAST zone (C, rate 0.5) needs exactly 20 ticks
;; to recover 10 battery -- just barely fitting before nightfall.
;;
;; Expected plan:
;;   0:    (move rover1 locA locB)
;;   0:    (move rover1 locB locC)
;;   0->20: wait 20 ticks at C, charging at rate 0.5
;;   20:   (move rover1 locC locD)
;; The plan completes EXACTLY at t=100 (nightfall) -- the boundary.
;; ============================================================

(define (problem rover-Q2-fastzone-only)
  (:domain rover-energy-plus)

  (:objects
    rover1               - rover
    locA locB locC locD  - location
  )

  (:init
    ;; --- rover start ---
    (at rover1 locA)
    (visited locA)

    ;; --- directional graph edges ---
    (connected locA locB)
    (connected locB locC)
    (connected locC locD)
    (connected locA locD)
    (connected locB locD)

    ;; --- solar zones ---
    (solar-zone locB)
    (solar-zone locC)

    ;; --- world state: LATE DAY, 20 ticks of daylight left ---
    (daytime)
    (= (time-of-day) 79)

    ;; --- battery: tight, needs +10 ---
    (= (battery-level rover1) 20)
    (= (max-battery   rover1) 100)

    ;; --- edge costs ---
    (= (move-cost locA locB) 10)
    (= (move-cost locB locC) 10)
    (= (move-cost locC locD) 10)
    (= (move-cost locA locD) 15)
    (= (move-cost locB locD) 20)

    ;; --- charge rates ---
    (= (charge-rate locB) 0.2)
    (= (charge-rate locC) 0.5)
  )

  (:goal (and
    (visited locA)
    (visited locB)
    (visited locC)
    (visited locD)
    (< (time-of-day) 100)
  ))
)
