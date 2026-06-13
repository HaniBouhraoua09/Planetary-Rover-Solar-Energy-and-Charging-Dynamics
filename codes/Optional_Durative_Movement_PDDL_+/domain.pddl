;; ============================================================
;; Domain: rover-energy-durative
;; Assignment D1-V7 -- OPTIONAL EXTENSION
;; Travel takes TIME, modelled the PDDL+ way (process + event)
;; because ENHSP supports processes/events, not :durative-action.
;;
;; A "move" is now THREE coordinated pieces:
;;   (:action  start-move) -- commit: leave origin, spend battery,
;;                            set a 5-tick countdown, mark traveling
;;   (:process travel)     -- counts the timer down continuously
;;   (:event   arrive)     -- when timer hits 0: arrive + visited
;;
;; Charging (Option A): only while STATIONARY at a solar zone.
;; While traveling, the rover is "at" no location, so the
;; charging process is naturally inactive in transit.
;; ============================================================

(define (domain rover-energy-durative)

  (:requirements :strips :typing :numeric-fluents
                 :negative-preconditions :time)

  (:types
    rover location
  )

  (:predicates
    (at ?r - rover ?l - location)
    (connected ?l1 - location ?l2 - location)
    (solar-zone ?l - location)
    (visited ?l - location)
    (daytime)
    (traveling ?r - rover)              ; rover is in transit
    (dest ?r - rover ?l - location)     ; where it is heading
  )

  (:functions
    (battery-level ?r - rover)
    (max-battery   ?r - rover)
    (move-cost     ?l1 - location ?l2 - location)
    (charge-rate   ?l - location)
    (time-of-day)
    (travel-timer  ?r - rover)          ; counts down 5 -> 0
  )

  ;; ----------------------------------------------------------
  ;; ACTION: start-move  -- commit to a 5-tick journey
  ;; ----------------------------------------------------------
  (:action start-move
    :parameters (?r - rover ?from - location ?to - location)
    :precondition (and
      (at ?r ?from)
      (not (traveling ?r))
      (connected ?from ?to)
      (>= (battery-level ?r) (move-cost ?from ?to)))
    :effect (and
      (not (at ?r ?from))
      (decrease (battery-level ?r) (move-cost ?from ?to))
      (traveling ?r)
      (dest ?r ?to)
      (assign (travel-timer ?r) 5))
  )

  ;; ----------------------------------------------------------
  ;; PROCESS: travel  -- count the timer down while in transit
  ;; ----------------------------------------------------------
  (:process travel
    :parameters (?r - rover)
    :precondition (and
      (traveling ?r)
      (> (travel-timer ?r) 0))
    :effect (decrease (travel-timer ?r) (* #t 1))
  )

  ;; ----------------------------------------------------------
  ;; EVENT: arrive  -- timer hit 0: land at destination
  ;; ----------------------------------------------------------
  (:event arrive
    :parameters (?r - rover ?to - location)
    :precondition (and
      (traveling ?r)
      (dest ?r ?to)
      (<= (travel-timer ?r) 0))
    :effect (and
      (not (traveling ?r))
      (not (dest ?r ?to))
      (at ?r ?to)
      (visited ?to))
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
  ;; PROCESS: charging  -- only while STATIONARY at a sun zone
  ;; ----------------------------------------------------------
  (:process charging
    :parameters (?r - rover ?l - location)
    :precondition (and
      (at ?r ?l)
      (solar-zone ?l)
      (daytime)
      (< (battery-level ?r) (max-battery ?r)))
    :effect (increase (battery-level ?r) (* #t (charge-rate ?l)))
  )

  ;; ----------------------------------------------------------
  ;; EVENT: nightfall  -- the sun goes down at t = 100
  ;; ----------------------------------------------------------
  (:event nightfall
    :parameters ()
    :precondition (and (>= (time-of-day) 100) (daytime))
    :effect (not (daytime))
  )

  ;; ----------------------------------------------------------
  ;; EVENT: sunrise  -- the sun comes up at t = 200
  ;; ----------------------------------------------------------
  (:event sunrise
    :parameters ()
    :precondition (and (>= (time-of-day) 200) (not (daytime)))
    :effect (daytime)
  )

)
