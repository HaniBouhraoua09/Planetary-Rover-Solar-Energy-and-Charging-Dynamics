;; ============================================================
;; Problem: durative tight
;; Battery low (20), morning start, plenty of daylight.
;; Deficit = 10 battery. Travel = 15 ticks. Charging adds more.
;; Expected: a feasible plan with travel time AND a charging gap,
;;           finishing well before nightfall (t < 100).
;; ============================================================

(define (problem rover-dur-tight)
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
