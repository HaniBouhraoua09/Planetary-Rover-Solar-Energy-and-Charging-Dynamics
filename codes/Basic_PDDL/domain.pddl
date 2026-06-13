;; ============================================================
;; Domain: rover-energy
;; Assignment D1-V7 -- Planetary Rover, Solar Energy & Charging
;; Q1 / Classical PDDL with numeric fluents
;; ============================================================


(define (domain rover-energy)

  (:requirements :strips :typing :numeric-fluents)

  (:types
    rover location
  )

  (:predicates
    (at ?r - rover ?l - location)
    (connected ?l1 - location ?l2 - location)
    (solar-zone ?l - location)
    (visited ?l - location)
  )

  (:functions
    (battery-level ?r - rover)
    (max-battery   ?r - rover)
    (move-cost     ?l1 - location ?l2 - location)
    (charge-rate   ?l - location)
  )

  ;; ----------------------------------------------------------
  ;; ACTION: move
  ;; Consumes battery to traverse a graph edge.
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
  ;; ACTION: recharge
  ;; Adds energy at a solar-exposed location, capped at max.
  ;; ----------------------------------------------------------
  (:action recharge
    :parameters (?r - rover ?l - location)
    :precondition (and
      (at ?r ?l)
      (solar-zone ?l)
      (<= (+ (battery-level ?r) (charge-rate ?l)) (max-battery ?r))
    )
    :effect (and
      (increase (battery-level ?r) (charge-rate ?l))
    )
  )

)