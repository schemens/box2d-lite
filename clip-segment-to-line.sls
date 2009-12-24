
(library (box2d-lite clip-segment-to-line)

  (export clip-segment-to-line)

  (import (rnrs)
	  (dharmalab misc is-vector)
	  (box2d-lite util say)
	  (box2d-lite vec)
	  (box2d-lite edge-numbers)
	  (box2d-lite clip-vertex)
	  (box2d-lite feature-pair)

	  (xitomatl debug)
	  )

  (define (clip-segment-to-line v-out v-in normal offset clip-edge)

    (define num-out 0)

    (is-vector       v-out num-out)
    (is-clip-vertex  v-out.num-out)
    (is-feature-pair v-out.num-out.fp)
    (is-edges        v-out.num-out.fp.e)

    (define-syntax v-in.0 (identifier-syntax (vector-ref v-in 0)))
    (define-syntax v-in.1 (identifier-syntax (vector-ref v-in 1)))

    (is-clip-vertex v-in.0)
    (is-clip-vertex v-in.1)

    ;; (say "********** clip-segment-to-line ********** ")

    ;; (say "v-in[0].fp.e = " (feature-pair-e (clip-vertex-fp (vector-ref v-in 0))))
    ;; (say "v-in[1].fp.e = " (feature-pair-e (clip-vertex-fp (vector-ref v-in 1))))

    ;; (say-expr normal)
    ;; (say-expr offset)
    ;; (say-expr clip-edge)

    (let ((distance-0 (- (vec-dot normal v-in.0.v) offset))
	  (distance-1 (- (vec-dot normal v-in.1.v) offset)))

      ;; (say-expr distance-0)
      ;; (say-expr distance-1)

      ;; (say-expr (* distance-0 distance-1))
      
      (if (<= distance-0 0.0)
	  (begin (v-out.num-out! v-in.0) (set! num-out (+ num-out 1))))
      
      (if (<= distance-1 0.0)
	  (begin (v-out.num-out! v-in.1) (set! num-out (+ num-out 1))))

      (if (< (* distance-0 distance-1) 0.0)
	  
	  (let ((interp (/ distance-0 (- distance-0 distance-1))))

	    ;; (say "branch taken")

	    (v-out.num-out.v! (v+ v-in.0.v (n*v interp (v- v-in.1.v v-in.0.v))))

	    (cond ((> distance-0 0.0)
		   (v-out.num-out.fp!             v-in.0.fp)
		   (v-out.num-out.fp.e.in-edge-1! clip-edge)
		   (v-out.num-out.fp.e.in-edge-2! NO-EDGE))

		  (else
		   (v-out.num-out.fp!             v-in.1.fp)
		   (v-out.num-out.fp.e.out-edge-1! clip-edge)
		   (v-out.num-out.fp.e.out-edge-2! NO-EDGE)))

	    (set! num-out (+ num-out 1)))))

    ;; (say "v-out[0].fp.e = " (feature-pair-e (clip-vertex-fp (vector-ref v-out 0))))
    ;; (say "v-out[1].fp.e = " (feature-pair-e (clip-vertex-fp (vector-ref v-out 1))))

    num-out)

  )