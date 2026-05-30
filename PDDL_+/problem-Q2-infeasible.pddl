;; ============================================================
;; Problem: rover-Q2-infeasible
;; Same battery as tight, but starts late in the day.
;; Expected: NO PLAN FOUND -- nightfall hits before
;;          enough charging is possible.
;; ============================================================

(define (problem rover-Q2-infeasible)
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

    ;; --- world state: LATE AFTERNOON ---
    (daytime)
    (= (time-of-day) 85)        ; only 15 ticks of daylight left

    ;; --- battery: TIGHT (same as previous problem) ---
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