;; ============================================================
;; Problem: durative easy
;; Battery generous (60), morning start.
;; Expected: 3 moves, no charging. Each move takes 5 ticks,
;;           so the plan now finishes around t = 15 (not t = 0).
;; ============================================================

(define (problem rover-dur-easy)
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
    (= (time-of-day) 0)

    (= (battery-level rover1) 60)
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
