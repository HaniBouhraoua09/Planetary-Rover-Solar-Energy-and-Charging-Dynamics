;; ============================================================
;; Problem A: rover-optional
;; Battery is generous -- recharge is NOT needed.
;; Expected plan: pure move actions, no recharge.
;; ============================================================

(define (problem rover-optional)
  (:domain rover-energy)

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

    ;; --- numeric: battery ---
    (= (battery-level rover1) 60)
    (= (max-battery   rover1) 100)

    ;; --- numeric: edge costs ---
    (= (move-cost locA locB) 10)
    (= (move-cost locB locC) 10)
    (= (move-cost locC locD) 10)
    (= (move-cost locA locD) 15)
    (= (move-cost locB locD) 20)

    ;; --- numeric: per-location charge rates ---
    (= (charge-rate locB) 15)
    (= (charge-rate locC) 25)
  )

  (:goal (and
    (visited locA)
    (visited locB)
    (visited locC)
    (visited locD)
  ))
)