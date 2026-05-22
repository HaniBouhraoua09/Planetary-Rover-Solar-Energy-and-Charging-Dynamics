;; ============================================================
;; Problem B: rover-necessary
;; Battery is tight -- the rover MUST recharge to finish.
;; Expected plan: 3 moves + 1 recharge.
;; ============================================================

(define (problem rover-necessary)
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

    ;; --- numeric: battery (LOWER than Problem A) ---
    (= (battery-level rover1) 25)
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