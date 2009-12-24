
(library (box2d-lite world)

  (export make-world

	  is-world
	  import-world

	  world::step

	  ;; for testing

	  world::broad-phase

	  world-bodies
	  world-joints
	  world-arbiters
	  world-gravity
	  world-iterations
	  )

  (import (except (rnrs) remove)
	  (only (srfi :1 lists) remove)
	  (box2d-lite util define-record-type)
	  (box2d-lite util say)
	  (box2d-lite vec)
	  (box2d-lite body)
	  (box2d-lite joint)
	  (box2d-lite arbiter)

	  ;; for testing
	  (box2d-lite contact)
	  (box2d-lite feature-pair)
	  
	  )

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (say-vec v) (say (vec-x v) "	" (vec-y v)))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define-record-type++ world
    is-world
    import-world
    (fields (mutable bodies)
	    (mutable joints)
	    (mutable arbiters)
	    (mutable gravity)
	    (mutable iterations))
    (methods (add-body world::add-body)
	     (clear world::clear)
	     (step world::step)))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; (define (world::add-body w body)
  ;;   (is-world w)
  ;;   (w.bodies! (cons body w.bodies)))

  (define (world::add-body w body)
    (is-world w)
    (w.bodies! (append w.bodies (list body))))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (world::clear w)
    (is-world w)
    (w.bodies!   '())
    (w.joints!   '())
    (w.arbiters! '()))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (world::broad-phase w)

    (import-world w)

    (do ((bodies bodies (cdr bodies)))
	((null? bodies))

      (let ((bi (car bodies)))

	(is-body bi)

	(do ((bodies (cdr bodies) (cdr bodies)))
	    ((null? bodies))

	  (let ((bj (car bodies)))

	    (is-body bj)

	    (if (and (= bi.inv-mass 0.0) (= bj.inv-mass 0.0))
		
		#t

		(let ((new-arb (create-arbiter bi bj)))

		  (is-arbiter new-arb)

		  (if (> new-arb.num-contacts 0)

		      (let ((arbiter (find
				      
				      (lambda (arbiter)
					(is-arbiter arbiter)
					(or (and (eq? bi arbiter.body-1)
						 (eq? bj arbiter.body-2))
					    (and (eq? bi arbiter.body-2)
						 (eq? bj arbiter.body-1)))
					)
				      
				      arbiters)))

			(is-arbiter arbiter)

			(if arbiter
			    (arbiter.update new-arb.contacts
					    new-arb.num-contacts)

			    (arbiters! (append arbiters (list new-arb)))

			    ))

		      (begin

			(arbiters!
			 (remove
			  (lambda (arbiter)
			    (is-arbiter arbiter)
			     (or (and (eq? bi arbiter.body-1)
				      (eq? bj arbiter.body-2))
				 (and (eq? bi arbiter.body-2)
				      (eq? bj arbiter.body-1)))
			    )
			  arbiters))

			)

		      ))))))))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (world::step w dt)

    (import-world w)

    ;; (say "world::step  "
    ;; 	 "bodies: " (length (world-bodies   w)) "  "
    ;; 	 "joints: " (length (world-joints   w)) "  "
    ;; 	 "arbiters: " (length (world-arbiters w)))

    ;; (if (>= (length (world-bodies w)) 2)
    ;; 	(say (body-velocity (list-ref (world-bodies w) 1))
    ;; 	     "	"
    ;; 	     (body-angular-velocity (list-ref (world-bodies w) 1))))

    ;; (if (>= (length (world-bodies w)) 2)
    ;; 	(say

    ;; 	 ;; (vec-x (body-velocity (list-ref (world-bodies w) 2)))
    ;; 	 ;; "	"
    ;; 	 ;; (vec-y (body-velocity (list-ref (world-bodies w) 2)))

    ;; 	 ;; (body-torque (list-ref (world-bodies w) 1))

    ;; 	 ))

    (let ((inv-dt (if (> dt 0.0) (/ 1.0 dt) 0.0)))

      (world::broad-phase w)

      (for-each
       (lambda (b)
	 (is-body b)
	 (if (= b.inv-mass 0.0)
	     #t
	     (begin
	       
	       (b.velocity!
		(v+ b.velocity (n*v dt (v+ gravity (n*v b.inv-mass b.force)))))
	       (b.angular-velocity!
		(+ b.angular-velocity (* dt b.inv-i b.torque)))

	       
	       
	       )))
       bodies)

      (for-each (lambda (arbiter) (arbiter::pre-step arbiter inv-dt)) arbiters)
      (for-each (lambda (joint)   (joint::pre-step   joint   inv-dt)) joints)

      (do ((i 0 (+ i 1)))
	  ((>= i iterations))
	(for-each arbiter::apply-impulse arbiters)
	(for-each joint::apply-impulse   joints))

      (for-each
       (lambda (b)
	 (is-body b)
	 (b.position! (v+ b.position (n*v dt b.velocity)))
	 (b.rotation! (+  b.rotation (*   dt b.angular-velocity)))
	 (vec::set b.force 0.0 0.0)
	 (b.torque! 0.0))
       bodies)))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  )
	    