;; ============================================================
;; Domain: rover-energy-plus
;; Assignment D1-V7 -- Q2 / PDDL+ with continuous charging
;;                     and day/night events
;; ============================================================

(define (domain rover-energy-plus)

  (:requirements :strips :typing :numeric-fluents :time)

  (:types
    rover location
  )

  (:predicates
    (at ?r - rover ?l - location)
    (connected ?l1 - location ?l2 - location)
    (solar-zone ?l - location)
    (visited ?l - location)
    (daytime)                 ; global: sun is up
  )

  (:functions
    (battery-level ?r - rover)
    (max-battery   ?r - rover)
    (move-cost     ?l1 - location ?l2 - location)
    (charge-rate   ?l - location)
    (time-of-day)             ; continuous clock
  )

  ;; ----------------------------------------------------------
  ;; ACTION: move  (unchanged from Q1)
  ;; ----------------------------------------------------------
  (:action move
    :parameters (?r - rover ?from - location ?to - location)
    :precondition (and
      (at ?r ?from)
      (connected ?from ?to)
      (>= (battery-level ?r) (move-cost ?from ?to))
    )
    :effect (and
      (not (at ?r ?from))
      (at ?r ?to)
      (visited ?to)
      (decrease (battery-level ?r) (move-cost ?from ?to))
    )
  )

  ;; ----------------------------------------------------------
  ;; PROCESS: time-flow  -- the clock ticks forward
  ;; ----------------------------------------------------------
  (:process time-flow
    :parameters ()
    :precondition (>= (time-of-day) 0)
    :effect (increase (time-of-day) (* #t 1))
  )

  ;; ----------------------------------------------------------
  ;; PROCESS: charging  -- replaces Q1's recharge action
  ;; Active only when: at a sun zone AND daytime AND battery not full
  ;; ----------------------------------------------------------
  (:process charging
    :parameters (?r - rover ?l - location)
    :precondition (and
      (at ?r ?l)                              ; rover must BE at location ?l
      (solar-zone ?l)                         ; ?l must be a sun zone
      (daytime)                               ; sun must be up
      (< (battery-level ?r) (max-battery ?r)) ; battery must not be full
    )
    :effect (increase (battery-level ?r) (* #t (charge-rate ?l)))
  )

  ;; ----------------------------------------------------------
  ;; EVENT: nightfall  -- the sun goes down at t = 100
  ;; ----------------------------------------------------------
  (:event nightfall
    :parameters ()
    :precondition (and
      (>= (time-of-day) 100)
      (daytime)
    )
    :effect (not (daytime))
  )

  ;; ----------------------------------------------------------
  ;; EVENT: sunrise  -- the sun comes up at t = 200
  ;; (optional, for completeness if mission spans > 1 day)
  ;; ----------------------------------------------------------
  (:event sunrise
    :parameters ()
    :precondition (and
      (>= (time-of-day) 200)
      (not (daytime))
    )
    :effect (daytime)
  )

)