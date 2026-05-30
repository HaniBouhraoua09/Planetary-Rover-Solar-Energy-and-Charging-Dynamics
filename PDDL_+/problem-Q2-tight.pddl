;; ============================================================
;; Problem: rover-Q2-tight
;; Battery is low BUT plenty of daylight remains.
;; Expected: 3 moves + a waiting gap at locC for charging.
;; ============================================================

(define (problem rover-Q2-tight)
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

    ;; --- world state: morning ---
    (daytime)
    (= (time-of-day) 0)

    ;; --- battery: TIGHT (only 20, need 30 for full tour) ---
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