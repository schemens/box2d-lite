
(library (box2d-lite collide)

  (export collide)

  (import (rnrs)
	  (dharmalab misc is-vector)
	  (box2d-lite util say)
	  (box2d-lite vec)
	  (box2d-lite mat)
	  (box2d-lite body)
	  (box2d-lite edge-numbers)
	  (box2d-lite contact)
	  (box2d-lite clip-vertex)
	  (box2d-lite feature-pair)
	  (box2d-lite compute-incident-edge)
	  (box2d-lite clip-segment-to-line)

	  )

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define FACE-A-X 'FACE-A-X)
  (define FACE-A-Y 'FACE-A-Y)
  (define FACE-B-X 'FACE-B-X)
  (define FACE-B-Y 'FACE-B-Y)

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (collide contacts body-a body-b)

    (is-body body-a)
    (is-body body-b)

    ;; (display "collide ")

    (let ((ha (n*v 0.5 body-a.width))
	  (hb (n*v 0.5 body-b.width))

	  (pos-a body-a.position)
	  (pos-b body-b.position)

	  (rot-a (angle->mat body-a.rotation))
	  (rot-b (angle->mat body-b.rotation)))

      (is-vec ha)
      (is-vec hb)

      (is-mat rot-a)
      (is-mat rot-b)

      (let ((rot-at (rot-a.transpose))
	    (rot-bt (rot-b.transpose))

	    (dp (v- pos-b pos-a)))

	(let* ((da (m*v rot-at dp))
	       (db (m*v rot-bt dp))

	       (abs-c (mat::abs (m* rot-at rot-b)))

	       (abs-ct (mat::transpose abs-c)))

	  (is-vec da)
	  (is-vec db)

	  (let ((face-a (v-v (vec::abs da) ha (m*v abs-c hb)))

		(face-b (v-v (vec::abs db) (m*v abs-ct ha) hb)))

	    (is-vec face-a)
	    (is-vec face-b)

	    ;; (say "face-a 	      	" face-a)

	    (if (or (> face-a.x 0.0)
		    (> face-a.y 0.0)
		    (> face-b.x 0.0)
		    (> face-b.y 0.0))

		0

		(let ((axis       #f)
		      (separation #f)
		      (normal     #f)

		      (relative-tol 0.95)
		      (absolute-tol 0.01))

		  ;; (say "pos-a		" pos-a)
		  ;; (say "pos-b		" pos-b)
		  ;; (say "dp		" dp)
		  ;; (say "dp		" dp)
		  ;; (say "rot-at		" rot-at)
		  ;; (say "da		" da)

		  (set! axis FACE-A-X)

		  (set! separation face-a.x)

		  (set! normal
			(v*n rot-a.col-1
			     (if (> da.x 0.0) 1 -1)))

		  ;; (say "normal		" normal)

		  (if (> face-a.y (+ (* relative-tol separation)
				     (* absolute-tol ha.y)))
		      (begin
			;; (say "********** BRANCH A **********")
			;; (say "da.y		" da.y)
			(set! axis       FACE-A-Y)
			(set! separation face-a.y)
			(set! normal     (v*n rot-a.col-2
					      (if (> da.y 0.0) 1 -1)))))

		  (if (> face-b.x (+ (* relative-tol separation)
				     (* absolute-tol hb.x)))
		      (begin
			;; (say "********** BRANCH B **********")
			(set! axis       FACE-B-X)
			(set! separation face-b.x)
			(set! normal     (v*n rot-b.col-1
					      (if (> db.x 0.0) 1 -1)))))

		  (if (> face-b.y (+ (* relative-tol separation)
				     (* absolute-tol hb.y)))
		      (begin
			;; (say "********** BRANCH C **********")
			(set! axis       FACE-B-Y)
			(set! separation face-b.y)
			(set!            normal (v*n rot-b.col-2
						     (if (> db.y 0.0) 1 -1)))))

		  (let (
			(front-normal #f)
			(side-normal  #f)

			;; (incident-edge (make-vector 2))

			(incident-edge
			 (vector
			  (make-clip-vertex (make-vec 0 0)
					    (make-feature-pair (create-edges) 0))
			  (make-clip-vertex (make-vec 0 0)
					    (make-feature-pair (create-edges) 0))))

			;; (incident-edge (vector (create-clip-vertex)
			;; 		       (create-clip-vertex)))
			
			(front #f)
			(neg-side #f)
			(pos-side #f)
			(neg-edge #f)
			(pos-edge #f)
			(side #f)
			)

		    ;; (say-expr incident-edge)

		    (case axis

		      ((FACE-A-X)

		       ;; (display "case FACE-A-X  ")
		       
		       (set! front-normal normal)
		       (set! front        (+ (vec-dot pos-a front-normal) ha.x))
		       (set! side-normal  rot-a.col-2)
		       (set! side         (vec-dot pos-a side-normal))
		       (set! neg-side     (+ (- side) ha.y))
		       (set! pos-side     (+ side ha.y))
		       (set! neg-edge     EDGE3)
		       (set! pos-edge     EDGE1)

		       (compute-incident-edge
			incident-edge hb pos-b rot-b front-normal)
		       
		       )

		      ((FACE-A-Y)

		       ;; (display  "case FACE-A-Y  ")
		       
		       (set! front-normal normal)
		       (set! front        (+ (vec-dot pos-a front-normal) ha.y))
		       (set! side-normal  rot-a.col-1)
		       (set! side         (vec-dot pos-a side-normal))
		       (set! neg-side     (+ (- side) ha.x))
		       (set! pos-side     (+ side ha.x))
		       (set! neg-edge     EDGE2)
		       (set! pos-edge     EDGE4)

		       (compute-incident-edge
			incident-edge hb pos-b rot-b front-normal))

		      ((FACE-B-X)

		       ;; (display "case FACE-B-X  ")

		       (set! front-normal (vec::neg normal))
		       (set! front        (+ (vec-dot pos-b front-normal) hb.x))
		       (set! side-normal  rot-b.col-2)
		       (set! side         (vec-dot pos-b side-normal))
		       (set! neg-side     (+ (- side) hb.y))
		       (set! pos-side     (+    side  hb.y))
		       (set! neg-edge     EDGE3)
		       (set! pos-edge     EDGE1)
		       (compute-incident-edge
			incident-edge ha pos-a rot-a front-normal))

		      ((FACE-B-Y)

		       ;; (display "case FACE-B-Y  ")

		       (set! front-normal (vec::neg normal))
		       (set! front        (+ (vec-dot pos-b front-normal) hb.y))
		       (set! side-normal  rot-b.col-1)
		       (set! side         (vec-dot pos-b side-normal))
		       (set! neg-side     (+ (- side) hb.x))
		       (set! pos-side     (+    side  hb.x))
		       (set! neg-edge     EDGE2)
		       (set! pos-edge     EDGE4)
		       (compute-incident-edge
			incident-edge ha pos-a rot-a front-normal))
		      )

		    ;; (say-expr incident-edge)

		    (let ((clip-points-1 (vector (create-clip-vertex)
						 (create-clip-vertex)))

			  (clip-points-2 (vector (create-clip-vertex)
						 (create-clip-vertex)))

			  )

		      ;; (say-expr clip-points-2)

		      ;; (say "incident-edge.0.v"
		      ;; 	   (clip-vertex-v (vector-ref incident-edge 0))
		      ;; 	   )
		      ;; (say "incident-edge.1.v"
		      ;; 	   (clip-vertex-v (vector-ref incident-edge 1))
		      ;; 	   )

		      (if (< (clip-segment-to-line clip-points-1
						   incident-edge
						   (vec::neg side-normal)
						   neg-side
						   neg-edge)
			     2)

			  0

			  (if (< (clip-segment-to-line clip-points-2
						       clip-points-1
						       side-normal
						       pos-side
						       pos-edge)
				 2)

			      0

			      (do ((num-contacts 0)
				   (i 0 (+ i 1)))
				  ((>= i 2)
				   ;; (say "num-contacts		" num-contacts)
				   num-contacts)

				;; (say-expr clip-points-2)

				(let ()

				  (is-vector      contacts num-contacts)
				  (is-contact     contacts.num-contacts)
				  
				  (is-vector      clip-points-2 i)
				  (is-clip-vertex clip-points-2.i)

				  (let ((separation
					 (- (vec-dot front-normal clip-points-2.i.v)
					    front)))

				    ;; (say "clip-points-1.0.v		"
				    ;; 	 (clip-vertex-v (vector-ref clip-points-1 0)))

				    ;; (say "clip-points-1.1.v		"
				    ;; 	 (clip-vertex-v (vector-ref clip-points-1 1)))

				    ;; (say "clip-points-2.0.v		"
				    ;; 	 (clip-vertex-v (vector-ref clip-points-2 0)))

				    ;; (say "clip-points-2.1.v		"
				    ;; 	 (clip-vertex-v (vector-ref clip-points-2 1)))

				    
				    ;; (say "i		" i)
				    ;; (say "front-normal		" front-normal)
				    ;; (say "clip-points-2.i.v     " clip-points-2.i.v)
				    ;; (say "separation		" separation)

				    (if (<= separation 0)

					(begin

					  (contacts.num-contacts.separation! separation)
					  (contacts.num-contacts.normal!     normal)
					  (contacts.num-contacts.position!
					   (v- clip-points-2.i.v
					       (n*v separation front-normal)))

					  ;; (say-expr clip-points-2.i.fp)

					  (contacts.num-contacts.feature!
					   clip-points-2.i.fp)

					  (if (or (eq? axis FACE-B-X)
						  (eq? axis FACE-B-Y))
					      (flip contacts.num-contacts.feature))

					  (set! num-contacts
						(+ num-contacts 1))))))))))))))))))

    )
